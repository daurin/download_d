import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'download_http_helper.dart';
import 'download_notifications_service.dart';
import 'models/active_download.dart';
import 'models/data_size.dart';
import 'download_preferences_repository.dart';
import 'download_task_repository.dart';
import 'models/download_task.dart';
import 'models/download_task_status.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/download_task_type.dart';

abstract class DownloadService {
  static bool _initialized = false;
  static StreamController<List<DownloadTask>> _enqueuedStreamController;
  static StreamController<List<DownloadTask>> _runningStreamController;

  static List<ActiveDownload> _activeTasks = [];

  static StreamController<List<DownloadTask>> _activeTaskStreamController;

  static DownloadTaskRepository _downloadDb = DownloadTaskRepository();

  static DownloadPreferencesRepository _downloadPreferences;

  static DownloadPreferencesRepository get preferences => _downloadPreferences;

  static Stream<List<DownloadTask>> get activeTaskStream =>
      _activeTaskStreamController?.stream;

  static String file5mb = 'http://212.183.159.230/5MB.zip';
  static String file10mb = 'http://212.183.159.230/10MB.zip';
  static String file20mb = 'http://212.183.159.230/20MB.zip';
  static String file50mb = 'http://212.183.159.230/50MB.zip';
  static String file100mb = 'http://212.183.159.230/100MB.zip';

  static Future<void> start({bool resume = true}) async {
    if (_initialized) return;
    _initialized = true;
    _downloadPreferences = DownloadPreferencesRepository();
    _runningStreamController = StreamController<List<DownloadTask>>.broadcast();
    _enqueuedStreamController =
        StreamController<List<DownloadTask>>.broadcast();
    _activeTaskStreamController =
        StreamController<List<DownloadTask>>.broadcast();
    await DownloadNotificationsService.initialize();

    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    List<DownloadTask> downloadsActive = await DownloadTaskRepository().find(
      statusOr: [
        DownloadTaskStatus.running,
        DownloadTaskStatus.enqueued,
        DownloadTaskStatus.paused,
        DownloadTaskStatus.failed,
      ],
    );

    downloadsActive.forEach((element) {
      if (element.status == DownloadTaskStatus.running) {
        element = element.copyWith(
          status: DownloadTaskStatus.enqueued,
        );
      }
      _addActiveTask(
        model: element,
      );
    });
    _notifyActiveTaskStream();

    // if (resume) await resumeEnqueue();
  }

  static Future<void> stop() async {
    if (!_initialized) return;
    await _runningStreamController.close();
    await _enqueuedStreamController.close();
    await _activeTaskStreamController.close();
    await DownloadNotificationsService.cancelAll();
    _initialized = false;
  }

