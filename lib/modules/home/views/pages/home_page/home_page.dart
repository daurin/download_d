import 'dart:async';
import 'package:download_d/modules/global/services/download/download_preferences_repository.dart';
import 'package:download_d/modules/global/services/download/download_service.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/home/views/fragments/queue_fragment.dart';
import 'package:download_d/modules/home/views/widgets/appbar_home.dart';
import 'package:download_d/modules/history/views/widgets/appbar_history.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedFragment;
  bool _visibleResumeAll;
  StreamSubscription<List<DownloadTask>> _runningTaskSubscription;
  StreamSubscription<List<DownloadTask>> _activeTaskSubscription;
  bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _visibleResumeAll = false;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await DownloadService.start(
        resume: !DownloadPreferencesRepository().lastStatusIsPaused,
      );
      _runningTaskSubscription =
          DownloadService.runningTaskStream.listen(_runningTaskListen);
      _activeTaskSubscription =
          DownloadService.activeTaskCountStream?.listen(_activeTaskListen);
      _visibleResumeAll = DownloadService.activeTasks.length > 0;

      _visibleResumeAll = false;
      _visibleResumeAll = DownloadService.activeTasks.length > 0;

      if (DownloadPreferencesRepository().downloadPath == null) {
        String downloadDir = await ExtStorage.getExternalStorageDirectory();
        downloadDir += '/' + ExtStorage.DIRECTORY_DOWNLOADS;
        DownloadPreferencesRepository().downloadPath=downloadDir;
      }

      setState(() {
        _isLoading = false;
      });
    });

    _selectedFragment = 0;
  }

  @override
  void dispose() {
    _runningTaskSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Builder(builder: (context) {
          if (_isLoading)
            return Center(
              child: CircularProgressIndicator(),
            );

          return IndexedStack(
            index: _selectedFragment,
            children: [
              QueueFragment(
                key: ValueKey('QueueFragment'),
              ),
              Center(
                child: Text('Historial'),
              ),
              // SettingsFragment(),
            ],
          );
        }),
        floatingActionButton: _selectedFragment == 0 || _selectedFragment == 1
            ? FloatingActionButton(
                child: Icon(Icons.add_rounded),
                onPressed: () async {},
              )
            : null,
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
              label: 'Cola',
              icon: Icon(Icons.playlist_play_rounded),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Historial',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.settings_rounded),
            //   label: 'Ajustes',
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    switch (_selectedFragment) {
      case 0:
        return AppBarHome(
          key: ValueKey('queue_appbar'),
          visibleResumeAll: _visibleResumeAll,
        );
      case 1:
        return AppBarHistory(
          key: ValueKey('history_appbar'),
        );
      default:
        return null;
    }
  }

  void _activeTaskListen(List<DownloadTask> event) {
    if (event.length == 0 && _visibleResumeAll) {
      setState(() {
        _visibleResumeAll = false;
      });
    } else if (event.length > 0 && !_visibleResumeAll) {
      setState(() {
        _visibleResumeAll = true;
      });
    }
  }

  void _runningTaskListen(List<DownloadTask> event) {
    bool lastStatusIsPaused =
        DownloadPreferencesRepository().lastStatusIsPaused;
    if (event.length == 0 && !lastStatusIsPaused) {
      DownloadPreferencesRepository().lastStatusIsPaused = true;
    } else if (event.length > 0 && lastStatusIsPaused) {
      DownloadPreferencesRepository().lastStatusIsPaused = false;
    }
    print(DownloadPreferencesRepository().lastStatusIsPaused);
  }
}
