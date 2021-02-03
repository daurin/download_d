import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db_download_creator.dart';
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

class DownloadService {
  bool _initialized = false;

  List<ActiveDownload> _activeTasks = [];

  StreamController<List<DownloadTask>> _activeTaskStreamController;
  StreamController<List<DownloadTask>> _statusStreamController;
  StreamController<DownloadTask> _onCompleteTaskStream;
  StreamController<DownloadTask> _statusChangeTaskStream;

  DownloadTaskRepository _downloadDb;

  DownloadPreferencesRepository _downloadPreferences;

  DownloadPreferencesRepository get preferences => _downloadPreferences;

  Stream<List<DownloadTask>> get activeTaskCountStream =>
      _activeTaskStreamController?.stream;

  Stream<List<DownloadTask>> get statusStream =>
      _statusStreamController?.stream;
  Stream<DownloadTask> get onCompleteTaskStream =>
      _onCompleteTaskStream?.stream;
  Stream<DownloadTask> get statusChangeTaskStream =>
      _statusChangeTaskStream?.stream;

  // static Stream<List<DownloadTask>> get runningTaskStream =>
  //     _statusStreamController?.stream?.where((event) {
  //       List<DownloadTask> tasks = event.where((element) {
  //         return element.status == DownloadTaskStatus.running;
  //       }).toList();
  //       print(event);
  //       if (event.length != _runningTaskStreamLastValue.length) {
  //         _runningTaskStreamLastValue = tasks.toList();
  //         return true;
  //       }
  //       bool isEqual =
  //           ListEquality().equals(tasks, _runningTaskStreamLastValue);
  //       if (!isEqual) {
  //         _runningTaskStreamLastValue = tasks.toList();
  //         return true;
  //       }
  //       return false;
  //     });

  static String file5mb = 'http://212.183.159.230/5MB.zip';
  static String file10mb = 'http://212.183.159.230/10MB.zip';
  static String file20mb = 'http://212.183.159.230/20MB.zip';
  static String file50mb = 'http://212.183.159.230/50MB.zip';
  static String file100mb = 'http://212.183.159.230/100MB.zip';

  static List<DownloadTask> _runningTaskStreamLastValue = [];
  bool _loadingGlobal = false;
  int _notificationIdHeader = 1;

