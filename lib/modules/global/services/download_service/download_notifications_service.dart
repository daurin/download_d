import 'package:download_d/modules/global/services/download_service/data_size.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      'Oshinstar se ejecuta en segundo plano',
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

  static Future<void> showProgressDownload({
    @required String title,
    @required int size,
    int sizeDownload = 0,
    AndroidNotificationChannelAction channelAction =
        AndroidNotificationChannelAction.createIfNotExists,
  }) async {
    int progress = (sizeDownload * 100) ~/ size;

    await _flutterLocalNotificationsPlugin.show(
      _notificationId,
      title,
      '$progress % (${DataSize.formatBytes(sizeDownload)}/${DataSize.formatBytes(size)})',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'download_d_task_channel',
          'Download status',
          'El estado de las descargas',
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          // groupKey: 'downloadsssss',
          // setAsGroupSummary: true,
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
    int idNotification=2,
    @required String displayName,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      idNotification,
      'Descarga finalizada',
      displayName,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          _channelName,
          _channelDescription,
          groupKey: 'downloads',
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

  static Future<void> cancel() async {
    await _flutterLocalNotificationsPlugin.cancel(_notificationId);
  }
}
