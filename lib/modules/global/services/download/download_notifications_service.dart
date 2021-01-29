import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models/data_size.dart';

abstract class DownloadNotificationsService {
  static bool _initialized = false;
  static FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static int _notificationId = 1;
  static String _channelName = 'Downloads';
  static String _channelDescription =
      'Downloads of Oshinstar documents and media files';

  static Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await _flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('drawable/nofication_icon'),
        // android: AndroidInitializationSettings('drawable/notify_icon'),
      ),
    );
    _initialized = true;
  }

  // ignore: unused_element
  static Future<void> _initIfNot() async {
    if (!_initialized) initialize();
  }

  static Future<void> showNotificationsEnabled() async {
    await _flutterLocalNotificationsPlugin.show(
      _notificationId,
      'Ejecutando servicio',
      'La aplicación se ejecutando en segundo plano',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'foreground_enabled_notification',
          'Foreground service',
          'Notifica que la aplicacion se ejecuta en segundo plano',
          // groupKey: 'downloadsssss',
          // setAsGroupSummary: true,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          // channelShowBadge: false,
        ),
      ),
    );
  }

  static Future<void> showHeaderDownloadGroup({
    @required int notificationId,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      'Download D',
      'La aplicación se esta ejecutando en segundo plano',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'download_d_task_channel',
          'Download status',
          'El estado de las descargas',
          showProgress: false,
          maxProgress: 100,
          groupKey: 'progress_tasks_group',
          setAsGroupSummary: true,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: false,
          ongoing: false,
          playSound: false,
          enableVibration: false,
          channelShowBadge: false,
        ),
      ),
    );
  }

  static Future<void> showProgressDownload({
    @required notificationId,
    @required String title,
    @required DataSize size,
    int notificationIdHeaderHroup,
    DataSize sizeDownload,
    DataSize speedDownload,
    AndroidNotificationChannelAction channelAction =
        AndroidNotificationChannelAction.createIfNotExists,
    bool setAsGroupSummary,
    bool showProgress=true,
  }) async {
    if (sizeDownload == null) sizeDownload = DataSize.zero;
    int progress = 0;
    if ((sizeDownload?.inBytes ?? 0) > 0) {
      progress = (sizeDownload.inBytes * 100) ~/ size.inBytes;
    }

    String subtitle = '';
    if ((size?.inBytes ?? 0) > 0 && (sizeDownload?.inBytes ?? 0) > 0) {
      subtitle += '$progress % (${sizeDownload.format()}/${size.format()}) ';
      if ((speedDownload?.inBytes ?? 0) > 0)
        subtitle += "${speedDownload.format()}/s";
    }

    if (channelAction == AndroidNotificationChannelAction.createIfNotExists) {
      await showHeaderDownloadGroup(notificationId: notificationIdHeaderHroup);
      // await _flutterLocalNotificationsPlugin.show(
      //   notificationIdHeaderHroup,
      //   'title',
      //   subtitle,
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'download_d_task_channel',
      //       'Download status',
      //       'El estado de las descargas',
      //       showProgress: true,
      //       maxProgress: 100,
      //       progress: progress,
      //       groupKey: 'progress_tasks_group',
      //       setAsGroupSummary: true,
      //       channelAction: channelAction,
      //       importance: Importance.defaultImportance,
      //       priority: Priority.defaultPriority,
      //       autoCancel: false,
      //       ongoing: true,
      //       playSound: false,
      //       enableVibration: false,
      //       channelShowBadge: false,
      //     ),
      //   ),
      // );
    }

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      subtitle,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'download_d_task_channel',
          'Download status',
          'El estado de las descargas',
          showProgress: showProgress,
          maxProgress: 100,
          progress: progress,
          groupKey: 'progress_tasks_group',
          setAsGroupSummary: setAsGroupSummary,
          channelAction: channelAction,
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
  }

  static Future<void> showFinishedDownload({
    @required int idNotification,
    @required String displayName,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      -25,
      'Descarga finalizada',
      displayName,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          _channelName,
          _channelDescription,
          groupKey: 'download_finished',
          setAsGroupSummary: true,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          // channelShowBadge: false,
        ),
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      idNotification,
      'Descarga finalizada',
      displayName,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          _channelName,
          _channelDescription,
          groupKey: 'download_finished',
          setAsGroupSummary: false,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          // channelShowBadge: false,
        ),
      ),
    );
  }

  static Future<void> cancel(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  static Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}