import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/home/views/widgets/queue_tile_1.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:download_d/modules/settings/views/pages/downloads_settings_page.dart';

class SettingsFragment extends StatefulWidget {
  const SettingsFragment({Key key}) : super(key: key);

  @override
  _SettingsFragmentState createState() => _SettingsFragmentState();
}

class _SettingsFragmentState extends State<SettingsFragment> {
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
    return ListView(
      children: [
        ListTile(
          title: Text(
            'Generales',
            style: TextStyle(
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.get_app_rounded),
          title: Text('Descargas'),
          onTap: (){
            
          },
        ),
        ListTile(
          leading: Icon(Icons.notifications_rounded),
          title: Text('Notificaciónes'),
        ),
        ListTile(
          leading: Icon(Icons.brightness_medium_rounded),
          title: Text('Apariencia'),
        ),
        ListTile(
          leading: Icon(Icons.language_rounded),
          title: Text('Idioma'),
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
    );

    return ListView(
      children: [
        ListTile(
          title: Text(
            'Descargas',
            style: TextStyle(
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        ListTile(
          title: Text('Carpeta para descargas'),
          subtitle: Text('/storage/emulated/0/Download'),
        ),
        ListTile(
          title: Text('Descargas simultaneas'),
          subtitle: Text('1 (Secuencial)'),
        ),
        SwitchListTile(
          title: Text('Reiniciar descarga'),
          subtitle: Text('Si hay errores o interrupción de conexión'),
          value: false,
          onChanged: (value) {},
        ),
        SwitchListTile(
          isThreeLine: true,
          title: Text('Mantener la aplicación en segundo plano'),
          subtitle: Text(
              'Active para que el dispositivo no suspenda la aplicación mientras la descarga esta en curso'),
          value: false,
          onChanged: (value) {},
        ),
        Divider(),
        ListTile(
          title: Text(
            'Apariencia',
            style: TextStyle(
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        ListTile(
          title: Text('Tema'),
          subtitle: Text('Claro'),
        ),
        ListTile(
          title: Text('Lenguaje de la aplicación'),
          subtitle: Text('Español'),
        ),
        ListTile(
          isThreeLine: true,
          contentPadding: EdgeInsets.zero,
          title: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Estilo de las descargas'),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Barra espaciadora'),
              ),
              QueueTile1(
                title: 'Descarga',
                status: DownloadTaskStatus.paused,
                downlaoded: DataSize(
                  mebibytes: 512,
                ),
                size: DataSize(
                  // megabytes: 777,
                  mebibytes: 1024,
                ),
              ),
            ],
          ),
          onTap: () {},
        ),
        SizedBox(height: 100),
      ],
    );
  }
}
