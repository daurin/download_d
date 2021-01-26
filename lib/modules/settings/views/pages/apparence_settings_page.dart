import 'package:download_d/modules/global/services/download/download_preferences_repository.dart';
import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/models/download_style_item.dart';
import 'package:download_d/modules/home/views/widgets/queue_tile_1.dart';
import 'package:download_d/modules/settings/blocs/pref_apparence_local_storage.dart';
import 'package:download_d/modules/settings/blocs/settings_display/settings_display_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApparenceSettingsPage extends StatefulWidget {
  const ApparenceSettingsPage({Key key}) : super(key: key);

  @override
  _ApparenceSettingsPageState createState() => _ApparenceSettingsPageState();
}

class _ApparenceSettingsPageState extends State<ApparenceSettingsPage> {
  DownloadPreferencesRepository _downloadPreferences;
  DownloadStyleItem _downloadItemStyle;

  @override
  void initState() {
    super.initState();
    _downloadPreferences = DownloadPreferencesRepository();
    _downloadItemStyle = PrefApparenceLocalStorage().downloadStyleItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apariencia'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Tema'),
            subtitle: Builder(builder: (context) {
              switch (BlocProvider.of<SettingsDisplayBloc>(context)
                  .state
                  .themeMode) {
                case ThemeMode.system:
                  return Text('Predeterminado del sistema');
                case ThemeMode.light:
                  return Text('Claro');
                case ThemeMode.dark:
                  return Text('Oscuro');
                default:
                  return null;
              }
            }),
            onTap: _onTapTheme,
          ),
          Divider(),
          ListTile(
            // isThreeLine: true,
            contentPadding: EdgeInsets.zero,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Estilo de las descargas'),
            ),
            // subtitle: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     SizedBox(height: 4),
            //     Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 16.0),
            //       child: Text('Barra espaciadora'),
            //     ),
            //     QueueTile1(
            //       title: 'Descarga',
            //       status: DownloadTaskStatus.paused,
            //       downlaoded: DataSize(
            //         mebibytes: 512,
            //       ),
            //       size: DataSize(
            //         // megabytes: 777,
            //         mebibytes: 1024,
            //       ),
            //     ),
            //   ],
            // ),
            onTap: () {},
          ),
          RadioListTile(
            value: DownloadStyleItem.linear.value,
            groupValue: _downloadItemStyle.value,
            title: Text('Barra linear'),
            onChanged: (value) {
              setState(() {
                _downloadItemStyle = DownloadStyleItem.from(value);
              });
              BlocProvider.of<SettingsDisplayBloc>(context).setDownloadStyleItem(value);
            },
          ),
          RadioListTile(
            value: DownloadStyleItem.circular.value,
            groupValue: _downloadItemStyle.value,
            title: Text('Barra circular'),
            onChanged: (value) {
              setState(() {
                _downloadItemStyle = DownloadStyleItem.from(value);
              });
              BlocProvider.of<SettingsDisplayBloc>(context).setDownloadStyleItem(value);
            },
          ),
          QueueTile1(
            title: 'Example-file.rar',
            status: DownloadTaskStatus.paused,
            downlaoded: DataSize(
              mebibytes: 512,
            ),
            size: DataSize(
              // megabytes: 777,
              mebibytes: 1024,
            ),
            showLinearProgress: _downloadItemStyle == DownloadStyleItem.linear,
            showCircularProgress:
                _downloadItemStyle == DownloadStyleItem.circular,
          )
        ],
      ),
    );
  }

  _onTapTheme() async {
    ThemeMode themeModeSelected =
        BlocProvider.of<SettingsDisplayBloc>(context).state.themeMode;

    Future<void> Function(ThemeMode value) onChange = (value) async {
      await BlocProvider.of<SettingsDisplayBloc>(context).setThemeMode(value);
      Navigator.pop(context);
    };

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Escoge un tema',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeModeSelected,
              onChanged: onChange,
              title: Text('Predeterminado del sistema'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeModeSelected,
              onChanged: onChange,
              title: Text('Claro'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeModeSelected,
              onChanged: onChange,
              title: Text('Oscuro'),
            ),
          ],
        );
      },
    );
  }
}
