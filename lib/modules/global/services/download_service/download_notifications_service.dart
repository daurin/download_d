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
        android: AndroidInitializationSettings('drawable/notify_icon'),
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
          'downloads',
          _channelName,
          _channelDescription,
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

  static Future<void> cancel()async{
    await _flutterLocalNotificationsPlugin.cancel(_notificationId);
  }
}
