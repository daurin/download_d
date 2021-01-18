import 'package:download_d/modules/global/services/download_service/download_service.dart';
import 'package:download_d/modules/home/views/fragments/queue_fragment.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedFragment;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await DownloadService.start();
    });

    _selectedFragment = 0;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Download D"),
          actions: [
            ButtonBar(
              children: [
                IconButton(
                  tooltip: 'Resumir/Pausar todo',
                  icon: Icon(Icons.pause_rounded),
                  onPressed: () {},
                ),
                IconButton(
                  tooltip: 'Configuración',
                  icon: Icon(Icons.settings_rounded),
                  onPressed: () {},
                ),
                // PopupMenuButton(
                //   icon: Icon(Icons.more_vert_rounded),
                //   onSelected: (value) {},
                //   itemBuilder: (context) {
                //     return [
                //       PopupMenuItem(
                //         child: Text('Configuracion'),
                //         value: 'settings',
                //       ),
                //     ];
                //   },
                // ),
              ],
            )
          ],
        ),
        body: IndexedStack(
          index: _selectedFragment,
          children: [
            QueueFragment(),
            Center(
              child: Text('Historial'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add_rounded),
          onPressed: () async {
            String file5mb = 'http://212.183.159.230/5MB.zip',
                file10mb = 'http://212.183.159.230/10MB.zip',
                file20mb = 'http://212.183.159.230/20MB.zip',
                file50mb = 'http://212.183.159.230/50MB.zip',
                file100mb = 'http://212.183.159.230/100MB.zip';

            String downloadDir = await ExtStorage.getExternalStorageDirectory();
            downloadDir +='/'+ ExtStorage.DIRECTORY_DOWNLOADS;
            DownloadService.addTask(
              id: 'task3',
              url: file20mb,
              saveDir: '$downloadDir',
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedFragment,
          selectedFontSize: 12.0,
          unselectedFontSize: 12.0,
          onTap: (int index) {
            setState(() {
              _selectedFragment = index;
            });
          },
          items: [
            BottomNavigationBarItem(
                label: 'Cola', icon: Icon(Icons.download_rounded)),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Historial',
            ),
          ],
        ),
      ),
    );
  }

  void test() {}
}