  static Future<bool> enableForegroundService() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Ejecutando servicio',
      notificationText: 'Oshinstar se ejecuta en segundo plano',
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    success = await FlutterBackground.enableBackgroundExecution();
    DownloadNotificationsService.showNotificationsEnabled();
    //await testWork();
    return success;
  }

  static Future<void> disableForegroundService() async {
    await FlutterBackground.disableBackgroundExecution();
  }

  static Future<void> resumeEnqueue() async {
    // List<DownloadTask> downloadsActive = await DownloadTaskRepository().find(
    //   statusOr: [
    //     DownloadTaskStatus.running,
    //     DownloadTaskStatus.enqueued,
    //     DownloadTaskStatus.paused,
    //     DownloadTaskStatus.failed,
    //   ],
    // );
    List<ActiveDownload> activeTask = _activeTasks.where((element) {
      if ([
        DownloadTaskStatus.enqueued,
        DownloadTaskStatus.paused,
        DownloadTaskStatus.failed,
      ].contains(element.task.status)) {
        return true;
      }
      return false;
    }).toList();

    activeTask.sort((a, b) => b.task.createdAt.compareTo(a.task.createdAt));

    for (var item in activeTask) {
      await resume(item.task.idCustom);
    }
  }

  static Future<void> addTask({
    String id,
    @required String url,
    @required String saveDir,
    String fileName,
    Map<String, dynamic> headers,
    bool autoStart = false,
    int index,
    DataSize limitBandwidth,
    String displayName,
    Duration duration,
    String thumbnailUrl,
  }) async {
    HttpClientResponse responseHead = await DownloadHttpHelper.head(
      url: url,
      headers: headers,
    );
    int contentLenght = responseHead.headers.contentLength ?? 0;
    if (fileName == null) {
      if (responseHead.redirects.length > 0)
        fileName = basename(responseHead.redirects.last.location.toString());
      else
        fileName = basename(url);
    }
    if (displayName == null) {
      displayName = fileName;
    }

    DownloadTaskStatus status = DownloadTaskStatus.enqueued;

    try {
      if (id == null) id = DateTime.now().millisecondsSinceEpoch.toString();
      await _downloadDb.add(
        idCustom: id,
        url: url,
        status: status,
        saveDir: saveDir,
        fileName: fileName,
        displayName: displayName,
        size: contentLenght != null ? DataSize(bytes: contentLenght) : null,
        mimeType: lookupMimeType(fileName),
        headers: headers,
        showNotification: true,
        index: index,
        limitBandwidth: limitBandwidth,
        resumable: responseHead.headers['Accept-Ranges'] != null,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
      );
    } on DatabaseException catch (err) {
      print(err);
    } catch (err) {
      print(err);
    }
    DownloadTask task = await DownloadTaskRepository().findByIdCustom(id);
    _addActiveTask(
      model: task.copyWith(
        status: DownloadTaskStatus.enqueued,
      ),
    );
  }

  static Future<void> pause(String idTask) async {
    DownloadTask task = await DownloadTaskRepository().findByIdCustom(idTask);
    ActiveDownload activeDownload = _getActiveTask(idTask);
    if (activeDownload?.changingStatus ?? false) return;
    _addActiveTask(
      model: task.copyWith(
        status: DownloadTaskStatus.paused,
        sizeDownloaded: DataSize(bytes: await File(task.path).length()),
      ),
      changingStatus: true,
    );
    await activeDownload.cancelableOperation.cancel();
    await DownloadTaskRepository()
        .update(status: DownloadTaskStatus.paused, whereEquals: {
      'id_custom': idTask,
    });
    _addActiveTask(
      model: task.copyWith(
        status: DownloadTaskStatus.paused,
        sizeDownloaded: DataSize(bytes: await File(task.path).length()),
      ),
      changingStatus: false,
    );
    activeDownload.statusStreamController.add(DownloadTaskStatus.paused);
    // ignore: close_sinks
    // HttpClientRequest request = _getActiveTaskRequest(idTask);
    // if (request != null) {
    //   request.abort();
    //   DownloadTask task = _getActiveTaskModel(idTask);
    //   if (task != null) {
    //     _addActiveTask(
    //       model: task.copyWith(
    //         status: DownloadTaskStatus.paused,
    //       ),
    //     );
    //   }
    //   await DownloadTaskRepository().update(
    //     status: DownloadTaskStatus.complete,
    //     completedAt: DateTime.now(),
    //     whereEquals: {
    //       'id_custom': idTask,
    //     },
    //     whereDistinct: {
    //       'status': DownloadTaskStatus.canceled.value,
    //     },
    //   );
    // }
  }

  static Future<void> cancel(
    String idTask, {
    bool clearHistory = false,
  }) async {
    DownloadTask task = await DownloadTaskRepository().findByIdCustom(idTask);
    _addActiveTask(
      model: task,
    );
    await DownloadTaskRepository().update(
      status: DownloadTaskStatus.canceled,
      whereEquals: {},
      whereDistinct: {
        'status': DownloadTaskStatus.canceled,
      },
    );
    await _removeActiveTask(idTask);
    _notifyActiveTaskStream();
    // HttpClientRequest request = _getActiveTaskRequest(idTask);
    // if (request != null) {
    //   request.close();
    //   if (clearHistory) {
    //     await DownloadTaskRepository().deleteByCustomId(idTask);
    //   } else {
    //     await DownloadTaskRepository().update(
    //       status: DownloadTaskStatus.complete,
    //       completedAt: DateTime.now(),
    //       whereEquals: {
    //         'id_custom': idTask,
    //       },
    //       whereDistinct: {
    //         'status': DownloadTaskStatus.canceled,
    //       },
    //     );
    //   }
    // }
    // _removeActiveTask(idTask);
  }

  static Future<void> cancelAll({bool clearHistory = false}) async {
    _activeTasks.forEach((element) async {
      String id = element.task.idCustom;

      if (clearHistory) {
        await DownloadTaskRepository().deleteByCustomId(id);
      } else {
        await DownloadTaskRepository().update(
            status: DownloadTaskStatus.complete,
            completedAt: DateTime.now(),
            whereEquals: {
              'id_custom': id,
            },
            whereDistinct: {
              'status': DownloadTaskStatus.canceled,
            });
      }
    });
    _activeTasks.clear();
  }

  static Future<bool> resume(String idTask) async {
    ActiveDownload activeDownload = _getActiveTask(idTask);
    if (activeDownload != null) {
      _addActiveTask(
        model: activeDownload.task,
        changingStatus: true,
      );
    }
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    if (activeDownload?.changingStatus ?? false) {
      return false;
    }

    try {
      DownloadTask downloadTask =
          await DownloadTaskRepository().findByIdCustom(idTask);
      int lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;

      _addActiveTask(
        model: activeDownload.task,
        changingStatus: true,
      );

      List<ActiveDownload> runningTask = _activeTasks.where((e) {
        return (e.task.status == DownloadTaskStatus.running);
      }).toList();

      if (runningTask.length >= _downloadPreferences.simultaneousDownloads) {
        if (downloadTask.status != DownloadTaskStatus.enqueued) {
          await DownloadTaskRepository()
              .update(status: DownloadTaskStatus.enqueued, whereEquals: {
            'id_custom': idTask,
          });
        }
        _addActiveTask(
          model: downloadTask.copyWith(
            status: DownloadTaskStatus.enqueued,
          ),
        );
        _notifyActiveTaskStream();
        return false;
      }
      // if(idTask=='2')_getActiveTask(idTask).receivedStreamController.stream.listen((event) {
      //   print(event);
      // });
      _notifyActiveTaskStream();

      if (await File(downloadTask.path).exists()) {
        if (await File(downloadTask.path).length() >=
            downloadTask.size.inBytes) {
          await File(downloadTask.path).delete();
        }
      }

      if (downloadTask.status != DownloadTaskStatus.running) {
        await DownloadTaskRepository()
            .update(status: DownloadTaskStatus.running, whereEquals: {
          'id_custom': idTask,
        });
        _addActiveTask(
          model: activeDownload.task.copyWith(
            status: DownloadTaskStatus.running,
          ),
        );
        _getActiveTask(idTask)
            .statusStreamController
            .add(DownloadTaskStatus.running);
      }

      await DownloadNotificationsService.showProgressDownload(
        notificationId: downloadTask.id,
        title: downloadTask.displayName,
        sizeDownload: DataSize.zero,
        size: downloadTask.size,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
        setAsGroupSummary: false,
      );

      DataSize lastSpeedDownload = DataSize.zero;

      // ignore: close_sinks
      CancelableOperation<void> cancelableOperation =
          await DownloadHttpHelper.download(
              url: downloadTask.url,
              savePath: downloadTask.saveDir + '/' + downloadTask.fileName,
              headers: downloadTask.headers,
              resume: downloadTask.resumable,
              limitBandwidth: downloadTask.limitBandwidth,
              onReceibedDelayCall: Duration(milliseconds: 200),
              onReceived: (received, total) async {
                if (!(activeDownload?.receivedStreamController?.isClosed ??
                    false)) {
                  activeDownload?.receivedStreamController?.add(received);
                } else {
                  print(activeDownload);
                }

                if ((DateTime.now().millisecondsSinceEpoch -
                        lastCallUpdateNotification) >
                    Duration(milliseconds: 1000).inMilliseconds) {
                  lastCallUpdateNotification =
                      DateTime.now().millisecondsSinceEpoch;
                  if (downloadTask.showNotification)
                    await DownloadNotificationsService.showProgressDownload(
                      notificationId: downloadTask.id,
                      title: downloadTask.displayName,
                      sizeDownload: received,
                      size: total,
                      speedDownload: lastSpeedDownload,
                      channelAction: AndroidNotificationChannelAction.update,
                      setAsGroupSummary: false,
                    );
                }
              },
              onSpeedDownloadChange: (size) {
                print(size.format());
                lastSpeedDownload = size;
                if (!(activeDownload?.speedDownloadStreamController?.isClosed ??
                    false))
                  activeDownload?.speedDownloadStreamController?.add(size);
                else {
                  print(activeDownload);
                }
              },
              onComplete: () async {
                _getActiveTask(idTask)
                    ?.statusStreamController
                    ?.add(DownloadTaskStatus.complete);
                await DownloadTaskRepository().update(
                  status: DownloadTaskStatus.complete,
                  completedAt: DateTime.now(),
                  whereEquals: {'id_custom': idTask},
                );
                await _removeActiveTask(idTask);
                _notifyActiveTaskStream();
                await resumeEnqueue();

                if (downloadTask.showNotification) {
                  await DownloadNotificationsService.cancel(downloadTask.id);
                  await DownloadNotificationsService.showFinishedDownload(
                    idNotification: downloadTask.id,
                    displayName: downloadTask.displayName,
                  );
                }
              },
              onError: (err) async {
                print(err);
                _getActiveTask(idTask)
                    ?.statusStreamController
                    ?.add(DownloadTaskStatus.failed);
                await DownloadTaskRepository().update(
                  status: DownloadTaskStatus.complete,
                  completedAt: DateTime.now(),
                  whereEquals: {'id_custom': idTask},
                );
                await resumeEnqueue();
              });

      _addActiveTask(
        model: activeDownload.task,
        cancelableOperation: cancelableOperation,
        changingStatus: false,
      );
      return true;
    } catch (err) {
      await DownloadTaskRepository().update(
        status: DownloadTaskStatus.failed,
        whereEquals: {'id_custom': idTask},
      );
      _getActiveTask(idTask)
          .statusStreamController
          .add(DownloadTaskStatus.failed);
      print(err);
    }
    return false;
  }

  static Future<void> retry(int idTask) async {}

  static Future<List<DownloadTask>> findTasks({
    List<DownloadTaskStatus> statusAnd,
    int offset = 0,
    int limit,
    DownloadTaskType type,
  }) async {
    List<DownloadTask> tasks = await DownloadTaskRepository().find(
      offset: offset,
      limit: limit,
      statusAnd: statusAnd,
      type: type,
    );
    await Future.wait(tasks.map((e) async {
      try {
        tasks[tasks.indexOf(e)] = e.copyWith(
          sizeDownloaded: DataSize(bytes: await File(e.path).length()),
        );
      } catch (err) {
        print(err);
      }
    }));

    return tasks;
  }

  static Future<DownloadTask> findTask(String idTask) {
    return DownloadTaskRepository().findByIdCustom(idTask);
  }

  static Future<void> deleteTask(String idTask) async {
    await DownloadTaskRepository().deleteByCustomId(idTask);
  }

  static void _addActiveTask({
    @required DownloadTask model,
    CancelableOperation<void> cancelableOperation,
    bool changingStatus,
  }) {
    List<ActiveDownload> tasks = _activeTasks.where((element) {
      DownloadTask task = element.task;
      return task.id == model.id;
    }).toList();

    if (tasks.length == 0) {
      _activeTasks.add(ActiveDownload(
        task: model,
        receivedStreamController: StreamController<DataSize>.broadcast(),
        speedDownloadStreamController: StreamController<DataSize>.broadcast(),
        statusStreamController:
            StreamController<DownloadTaskStatus>.broadcast(),
        cancelableOperation: cancelableOperation,
        changingStatus: changingStatus,
      ));
    } else {
      ActiveDownload activeTask = tasks.firstWhere(
        (e) => e.task.idCustom == model.idCustom,
        orElse: () => null,
      );
      if (activeTask != null) {
        _activeTasks[_activeTasks.indexOf(activeTask)] =
            activeTask = activeTask.copyWith(
          task: model,
          cancelableOperation: cancelableOperation,
          changingStatus: changingStatus,
        );
      }
    }
  }

  static Future<void> _removeActiveTask(String idTask) async {
    ActiveDownload activeTask = _activeTasks.firstWhere(
      (e) => e.task.idCustom == idTask,
      orElse: () => null,
    );
    await activeTask?.receivedStreamController?.close();
    await activeTask?.speedDownloadStreamController?.close();
    await activeTask?.statusStreamController?.close();
    _activeTasks.remove(activeTask);
  }

  static ActiveDownload _getActiveTask(String idTask) {
    ActiveDownload task = _activeTasks.firstWhere(
      (element) => element.task.idCustom == idTask,
      orElse: () => null,
    );
    return task;
  }

  // static DownloadTask _getActiveTaskModel(String idTask) {
  //   ActiveDownload activeDownload = _getActiveTask(idTask);
  //   if (activeDownload == null) return null;
  //   return activeDownload.task;
  // }

  static List<DownloadTask> get activeTasks {
    return _activeTasks.map((e) {
      return e.task;
    }).toList();
  }

  static DownloadTask activeTask(String idTask) {
    return _getActiveTask(idTask)?.task ?? null;
  }

  static Stream<DataSize> receibedStream(String idTask) {
    return _getActiveTask(idTask)?.receivedStreamController?.stream ?? null;
  }

  static Stream<DataSize> speedDownloadStream(String idTask) {
    return _getActiveTask(idTask)?.speedDownloadStreamController?.stream ??
        null;
  }

  static Stream<DownloadTaskStatus> statusStream(String idTask) {
    return _getActiveTask(idTask)?.statusStreamController?.stream ?? null;
  }

  static void _notifyActiveTaskStream() {
    List<DownloadTask> tasks = _activeTasks.map((e) => e.task).toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _activeTaskStreamController.add(tasks);
  }
}

