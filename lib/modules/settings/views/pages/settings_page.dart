import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'downloads_settings_page.dart';
import 'notifications_settings_page.dart';
import 'apparence_settings_page.dart';
import 'language_setting_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PackageInfo _packageInfo;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _packageInfo = await PackageInfo.fromPlatform();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              'General',
              style: TextStyle(
                color: Theme.of(context).accentColor,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.get_app_rounded),
            title: Text('Descargas'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DownloadsSettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_rounded),
            title: Text('Notificaciónes'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NotificationsSettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.brightness_medium_rounded),
            title: Text('Apariencia'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ApparenceSettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.language_rounded),
            title: Text('Idioma'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LanguageSettingPage()));
            },
          ),
          ListTile(
            title: Text(
              'Información',
              style: TextStyle(
                color: Theme.of(context).accentColor,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.star_rate_rounded),
            title: Text('Valorar esta aplicación'),
          ),
          ListTile(
            leading: Icon(Icons.info_rounded),
            title: Text('Acerca de'),
            onTap: _onTapAbout,
          ),
          // ListTile(
          //   // leading: Icon(Icons.info_rounded),
          //   title: Text('Version de la aplicación'),
          //   subtitle: Text('${_packageInfo?.version ?? ''}'),
          // ),
          ListTile(
            // leading: Icon(Icons.info_rounded),
            title: Center(
              child: Text(
                '${_packageInfo?.appName ?? ''} version ${_packageInfo?.version ?? ''}',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTapAbout() {
    showAboutDialog(
        context: context,
        applicationIcon: Image.asset(
          'assets/launcher/app_icon_3.png',
          height: 48,
          width: 48,
        ),
        applicationName: _packageInfo.appName,
        applicationVersion: _packageInfo.version,
        children: [
          Text('Autor: Daurin Lora'),
        ]);
  }
}
