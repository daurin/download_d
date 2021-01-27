import 'dart:async';

import 'package:download_d/modules/global/models/download_style_item.dart';
import 'package:download_d/modules/global/services/download/download_preferences_repository.dart';
import 'package:download_d/modules/global/services/download/download_service.dart';
import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/home/views/widgets/queue_tile_1.dart';
import 'package:download_d/modules/settings/blocs/pref_apparence_local_storage.dart';
import 'package:download_d/modules/settings/blocs/settings_display/settings_display_bloc.dart';
import 'package:download_d/modules/settings/blocs/settings_display/settings_display_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QueueFragment extends StatefulWidget {
  const QueueFragment({Key key}) : super(key: key);

  @override
  _QueueFragmentState createState() => _QueueFragmentState();
}

class _QueueFragmentState extends State<QueueFragment> {
  StreamSubscription<SettingsDisplayState> _settingsDisplaySubscription;

  PrefApparenceLocalStorage _preffApparence;
  DownloadStyleItem _downloadItemStyle;

  @override
  void initState() {
    super.initState();
    _preffApparence = PrefApparenceLocalStorage();
    _downloadItemStyle = _preffApparence.downloadStyleItem;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {  
      _settingsDisplaySubscription =BlocProvider.of<SettingsDisplayBloc>(context).listen((state) {
        if(state.downloadStyleItem!=_downloadItemStyle){
          setState(() {
            _downloadItemStyle=state.downloadStyleItem;
          });
        }
      });
    });
  }


  @override
  void dispose() {
    super.dispose();
    _settingsDisplaySubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DownloadTask>>(
      key: ValueKey('stream-activetaskviews'),
      stream: DownloadService.activeTaskCountStream,
      initialData: DownloadService.activeTasks,
      builder:
          (BuildContext context, AsyncSnapshot<List<DownloadTask>> snapshot) {
        return ListView.builder(
          key: ValueKey('list-activetaskviews'),
          padding: EdgeInsets.only(
            bottom: 100,
          ),
          itemCount: snapshot.data?.length,
          itemBuilder: (context, index) {
            DownloadTask task = snapshot.data[index];
            return _buildItem(task, index);
          },
        );
      },
    );
  }

  Widget _buildItem(DownloadTask task, int index) {
    return StreamBuilder(
      key: ValueKey(task.idCustom + 'stream1'),
      stream: DownloadService.statusTaskStream(task.idCustom),
      initialData: DownloadService.activeTask(task.idCustom)?.status ??
          DownloadTaskStatus.failed,
      builder: (BuildContext context, AsyncSnapshot status) {
        return StreamBuilder<DataSize>(
          key: ValueKey(task.idCustom + 'stream2'),
          stream: DownloadService.speedDownloadStream(task.idCustom),
          initialData: DownloadService.activeTask(task.idCustom)?.speedDownload,
          builder:
              (BuildContext context, AsyncSnapshot<DataSize> speedDownload) {
            return StreamBuilder<DataSize>(
              key: ValueKey(task.idCustom + 'stream3'),
              stream: DownloadService.receibedStream(task.idCustom),
              initialData:
                  DownloadService.activeTask(task.idCustom)?.sizeDownloaded ??
                      DataSize.zero,
              builder:
                  (BuildContext context, AsyncSnapshot<DataSize> receibed) {
                return Dismissible(
                  key: ValueKey(task.idCustom),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).errorColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.clear_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // onDismissed: (direction){

                  // },
                  confirmDismiss: (direction) async {
                    bool success=await DownloadService.cancel(task.idCustom);
                    return success;
                  },
                  child: QueueTile1(
                    key: ValueKey(task.idCustom + 'item'),
                    title: task.displayName,
                    status: status?.data ?? DownloadTaskStatus.undefined,
                    size: task.size,
                    downlaoded: receibed?.data ?? task.sizeDownloaded,
                    speedDownload: speedDownload.data ?? DataSize.zero,
                    onTapLeading: (DownloadTaskStatus status) {
                      if (status == DownloadTaskStatus.running ||
                          status == DownloadTaskStatus.enqueued)
                        DownloadService.pause(task.idCustom);
                      else
                        DownloadService.resume(task.idCustom);
                    },
                    showLinearProgress:
                        _downloadItemStyle == DownloadStyleItem.linear,
                    showCircularProgress:
                        _downloadItemStyle == DownloadStyleItem.circular,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