Future<void> testWork() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
        android: AndroidInitializationSettings('drawable/notify_icon')),
  );

  int secondsMax = 1800;
  int notificationId = 1;
  await flutterLocalNotificationsPlugin.cancelAll();
  await flutterLocalNotificationsPlugin.show(
    notificationId,
    'Test WorkManager',
    'Seconds(0/$secondsMax)',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'flutter_background',
        'Descargas',
        'Descargas de documentos y archivos multimedia de oshinstar',
        showProgress: true,
        maxProgress: secondsMax,
        progress: 0,
        // groupKey: 'downloadsssss',
        // setAsGroupSummary: true,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: false,
        ongoing: true,
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
      ),
    ),
  );
  for (int i = 0; i <= secondsMax; i++) {
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Test WorkManager',
      'Seconds($i/$secondsMax)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'flutter_background',
          'Descargas',
          'Descargas de documentos y archivos multimedia de oshinstar',
          showProgress: true,
          maxProgress: secondsMax,
          progress: i,
          // groupKey: 'downloadsssss',
          // setAsGroupSummary: true,
          channelAction: AndroidNotificationChannelAction.update,
          autoCancel: false,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: true,
          playSound: false,
          enableVibration: false,
          channelShowBadge: false,
        ),
      ),
    );
  }
  await flutterLocalNotificationsPlugin.cancel(notificationId);
}
