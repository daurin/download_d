import 'dart:async';
import 'dart:io';
import 'package:download_d/modules/global/services/download_service/data_size.dart';
import 'package:download_d/modules/global/services/download_service/download_http_helper.dart';
import 'package:download_d/modules/global/services/download_service/download_notifications_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'download_preferences_repository.dart';
import 'download_task_repository.dart';
import 'models/download_task.dart';
import 'models/download_task_status.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

abstract class DownloadService {
  static bool _initialized = false;
  static StreamController<List<DownloadTask>> _enqueuedStreamController;
  static StreamController<List<DownloadTask>> _runningStreamController;

  static List<Map<String, dynamic>> _activeTasks = [];

  static DownloadTaskRepository _downloadDb = DownloadTaskRepository();

  static DownloadPreferencesRepository _downloadPreferences;

  static DownloadPreferencesRepository get preferences => _downloadPreferences;

  static Future<void> start() async {
    if (_initialized) return;
    _initialized = true;
    _downloadPreferences = DownloadPreferencesRepository();
    _runningStreamController = StreamController<List<DownloadTask>>.broadcast();
    _enqueuedStreamController =
        StreamController<List<DownloadTask>>.broadcast();
    await DownloadNotificationsService.initialize();

    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    // String file5mb = 'http://212.183.159.230/5MB.zip',
    //     file10mb = 'http://212.183.159.230/10MB.zip',
    //     file20mb = 'http://212.183.159.230/20MB.zip',
    //     file50mb = 'http://212.183.159.230/50MB.zip',
    //     file100mb = 'http://212.183.159.230/100MB.zip';
    // String videoYoutube =
    //     'https://redirector.googlevideo.com/videoplayback?expire=1610726159&ei=r2YBYIKNNNPb7gPrho_YBw&ip=93.170.35.14&id=o-AB_N38DzLYd48JLgXKvwBrkO5PpUudFhygY75oFRk0vb&itag=22&source=youtube&requiressl=yes&mh=-B&mm=31%2C29&mn=sn-punu5gjvhx03g-ig3e%2Csn-3c27sn7y&ms=au%2Crdu&mv=m&mvi=1&pcm2cms=yes&pl=24&initcwndbps=651250&vprv=1&mime=video%2Fmp4&ns=ezalh58SIHtGNlKH1KhhmwgF&ratebypass=yes&dur=30.093&lmt=1602727984405029&mt=1610704362&fvip=18&c=WEB&txp=5432434&n=aq_c3DK8F90WuI&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cvprv%2Cmime%2Cns%2Cratebypass%2Cdur%2Clmt&sig=AOq0QJ8wRAIgDDZeVOif34gTSR41EOnxQnAmA4-ofDYRJjpGdmu_VxICIBIS37fi6CKuTSwyM9ELE-THcj4DYlVBUaB929ADWT72&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpcm2cms%2Cpl%2Cinitcwndbps&lsig=AG3C_xAwRAIgAbDtgS60whuVI2xMNbiZlSgbrjo51KwVDU-p9IQDPzgCIAKHT7ZX5mSiaxUR6uksN_MFtwHuaBv-hJk9A67aqbb9&title=%22Yee+Yee+Ass+Haircut%22+%28GTA+V+PS4%29';

    // DownloadNotificationsService.showProgressDownload(
    //   title: 'test',
    //   sizeDownload: 0,
    //   size: 1000,
    // );

    // int lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;

    // DownloadHttpHelper.download(
    //   url: file20mb,
    //   savePath: '/storage/emulated/0/Download/20MB.zip',
    //   // headers: headers,
    //   onReceived: (receibed) {
    //     if ((DateTime.now().millisecondsSinceEpoch -
    //             lastCallUpdateNotification) >
    //         Duration(milliseconds: 500).inMilliseconds) {
    //       lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;
    //       DownloadNotificationsService.showProgressDownload(
    //         title: 'test',
    //         sizeDownload: receibed,
    //         size: contentLength,
    //         channelAction: AndroidNotificationChannelAction.update,
    //       );
    //     }
    //   },
    //   onProgress: (progress) {
    //     // print(progress);
    //   },
    //   onComplete: () {
    //     Future.delayed(Duration(seconds: 2), () {
    //       DownloadNotificationsService.showNotificationsEnabled();
    //     });
    //   },
    // );
  }

