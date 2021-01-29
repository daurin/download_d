import 'dart:io';

import 'package:download_d/modules/global/services/download/download_preferences_repository.dart';
import 'package:download_d/modules/global/services/download/singleton/download_file_service.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_ex/path_provider_ex.dart';

class DownloadsSettingsPage extends StatefulWidget {
  const DownloadsSettingsPage({Key key}) : super(key: key);

  @override
  _DownloadsSettingsPageState createState() => _DownloadsSettingsPageState();
}

class _DownloadsSettingsPageState extends State<DownloadsSettingsPage> {
  
  DownloadPreferencesRepository _downloadPreferences;
  List<StorageInfo> _storageInfo;
  Directory _rootDirectoryDownload;
  Directory _downloadsPath;

  int _simultaneousDownloads;
  bool _restartDownload;
  bool _keepBackground;

  @override
  void initState() {
    super.initState();
    _downloadPreferences = DownloadFileService().preferences;
    _downloadsPath=Directory(_downloadPreferences.downloadPath);
    _simultaneousDownloads = _downloadPreferences.simultaneousDownloads;
    _restartDownload = _downloadPreferences.restart;
    _keepBackground = _downloadPreferences.keepBackground;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
      _storageInfo=await PathProviderEx.getStorageInfo();
      String _rootDir = await ExtStorage.getExternalStorageDirectory();
      if(_rootDir.length>0)_rootDirectoryDownload=Directory(_storageInfo[0].rootDir); 
      
    });
  }

      
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Descargas'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Carpeta para descargas'),
            subtitle: Text(_downloadsPath.path),
            onTap: () async{
              String path = await FilesystemPicker.open(
                title: 'Carpeta para descargas',
                context: context,
                rootDirectory: _rootDirectoryDownload,
                fsType: FilesystemType.folder,
                pickText: 'Seleccionar esta carpeta',
                // folderIconColor: Colors.teal,
              );
              if(path!=null){
                _downloadPreferences.downloadPath=path;
                setState(() {
                  _downloadsPath=Directory(path);
                });
              }
            },
          ),
          Divider(),
          ListTile(
            title: Text('Descargas simultaneas'),
            subtitle: Builder(builder: (context) {
              if (_simultaneousDownloads == 1) {
                return Text('1 (Secuencial)');
              }
              return Text('$_simultaneousDownloads descargas');
            }),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _simultaneousDownloads.toDouble(),
              min: 1,
              max: 20,
              onChangeEnd: (value) {
                _downloadPreferences.simultaneousDownloads = value.toInt();
              },
              onChanged: (value) {
                setState(() {
                  _simultaneousDownloads = value.toInt();
                });
              },
            ),
          ),
          Divider(),
          SwitchListTile(
            title: Text('Reiniciar descarga'),
            subtitle: Text('Si hay errores o interrupción de conexión'),
            value: _restartDownload,
            onChanged: (value) {
              _downloadPreferences.restart = value;
              setState(() {
                _restartDownload = value;
              });
            },
          ),
          SwitchListTile(
            isThreeLine: true,
            title: Text('Mantener la aplicación en segundo plano'),
            subtitle: Text(
                'Active para que el dispositivo no suspenda la aplicación mientras la descarga esta en curso'),
            value: _keepBackground,
            onChanged: (value) {
              _downloadPreferences.keepBackground = value;
              setState(() {
                _keepBackground = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
