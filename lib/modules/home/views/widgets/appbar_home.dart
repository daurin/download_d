import 'package:download_d/modules/global/services/download/download_preferences_repository.dart';
import 'package:download_d/modules/global/services/download/download_service.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/services/download/singleton/download_file_service.dart';
import 'package:download_d/modules/settings/views/pages/settings_page.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';

class AppBarHome extends StatelessWidget implements PreferredSizeWidget {
  final bool visibleResumeAll;
  const AppBarHome({
    Key key,
    this.visibleResumeAll = false,
  }) : super(key: key);

  Size get preferredSize => Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: ValueKey('afdsifhdsjgs'),
      title: Text("Download D"),
      actions: [
        ButtonBar(
          children: [
            TextButton(
              child: Text('Test'),
              style: TextButton.styleFrom(
                primary: Colors.white,
              ),
              onPressed: _testDownload,
            ),
            if (visibleResumeAll)
              StreamBuilder<List<DownloadTask>>(
                stream: DownloadFileService().statusStream,
                initialData: DownloadFileService().activeTasks.where((e) {
                  return e.status == DownloadTaskStatus.running;
                }).toList(),
                builder: (context, snapshot) {
                  if (snapshot.data.length > 0) {
                    return IconButton(
                      tooltip: 'Resumir todo',
                      icon: Icon(Icons.pause_rounded),
                      onPressed: () async {
                        await DownloadFileService().pauseAll(
                          resumeEnqueueTask: false,
                        );
                      },
                    );
                  } else
                    return IconButton(
                      tooltip: 'Pausar todo',
                      icon: Icon(Icons.play_arrow_rounded),
                      onPressed: () async {
                        await DownloadFileService().resumeAll();
                      },
                    );
                },
              ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded),
              itemBuilder: (context) {
                List<PopupMenuItem> items = [];

                if (visibleResumeAll)
                  items.add(PopupMenuItem(
                    child: ListTile(
                      // leading: Icon(Icons.clear_all_rounded),
                      title: Text('Cancelar todo'),
                      onTap: () async {
                        Navigator.pop(context);
                        await DownloadFileService().cancelAll();
                      },
                    ),
                    value: 'cancel_all',
                  ));

                items.add(PopupMenuItem(
                  child: ListTile(
                    // leading: Icon(Icons.settings_rounded),
                    title: Text('Configuracion'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SettingsPage()));
                    },
                  ),
                  value: 'settings',
                ));

                return items;
              },
            ),
          ],
        )
      ],
    );
  }

  void _testDownload() async {
    String file5mb = 'http://212.183.159.230/5MB.zip',
        file10mb = 'http://212.183.159.230/10MB.zip',
        file20mb = 'http://212.183.159.230/20MB.zip',
        file50mb = 'http://212.183.159.230/50MB.zip',
        file100mb = 'http://212.183.159.230/100MB.zip';

    await DownloadFileService().addTask(
      id: 'big_buck_bunny_720p_2mbgdfg',
      url: 'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4',
      saveDir: DownloadPreferencesRepository().downloadPath,
    );

    for (int i = 0; i < 5; i++) {
      await DownloadFileService().addTask(
        id: '10mbtest${i + 1}',
        url: file10mb,
        fileName: '10MB(${i + 1}).zip',
        saveDir: DownloadPreferencesRepository().downloadPath,
        // limitBandwidth: DataSize(
        //   kilobytes: 400,
        // ),
      );
    }
    await DownloadFileService().resumeEnqueue();
  }
}
