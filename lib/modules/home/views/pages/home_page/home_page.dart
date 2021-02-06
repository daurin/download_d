import 'dart:async';
import 'package:download_d/modules/ads/ads_banner_home.dart';
import 'package:download_d/modules/downloads/views/widgets/add_task_dialog/add_task_dialog.dart';
import 'package:download_d/modules/global/blocs/connectivty_cubit/connectivity_cubit.dart';
import 'package:download_d/modules/global/blocs/connectivty_cubit/connectivity_cubit_state.dart';
import 'package:download_d/modules/global/services/download/download_preferences_repository.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/services/download/singleton/download_file_service.dart';
import 'package:download_d/modules/downloads/views/fragments/history_fragment.dart';
import 'package:download_d/modules/home/views/fragments/queue_fragment.dart';
import 'package:download_d/modules/home/views/widgets/appbar_home.dart';
import 'package:download_d/modules/downloads/views/widgets/appbar_history.dart';
import 'package:download_d/modules/settings/blocs/settings_display/settings_display_bloc.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  StreamSubscription<ConnectivityCubitState> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _visibleResumeAll = false;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
        await BlocProvider.of<ConnectivityCubit>(context)
            .listenStatusConnection();
        _connectivitySubscription = BlocProvider.of<ConnectivityCubit>(context)
            .listen(_onConnectivityChanged);
        await DownloadFileService().init(
          resume: !DownloadPreferencesRepository().lastStatusIsPaused,
        );
        _runningTaskSubscription =
            DownloadFileService().statusStream.listen(_runningTaskListen);
        _activeTaskSubscription = DownloadFileService()
            .activeTaskCountStream
            ?.listen(_activeTaskListen);
        _visibleResumeAll = DownloadFileService().activeTasks.length > 0;

        _visibleResumeAll = false;
        _visibleResumeAll = DownloadFileService().activeTasks.length > 0;

        if (DownloadPreferencesRepository().downloadPath == null) {
          String downloadDir = await ExtStorage.getExternalStorageDirectory();
          downloadDir += '/' + ExtStorage.DIRECTORY_DOWNLOADS;
          DownloadPreferencesRepository().downloadPath = downloadDir;
        }
        setState(() {
          _isLoading = false;
        });

        await _showBannerHome();
      } catch (err) {
        print(err);
      }
    });

    _selectedFragment = 0;
  }

  @override
  void dispose() {
    _runningTaskSubscription?.cancel();
    _activeTaskSubscription?.cancel();
    _connectivitySubscription?.cancel();
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
              HistoryFragment(),
              // SettingsFragment(),
            ],
          );
        }),
        floatingActionButton: _selectedFragment == 0 || _selectedFragment == 1
            ? FloatingActionButton(
                child: Icon(Icons.add_rounded),
                onPressed: _onTapFloatingButton,
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

  void _onTapFloatingButton() {
    showDialog(
        context: context,
        builder: (context) {
          return AddTaskDialog();
        });
  }

  void _onConnectivityChanged(ConnectivityCubitState state) async {
    if (state.hasConnection &&
        (DownloadFileService()?.preferences?.restart ?? false)) {
      List<DownloadTask> failedConnectionTasks = DownloadFileService()
          .activeTasks
          .where((e) => e.status == DownloadTaskStatus.failedConexion)
          .toList();
      print(failedConnectionTasks);
      if (failedConnectionTasks.length > 0) {
        for (var item in failedConnectionTasks) {
          await DownloadFileService().resume(item.idCustom);
        }
      }
      // if(!DownloadFileService().preferences.lastStatusIsPaused){
      //   await DownloadFileService().resumeAll();
      // }
    }
  }

  Future<void> _showBannerHome() async {
    await BannerHome.show(listener: (event) {
      SettingsDisplayBloc settingsDisplayBloc =
          BlocProvider.of<SettingsDisplayBloc>(context);
      if (event == MobileAdEvent.impression) {
        settingsDisplayBloc.setPaddingApp(EdgeInsets.only(
          bottom: BannerHome.bannerHomePage.size.height.toDouble(),
        ));
      } else if (event == MobileAdEvent.failedToLoad) {
        settingsDisplayBloc.setPaddingApp(EdgeInsets.zero);
      }
      print("BannerAd event is $event");
    });
  }
}