  static Future<void> stop() async {
    if (!_initialized) return;
    await _runningStreamController.close();
    await _enqueuedStreamController.close();
    await DownloadNotificationsService.cancel();
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

  static Future<void> addTask({
    String id,
    @required String url,
    @required String saveDir,
    String fileName,
    Map<String, dynamic> headers,
    bool autoStart = true,
    String displayName,
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
        size: contentLenght,
        mimeType: responseHead.headers.contentType.value,
        headers: headers,
        showNotification: true,
        resumable: responseHead.headers['Accept-Ranges'] != null,
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

  static Future<void> resume(String idTask) async {
    if (runningTaskTotal >= _downloadPreferences.simultaneousDownloads) {
      return;
    }
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }

    try {
      DownloadTask downloadTask =
          await DownloadTaskRepository().findByIdCustom(idTask);
      int lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;

      if (downloadTask.status == DownloadTaskStatus.complete) {
        if(await File(downloadTask.path).exists())await File(downloadTask.path).delete();
      }

      if(downloadTask.status != DownloadTaskStatus.running){
        await DownloadTaskRepository()
            .update(status: DownloadTaskStatus.running, whereEquals: {
          'id_custom': idTask,
        });
      }


      DownloadNotificationsService.showProgressDownload(
        title: downloadTask.displayName,
        sizeDownload: 0,
        size: downloadTask.size,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
      );

      // ignore: close_sinks
      HttpClientRequest request = await DownloadHttpHelper.download(
        url: downloadTask.url,
        savePath: downloadTask.saveDir + '/' + downloadTask.fileName,
        headers: downloadTask.headers,
        resume: downloadTask.resumable,
        // limitBandwidth: 40000,
        onReceived: (receivedLength, contentLength) async {
          if ((DateTime.now().millisecondsSinceEpoch -
                  lastCallUpdateNotification) >
              Duration(milliseconds: 500).inMilliseconds) {
            lastCallUpdateNotification = DateTime.now().millisecondsSinceEpoch;
            if (downloadTask.showNotification)
              await DownloadNotificationsService.showProgressDownload(
                title: downloadTask.displayName,
                sizeDownload: receivedLength,
                size: contentLength,
                channelAction: AndroidNotificationChannelAction.update,
              );
          }
        },
        onSpeedDownloadChange: (bytesInSeconds) {
          // print('${DataSize.formatBytes(bytesInSeconds)}/sec');
        },
        onComplete: () async {
          DownloadNotificationsService.cancel();
          await DownloadTaskRepository().update(
            status: DownloadTaskStatus.complete,
            completedAt: DateTime.now(),
            whereEquals: {'id_custom': idTask},
          );
          _removeActiveTask(idTask);

          if (downloadTask.showNotification)
            await DownloadNotificationsService.showFinishedDownload(
              idNotification: downloadTask.id,
              displayName: downloadTask.displayName,
            );
        },
      );
      _addActiveTask(
        model: downloadTask,
        request: request,
      );
    } catch (err) {
      print(err);
    }
  }

  static Future<void> retry(int idTask) async {}

  static void _addActiveTask({
    @required DownloadTask model,
    @required HttpClientRequest request,
  }) {
    List<Map<String, dynamic>> task = _activeTasks.where((element) {
      DownloadTask task = element['model'];
      return task.id == model.id;
    }).toList();

    if (task == null) {
      _activeTasks.add({
        'model': model,
        'request': request,
      });
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

  static int get runningTaskTotal {
    List<Map<String, dynamic>> tasks = _activeTasks.where((element) {
      DownloadTask task = element['model'];
      return task.status == DownloadTaskStatus.running;
    }).toList();
    return tasks.length;
    // List<DownloadTask> tasks = await _runningStreamController.stream.last;
    // return tasks.length;
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
