import 'dart:async';
import 'dart:io';
import 'package:download_d/modules/global/services/download_service/download_task_helper.dart';
import 'package:download_d/modules/global/services/download_service/download_notifications_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'data_size.dart';
import 'download_preferences_repository.dart';
import 'download_task_repository.dart';
import 'models/download_task.dart';
import 'models/download_task_status.dart';
import 'models/download_task_type.dart';

abstract class DownloadService {
  static StreamController<List<DownloadTask>> _enqueuedStreamController;
  static StreamController<List<DownloadTask>> _runningStreamController;

  static DownloadTaskRepository _downloadDb = DownloadTaskRepository();

  static DownloadPreferencesRepository _downloadPreferences;

  static DownloadPreferencesRepository get preferences => _downloadPreferences;

  static Future<int> get runningTaskTotal async {
    List<DownloadTask> tasks = await _runningStreamController.stream.last;
    return tasks.length;
  }

  static Future<int> get enqueuedTaskTotal async {
    List<DownloadTask> tasks = await _runningStreamController.stream.last;
    return tasks.length;
  }

  static Future<void> start() async {
    _downloadPreferences = DownloadPreferencesRepository();
    _runningStreamController = StreamController<List<DownloadTask>>.broadcast();
    _enqueuedStreamController =
        StreamController<List<DownloadTask>>.broadcast();
    await DownloadNotificationsService.initialize();

    DownloadHttpHelper.download(
      url:
          'http://212.183.159.230/10MB.zip',
      savePath: 'null',
    );
  }

  static Future<void> stop() async {
    DownloadNotificationsService.cancel();
    await _runningStreamController.close();
    await _enqueuedStreamController.close();
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
    @required String id,
    @required String url,
    @required String path,
    Map<String, dynamic> headers,
    bool autoStart = false,
    String displayName,
  }) async {
    HttpClientResponse response =await DownloadHttpHelper.head(
      url:'http://212.183.159.230/10MB.zip',
    );
    int contentLenght = int.parse(response.headers['content-length'] ?? '0');

    String formatedSize = DataSize.formatBytes(contentLenght);
    print(formatedSize);

    DownloadTaskStatus status = DownloadTaskStatus.enqueued;
    if (autoStart &&
        await runningTaskTotal < _downloadPreferences.simultaneousDownloads) {
      status = DownloadTaskStatus.running;
    }

    int idDb = await _downloadDb.add(
      idCustom: id,
      url: url,
      status: status,
      path: path,
      size: contentLenght,
      type: DownloadTaskType.video,
    );
  }

  static Future<void> download() async {}

  static Future<void> pause(int idTask) async {}

  static Future<void> cancel(int idTask) async {}

  static Future<void> cancelAll() async {}

  static Future<void> resume(int idTask) async {}

  static Future<void> retry(int idTask) async {}
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
