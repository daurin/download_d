import 'package:download_d/modules/global/services/download/download_preferences_repository.dart';
import 'package:flutter/material.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({Key key}) : super(key: key);

  @override
  _NotificationsSettingsPageState createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {

  DownloadPreferencesRepository _downloadPreferences;
  bool _enabledNotifications;
  bool _showProgressBarNotifications;
  bool _notifyOnFinished;

  @override
  void initState() {
    super.initState();
    _downloadPreferences=DownloadPreferencesRepository();
    _enabledNotifications=_downloadPreferences.enabledNotifications;
    _showProgressBarNotifications=_downloadPreferences.showProgressBarNotifications;
    _notifyOnFinished=_downloadPreferences.notifyOnFinished;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            isThreeLine: _downloadPreferences.keepBackground && !_enabledNotifications,
            title: Text('Notificaciones'),
            subtitle: Builder(
              builder: (context) {
                if(_enabledNotifications)return Text('habilita todas las notificaciones');
                else if(_downloadPreferences.keepBackground)return Text('No se mostrara ninguna notificación a excepción de la notificación que indica que se esta ejefcutando en segundo plano');
                return Text('No se mostrara ninguna notificación');
              }
            ),
            value: _enabledNotifications,
            onChanged: (value) {
              _downloadPreferences.enabledNotifications = value;
              setState(() {
                _enabledNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Mostrar barra de progreso'),
            value: _showProgressBarNotifications,
            onChanged: !_enabledNotifications ? null : (value) {
              _downloadPreferences.showProgressBarNotifications = value;
              setState(() {
                _showProgressBarNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Notificar al finalizar una descarga'),
            value: _notifyOnFinished,
            onChanged: !_enabledNotifications ? null : (value) {
              _downloadPreferences.notifyOnFinished = value;
              setState(() {
                _notifyOnFinished = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
