import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data_size.dart';
import 'download_http_helper.dart';
import 'download_notifications_service.dart';
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

  static List<Map<String, dynamic>> _activeTasks = [];

  static StreamController<List<DownloadTask>> _activeTaskStreamController;

  static DownloadTaskRepository _downloadDb = DownloadTaskRepository();

  static DownloadPreferencesRepository _downloadPreferences;

  static DownloadPreferencesRepository get preferences => _downloadPreferences;

  static Stream<List<DownloadTask>> get activeTaskStream =>
      _activeTaskStreamController.stream;

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

    if (resume) await resumeEnqueue();
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
    List<DownloadTask> downloadsActive = await DownloadTaskRepository().find(
      statusOr: [
        DownloadTaskStatus.running,
        DownloadTaskStatus.enqueued,
        DownloadTaskStatus.paused,
      ],
    );

    downloadsActive.forEach((element) async {
      await resume(element.idCustom);
    });
  }

  static Future<void> addTask({
    String id,
    @required String url,
    @required String saveDir,
    String fileName,
    Map<String, dynamic> headers,
    bool autoStart = true,
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
      if (autoStart) await resume(id);
    } on DatabaseException catch (err) {
      print(err);
      if (autoStart) await resume(id);
    }
  }

  static Future<void> pause(String idTask) async {
    // ignore: close_sinks
    HttpClientRequest request = _getActiveTaskRequest(idTask);
    if (request != null) {
      request.abort();
      DownloadTask task = _getActiveTaskModel(idTask);
      if (task != null) {
        _updateActiveTask(
          idTask,
          model: task.copyWith(
            status: DownloadTaskStatus.paused,
          ),
        );
      }
      await DownloadTaskRepository().update(
        status: DownloadTaskStatus.complete,
        completedAt: DateTime.now(),
        whereEquals: {
          'id_custom': idTask,
        },
        whereDistinct: {
          'status': DownloadTaskStatus.canceled.value,
        },
      );
    }
  }

  static Future<void> cancel(
    String idTask, {
    bool clearHistory = false,
  }) async {
    HttpClientRequest request = _getActiveTaskRequest(idTask);
    if (request != null) {
      request.close();
      if (clearHistory) {
        await DownloadTaskRepository().deleteByCustomId(idTask);
      } else {
        await DownloadTaskRepository().update(
          status: DownloadTaskStatus.complete,
          completedAt: DateTime.now(),
          whereEquals: {
            'id_custom': idTask,
          },
          whereDistinct: {
            'status': DownloadTaskStatus.canceled,
          },
        );
      }
    }
    _removeActiveTask(idTask);
  }

  static Future<void> cancelAll({bool clearHistory = false}) async {
    _activeTasks.forEach((element) async {
      String id = (element['model'] as DownloadTask).idCustom;
      HttpClientRequest request = element['request'];
      request.close();

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
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    try {
      DownloadTask downloadTask =
          await DownloadTaskRepository().findByIdCustom(idTask);
      int lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;

      List<Map> runningTask = _activeTasks
          .where((e) =>
              (e['model'] as DownloadTask).status == DownloadTaskStatus.running)
          .toList();

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
        return false;
      }
      _addActiveTask(
        model: downloadTask.copyWith(
          status: DownloadTaskStatus.running,
        ),
      );

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
      await DownloadHttpHelper.download(
        url: downloadTask.url,
        savePath: downloadTask.saveDir + '/' + downloadTask.fileName,
        headers: downloadTask.headers,
        resume: downloadTask.resumable,
        limitBandwidth: downloadTask.limitBandwidth,
        onReceived: (receivedLength, total) async {
          if ((DateTime.now().millisecondsSinceEpoch -
                  lastCallUpdateNotification) >
              Duration(milliseconds: 1000).inMilliseconds) {
            lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;
            if (downloadTask.showNotification)
              await DownloadNotificationsService.showProgressDownload(
                notificationId: downloadTask.id,
                title: downloadTask.displayName,
                sizeDownload: receivedLength,
                size: total,
                speedDownload: lastSpeedDownload,
                channelAction: AndroidNotificationChannelAction.update,
                setAsGroupSummary: false,
              );
          }
        },
        onSpeedDownloadChange: (size) {
          lastSpeedDownload = size;
          print(size.format());
        },
        onComplete: () async {
          await DownloadTaskRepository().update(
            status: DownloadTaskStatus.complete,
            completedAt: DateTime.now(),
            whereEquals: {'id_custom': idTask},
          );
          _removeActiveTask(idTask);
          await resumeEnqueue();

          if (downloadTask.showNotification) {
            await DownloadNotificationsService.cancel(downloadTask.id);
            await DownloadNotificationsService.showFinishedDownload(
              idNotification: downloadTask.id,
              displayName: downloadTask.displayName,
            );
          }
        },
      );
      return true;
    } catch (err) {
      print(err);
    }
    return false;
  }

  static Future<void> retry(int idTask) async {}

  static Future<List<DownloadTask>> getTask({
    List<DownloadTaskStatus> status,
    int offset = 0,
    int limit,
    DownloadTaskType type,
  }) async {
    List<DownloadTask> tasks = await DownloadTaskRepository().find(
      offset: offset,
      limit: limit,
      statusAnd: status,
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

  static void _addActiveTask({
    @required DownloadTask model,
    HttpClientRequest request,
  }) {
    List<Map<String, dynamic>> tasks = _activeTasks.where((element) {
      DownloadTask task = element['model'];
      return task.id == model.id;
    }).toList();

    if (tasks.length == 0) {
      _activeTasks.add({
        'model': model,
        'request': request,
      });
    } else {
      Map task = tasks.firstWhere(
          (e) => (e['model'] as DownloadTask).idCustom == model.idCustom,
          orElse: () {});
      if (task != null) {
        task['model'] = model;
      }
    }
  }

  static Map<String, dynamic> _getActiveTask(String idTask) {
    Map task = _activeTasks.firstWhere(
      (element) => (element['model'] as DownloadTask).idCustom == idTask,
      orElse: () => null,
    );
    return task;
  }

  static void _updateActiveTask(
    String idTask, {
    DownloadTask model,
    HttpClientRequest request,
  }) {
    Map task = _getActiveTask(idTask);
    if (model != null) task['model'] = model;
    if (request != null) task['request'] = request;
  }

  static void _removeActiveTask(String idTask) {
    _activeTasks.removeWhere(
        (element) => (element['model'] as DownloadTask).idCustom == idTask);
    _notifyActiveTaskStream();
  }

  static DownloadTask _getActiveTaskModel(String idTask) {
    Map task = _getActiveTask(idTask);
    if (task == null) return null;
    return task['model'] as DownloadTask;
  }

  static HttpClientRequest _getActiveTaskRequest(String idTask) {
    Map task = _getActiveTask(idTask);
    if (task == null) return null;
    return task['request'] as HttpClientRequest;
  }

  static List<DownloadTask> get activeTask {
    return _activeTasks.map((e) {
      return e['model'] as DownloadTask;
    }).toList();
    List<Map<String, dynamic>> tasks = _activeTasks.where((element) {
      DownloadTask task = element['model'];
      return task.status == DownloadTaskStatus.running;
    }).toList();
    // return tasks.length;
    // List<DownloadTask> tasks = await _runningStreamController.stream.last;
    // return tasks.length;
  }

  static void _notifyActiveTaskStream() {
    _activeTaskStreamController.add(
      _activeTasks.map((e) => e['model'] as DownloadTask).toList(),
    );
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
    await Future.delayed(Duration(seconds: 1));
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