  Future<void> start({
    String id = 'downloads',
    bool resume = true,
  }) async {
    try {
      if (_initialized) return;
      _initialized = true;

      // Database init
      Database db = await DBDownloadCreator().init(id);
      _downloadDb = DownloadTaskRepository(db);

      _downloadPreferences = DownloadPreferencesRepository();
      _activeTaskStreamController =
          StreamController<List<DownloadTask>>.broadcast();
      _statusStreamController =
          StreamController<List<DownloadTask>>.broadcast();
      _onCompleteTaskStream = StreamController<DownloadTask>.broadcast();
      _statusChangeTaskStream = StreamController<DownloadTask>.broadcast();
      await DownloadNotificationsService.initialize();

      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }

      List<DownloadTask> downloadsActive = await _downloadDb.find(
        statusOr: [
          DownloadTaskStatus.running,
          DownloadTaskStatus.enqueued,
          DownloadTaskStatus.paused,
          DownloadTaskStatus.failed,
          DownloadTaskStatus.failedConexion,
        ],
      );

      for (var element in downloadsActive) {
        DataSize sizeDownloaded;
        try {
          sizeDownloaded = DataSize(bytes: await File(element.path).length());
        } catch (err) {
          print(err);
        }
        element = element.copyWith(
          sizeDownloaded: sizeDownloaded,
        );
        if (element.status == DownloadTaskStatus.running) {
          element = element.copyWith(
            status: DownloadTaskStatus.enqueued,
          );
        }
        _addActiveTask(
          model: element,
        );
      }
      _notifyActiveTaskStream();

      if (resume)
        await resumeEnqueue();
      else {}
    } catch (err) {
      print(err);
    }
  }

  Future<void> stop() async {
    if (!_initialized) return;
    await _activeTaskStreamController.close();
    await _statusStreamController.close();
    await _onCompleteTaskStream.close();
    await _statusChangeTaskStream.close();
    await DownloadNotificationsService.cancelAll();
    _initialized = false;
  }

  static Future<bool> enableForegroundService() async {
    if (FlutterBackground.isBackgroundExecutionEnabled) return true;
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Ejecutando servicio',
      notificationText: 'Oshinstar se ejecuta en segundo plano',
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    success = await FlutterBackground.enableBackgroundExecution();
    DownloadNotificationsService.showNotificationsEnabled();
    return success;
  }

  static Future<void> disableForegroundService() async {
    if (!FlutterBackground.isBackgroundExecutionEnabled) return;
    await FlutterBackground.disableBackgroundExecution();
  }

  static bool get isBackgroundExecutionEnabled =>
      FlutterBackground.isBackgroundExecutionEnabled;

  Future<void> addTask({
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
    Map<String, dynamic> metadata,
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

    DownloadTaskStatus status = DownloadTaskStatus.paused;

    try {
      if (id == null) id = DateTime.now().millisecondsSinceEpoch.toString();
      await _downloadDb.add(
        idCustom: id,
        url: url,
        status: status,
        saveDir: saveDir,
        fileName: fileName,
        displayName: displayName,
        size: contentLenght != null ? DataSize(bytes: contentLenght) : -1,
        mimeType: lookupMimeType(fileName),
        headers: headers,
        showNotification: true,
        index: index,
        limitBandwidth: limitBandwidth,
        resumable: responseHead.headers['Accept-Ranges'] != null,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
        metadata: metadata,
      );
      DownloadTask task = await _downloadDb.findByIdCustom(id);
      _addActiveTask(
        model: task.copyWith(
          status: status,
        ),
      );
      _getActiveTask(id)?.emitStatus(status);
      _notifyActiveTaskStream();
      if (autoStart) await resume(id);
    } on DatabaseException catch (err) {
      DownloadTask task = await _downloadDb.findByIdCustom(id);
      _addActiveTask(
        model: task.copyWith(
          status: status,
        ),
      );
      _getActiveTask(id)?.emitStatus(status);
      _notifyActiveTaskStream();
      if (autoStart) await resume(id);
      print(err);
    } catch (err) {
      print(err);
    }
  }

  Future<void> resumeAll() async {
    try {
      if (_loadingGlobal) return;
      _loadingGlobal = true;
      List<ActiveDownload> tasks = _activeTasks.where((element) {
        if ([
          DownloadTaskStatus.enqueued,
          DownloadTaskStatus.paused,
          DownloadTaskStatus.failed,
          DownloadTaskStatus.failedConexion,
          DownloadTaskStatus.undefined,
        ].contains(element.task.status)) {
          return true;
        }
        return false;
      }).toList();

      tasks.sort((a, b) => b.task.createdAt.compareTo(a.task.createdAt));

      for (var item in tasks) {
        await resume(item.task.idCustom);
      }
    } catch (err) {}
    _loadingGlobal = false;
  }

  Future<void> resumeEnqueue() async {
    if (_loadingGlobal) return;
    _loadingGlobal = true;
    List<ActiveDownload> tasks = _activeTasks.where((element) {
      if ([
        DownloadTaskStatus.enqueued,
      ].contains(element.task.status)) {
        return true;
      }
      return false;
    }).toList();

    tasks.sort((a, b) => b.task.createdAt.compareTo(a.task.createdAt));

    for (var item in tasks) {
      await resume(item.task.idCustom);
    }
    _loadingGlobal = false;
  }

  Future<void> pauseAll({bool resumeEnqueueTask = true}) async {
    try {
      if (_loadingGlobal) return;
      _loadingGlobal = true;
      List<ActiveDownload> tasks = _activeTasks.where((element) {
        if ([
          DownloadTaskStatus.running,
          DownloadTaskStatus.enqueued,
          DownloadTaskStatus.failedConexion,
        ].contains(element.task.status)) {
          return true;
        }
        return false;
      }).toList();
      for (var item in tasks) {
        await pause(
          item.task.idCustom,
          resumeEnqueueTask: false,
        );
      }
      if (resumeEnqueueTask) resumeEnqueue();
    } catch (err) {}
    _loadingGlobal = false;
  }

  Future<void> pause(String idTask, {bool resumeEnqueueTask = true}) async {
    DownloadTask task = await _downloadDb.findByIdCustom(idTask);
    ActiveDownload activeDownload = _getActiveTask(idTask);
    if (activeDownload?.changingStatus ?? false) return;
    try {
      activeDownload?.cancelableOperation?.cancel();
      _addActiveTask(
        model: activeDownload.task.copyWith(
          status: DownloadTaskStatus.paused,
          // sizeDownloaded: DataSize(
          //   bytes: await File(task.path).length().catchError((err) => 0),
          // ),
        ),
        changingStatus: true,
      );
      activeDownload.emitStatus(DownloadTaskStatus.paused);
      await activeDownload?.cancelableOperation?.cancel();
      await _downloadDb.update(
        status: DownloadTaskStatus.paused,
        whereEquals: {
          'id_custom': idTask,
        },
      );
      _addActiveTask(
        model: activeDownload.task.copyWith(
          status: DownloadTaskStatus.paused,
        ),
        changingStatus: false,
      );
      if (_runningTaskStreamLastValue.length == 0) {
        await disableForegroundService();
        await DownloadNotificationsService.cancel(_notificationIdHeader);
      }
      await DownloadNotificationsService.cancel(task.id);
      if (resumeEnqueueTask) await resumeEnqueue();
    } catch (err) {
      _addActiveTask(
        model: activeDownload.task.copyWith(),
        changingStatus: false,
      );
      print(err);
    }
  }

  Future<bool> cancel(
    String idTask, {
    bool deleteFile = true,
    bool clearHistory = true,
  }) async {
    try {
      DownloadTask task = await _downloadDb.findByIdCustom(idTask);
      _addActiveTask(
        model: task.copyWith(
          status: DownloadTaskStatus.canceled,
        ),
      );
      ActiveDownload activeDownload = _getActiveTask(idTask);
      await activeDownload?.cancelableOperation?.cancel();
      if (deleteFile) {
        await File(task.path).delete().catchError((err) {});
      }
      if (clearHistory) {
        await _downloadDb.deleteByCustomId(idTask);
        activeDownload?.emitStatus(DownloadTaskStatus.canceled);

        activeDownload?.receivedStreamController?.add(DataSize.zero);
        activeDownload?.speedDownloadStreamController?.add(DataSize.zero);
      } else {
        await _downloadDb.update(
          status: DownloadTaskStatus.canceled,
          whereEquals: {
            'id_custom': idTask,
          },
        );
        activeDownload?.emitStatus(DownloadTaskStatus.canceled);
        activeDownload?.receivedStreamController?.add(DataSize.zero);
        activeDownload?.speedDownloadStreamController?.add(DataSize.zero);
      }
      await _removeActiveTask(idTask);
      _notifyActiveTaskStream();
      if (_runningTaskStreamLastValue.length == 0) {
        await disableForegroundService();
        await DownloadNotificationsService.cancel(
          _notificationIdHeader,
        );
      }
      await DownloadNotificationsService.cancel(task.id);

      await resumeEnqueue();

      return true;
    } catch (err) {
      print(err);
      return false;
    }
  }

  Future<void> cancelAll({
    bool deleteFile = true,
    bool clearHistory = false,
  }) async {
    List<ActiveDownload> tasks = _activeTasks.where((element) {
      return true;
      // if ([
      //   DownloadTaskStatus.running,
      //   DownloadTaskStatus.paused,
      //   DownloadTaskStatus.canceled,
      //   DownloadTaskStatus.failed,
      //   DownloadTaskStatus.enqueued,
      // ].contains(element.task.status)) {
      //   return true;
      // }
      // return false;
    }).toList();
    for (var item in tasks) {
      await cancel(
        item.task.idCustom,
        clearHistory: clearHistory,
        deleteFile: deleteFile,
      );
    }
  }

  Future<bool> resume(String idTask) async {
    ActiveDownload activeDownload = _getActiveTask(idTask);

    if ((activeDownload?.changingStatus ?? false) ||
        activeDownload?.task?.status == DownloadTaskStatus.running) {
      return false;
    }
    _addActiveTask(
      model: activeDownload.task,
      changingStatus: true,
    );

    try {
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
      List<ActiveDownload> runningTask = _activeTasks.where((e) {
        return (e.task.status == DownloadTaskStatus.running);
      }).toList();

      if (runningTask.length >= _downloadPreferences.simultaneousDownloads) {
        if (activeDownload.task.status != DownloadTaskStatus.enqueued) {
          await _downloadDb.update(
            status: DownloadTaskStatus.enqueued,
            whereEquals: {
              'id_custom': idTask,
            },
          );
        }
        _addActiveTask(
          model: activeDownload.task.copyWith(
            status: DownloadTaskStatus.enqueued,
          ),
          changingStatus: false,
        );
        _getActiveTask(idTask).emitStatus(DownloadTaskStatus.enqueued);

        return false;
      }
      DownloadTask downloadTask = await _downloadDb.findByIdCustom(idTask);
      int lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;

      if (await File(downloadTask.path).exists()) {
        if (await File(downloadTask.path).length() >=
            downloadTask.size.inBytes) {
          await File(downloadTask.path).delete();
        }
      }
      await _downloadDb.update(
        status: DownloadTaskStatus.running,
        whereEquals: {
          'id_custom': idTask,
        },
      );
      downloadTask = downloadTask.copyWith(status: DownloadTaskStatus.running);
      _addActiveTask(
        model: downloadTask,
      );
      _getActiveTask(idTask).emitStatus(DownloadTaskStatus.running);
      _notifyActiveTaskStream();

      // if(downloadTask.showNotification)await DownloadNotificationsService.showHeaderDownloadGroup(notificationId: _notificationIdHeader);
      if (_downloadPreferences.enabledNotifications)
        await DownloadNotificationsService.showProgressDownload(
          notificationId: downloadTask.id,
          notificationIdHeaderHroup: _notificationIdHeader,
          title: downloadTask.displayName,
          sizeDownload: downloadTask.sizeDownloaded ?? DataSize.zero,
          size: downloadTask.size,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          setAsGroupSummary: false,
          showProgress: _downloadPreferences.showProgressBarNotifications,
        );

      DataSize lastSpeedDownload = DataSize.zero;

      CancelableOperation<void> cancelableOperation =
          await DownloadHttpHelper.download(
        url: downloadTask.url,
        savePath: downloadTask.saveDir + '/' + downloadTask.fileName,
        headers: downloadTask.headers,
        resume: downloadTask.isResumable,
        limitBandwidth: downloadTask.limitBandwidth,
        onReceibedDelayCall: Duration(milliseconds: 200),
        onReceived: (received, total) async {
          downloadTask = downloadTask.copyWith(
            sizeDownloaded: received,
          );
          _addActiveTask(
            model: downloadTask,
          );
          activeDownload?.receivedStreamController?.add(received);

          if ((DateTime.now().millisecondsSinceEpoch -
                  lastCallUpdateNotification) >
              Duration(milliseconds: 1000).inMilliseconds) {
            lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;
            if (_downloadPreferences.enabledNotifications)
              await DownloadNotificationsService.showProgressDownload(
                notificationId: downloadTask.id,
                title: downloadTask.displayName,
                sizeDownload: received,
                size: downloadTask.size,
                speedDownload: lastSpeedDownload,
                channelAction: AndroidNotificationChannelAction.update,
                showProgress: _downloadPreferences.showProgressBarNotifications,
              );
          }
        },
        onSpeedDownloadChange: (size) {
          print(size.format());
          lastSpeedDownload = size;
          if (!(activeDownload?.speedDownloadStreamController?.isClosed ??
              false)) activeDownload?.speedDownloadStreamController?.add(size);
          downloadTask = downloadTask.copyWith(
            speedDownload: size,
          );
          _addActiveTask(
            model: downloadTask,
          );
        },
        onComplete: () async {
          downloadTask =
              downloadTask.copyWith(status: DownloadTaskStatus.complete);
          _addActiveTask(
            model: downloadTask,
          );
          _getActiveTask(idTask)?.emitStatus(DownloadTaskStatus.complete);
          await _downloadDb.update(
            status: DownloadTaskStatus.complete,
            completedAt: DateTime.now(),
            whereEquals: {'id_custom': idTask},
          );
          await _removeActiveTask(idTask);
          _notifyActiveTaskStream();
          await resumeEnqueue();

          if (_downloadPreferences.enabledNotifications &&
              _downloadPreferences.notifyOnFinished) {
            await DownloadNotificationsService.showFinishedDownload(
              idNotification: downloadTask.id,
              displayName: downloadTask.displayName,
            );
          }
          await DownloadNotificationsService.cancel(
            _notificationIdHeader,
          );
          await DownloadNotificationsService.cancel(
            downloadTask.id,
          );
          if (_runningTaskStreamLastValue.length == 0) {
            await disableForegroundService();
          }
        },
        onError: (err) async {
          bool conexionError = false;
          // Err conexion
          if (err is HttpException) {
            if (err.message == 'Connection closed while receiving data')
              conexionError = true;
          }
          if (err is SocketException) {
            if (err.message == 'Connection failed') conexionError = true;
          }
          DownloadTaskStatus newStatus = conexionError
              ? DownloadTaskStatus.failedConexion
              : DownloadTaskStatus.failed;
          downloadTask = downloadTask.copyWith(status: newStatus);
          _addActiveTask(
            model: downloadTask,
          );
          _getActiveTask(idTask)?.emitStatus(newStatus);
          await _downloadDb.update(
            status: newStatus,
            completedAt: DateTime.now(),
            whereEquals: {'id_custom': idTask},
          );
          if (_runningTaskStreamLastValue.length == 0) {
            await disableForegroundService();
            if (_downloadPreferences.enabledNotifications)
              await DownloadNotificationsService.cancel(
                _notificationIdHeader,
              );
          }
          if (_downloadPreferences.restart &&
              downloadTask.restartCount == 0 &&
              !conexionError) {
            Future.delayed(
                Duration(seconds: _downloadPreferences.restartInterval),
                () async {
              await retry(idTask);
            });
          }
          await resumeEnqueue();
        },
      );

      _addActiveTask(
        model: downloadTask,
        cancelableOperation: cancelableOperation,
        changingStatus: false,
      );
      if (_downloadPreferences.keepBackground) {
        if (!FlutterBackground.isBackgroundExecutionEnabled) {
          await enableForegroundService();
          DownloadNotificationsService.showHeaderDownloadGroup(
              notificationId: _notificationIdHeader);
        }
      }
      return true;
    } catch (err) {
      await _downloadDb.update(
        status: DownloadTaskStatus.failed,
        whereEquals: {'id_custom': idTask},
      );
      ActiveDownload activeDownload = _getActiveTask(idTask);
      _addActiveTask(
        model: activeDownload.task,
        changingStatus: false,
      );
      activeDownload.emitStatus(DownloadTaskStatus.failed);
      await resumeEnqueue();
    }
    return false;
  }

  Future<void> retry(String idTask) async {
    ActiveDownload active = _getActiveTask(idTask);
    if (active.task.status == DownloadTaskStatus.failed) {
      _addActiveTask(
          model: active.task.copyWith(
        restartCount: active.task.restartCount + 1,
      ));
    }
    await resume(idTask);
  }

  Future<List<DownloadTask>> findTasks({
    List<DownloadTaskStatus> statusAnd,
    int offset = 0,
    int limit,
    DownloadTaskType type,
  }) async {
    List<DownloadTask> tasks = await _downloadDb.find(
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

  Future<DownloadTask> findTask(String idTask) {
    return _downloadDb.findByIdCustom(idTask);
  }

  Future<bool> deleteHistoryTask(
    String idTask, {
    bool deleteFile = false,
  }) async {
    if (deleteFile) {
      DownloadTask download = await _downloadDb.findByIdCustom(idTask);
      await File(download.path).delete().catchError((err) {});
    }
    int affected = await _downloadDb.deleteByCustomId(idTask);
    return affected > 0;
  }

  Future<bool> updateTask(
    String idTask, {
    String fileName,
    String displayName,
    String saveDir,
    DataSize limitBandwidth,
  }) async {
    DownloadTask task;
    if (fileName != null || saveDir != null) {
      task = await _downloadDb.findByIdCustom(idTask);
      bool fileExist = await File(task.path).exists();
      if (task.saveDir != saveDir) {
        if (fileExist)
          await _moveFile(File(task.path), task.copyWith(saveDir: saveDir).path)
              .catchError((err) {});
        task = task.copyWith(saveDir: saveDir);
      }
      if (fileName != null) {
        if (fileExist) {
          if (task.path != task.copyWith(fileName: fileName).path) {
            await File(task.path).copy(task.copyWith(fileName: fileName).path);
            await File(task.path).delete();
          }
        }
        task = task.copyWith(fileName: fileName);
      }
    }
    int affected = await _downloadDb.update(
      fileName: fileName,
      displayName: displayName,
      limitBandwidth: limitBandwidth,
      saveDir: saveDir,
      whereEquals: {
        'id_custom': idTask,
      },
    );
    if (task != null) {
      task = task.copyWith(
        displayName: displayName,
      );
      _addActiveTask(model: task);
      _notifyActiveTaskStream();
    }
    return affected > 0;
  }

  Future<File> _moveFile(File sourceFile, String newPath) async {
    try {
      // prefer using rename as it is probably faster
      return await sourceFile.rename(newPath);
    } on FileSystemException catch (e) {
      // if rename fails, copy the source file and then delete it
      final newFile = await sourceFile.copy(newPath);
      await sourceFile.delete();
      return newFile;
    }
  }

  void _addActiveTask({
    @required DownloadTask model,
    CancelableOperation<void> cancelableOperation,
    bool changingStatus,
  }) {
    ActiveDownload active = _activeTasks.firstWhere((element) {
      DownloadTask task = element.task;
      return task.id == model.id;
    }, orElse: () => null);

    if (active == null) {
      ActiveDownload newActiveDownload = ActiveDownload(
          task: model,
          receivedStreamController: StreamController<DataSize>.broadcast(),
          speedDownloadStreamController: StreamController<DataSize>.broadcast(),
          statusStreamController:
              StreamController<DownloadTaskStatus>.broadcast(),
          cancelableOperation: cancelableOperation,
          changingStatus: changingStatus,
          onEmitStatus: (DownloadTask event) {
            ActiveDownload activeTask = _getActiveTask(event.idCustom);
            print(event);
            _addActiveTask(
              model: event.copyWith(
                status: event.status,
              ),
            );
            List<DownloadTask> tasks = _activeTasks
                .where((e) => e.task.status == DownloadTaskStatus.running)
                .map((e) => e.task)
                .toList();

            _statusChangeTaskStream?.add(event);
            if (event.status == DownloadTaskStatus.complete)
              _onCompleteTaskStream?.add(event);

            activeTask?.statusStreamController?.add(event.status);

            _statusStreamController?.add(tasks);
            if (tasks.length != _runningTaskStreamLastValue.length) {
              _runningTaskStreamLastValue = tasks.toList();
            }
            bool isEqual =
                ListEquality().equals(tasks, _runningTaskStreamLastValue);
            if (!isEqual) {
              _runningTaskStreamLastValue = tasks.toList();
            }
          });
      _activeTasks.add(newActiveDownload);
      newActiveDownload.statusStreamController.sink
          .add(newActiveDownload.task.status);
      newActiveDownload.receivedStreamController.sink
          .add(newActiveDownload.task.sizeDownloaded);
    } else {
      // ActiveDownload activeTask = tasks.firstWhere(
      //   (e) => e.task.idCustom == model.idCustom,
      //   orElse: () => null,
      // );
      if (active != null) {
        _activeTasks[_activeTasks.indexOf(active)] = active = active.copyWith(
          task: model,
          cancelableOperation: cancelableOperation,
          changingStatus: changingStatus,
        );
      }
    }
  }

  Future<void> _removeActiveTask(String idTask) async {
    ActiveDownload activeTask = _activeTasks.firstWhere(
      (e) => e.task.idCustom == idTask,
      orElse: () => null,
    );
    await activeTask?.receivedStreamController?.close();
    await activeTask?.speedDownloadStreamController?.close();
    await activeTask?.statusStreamController?.close();
    _activeTasks.remove(activeTask);
  }

  ActiveDownload _getActiveTask(String idTask) {
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

  List<DownloadTask> get activeTasks {
    List<DownloadTask> tasks = _activeTasks.map((e) {
      return e.task;
    }).toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  DownloadTask activeTask(String idTask) {
    return _getActiveTask(idTask)?.task ?? null;
  }

  Stream<DataSize> receibedStream(String idTask) {
    return _getActiveTask(idTask)?.receivedStreamController?.stream ?? null;
  }

  Stream<DataSize> speedDownloadStream(String idTask) {
    return _getActiveTask(idTask)?.speedDownloadStreamController?.stream ??
        null;
  }

  Stream<DownloadTaskStatus> statusTaskStream(String idTask) {
    return _getActiveTask(idTask)?.statusStreamController?.stream ?? null;
  }

  void _notifyActiveTaskStream() {
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
