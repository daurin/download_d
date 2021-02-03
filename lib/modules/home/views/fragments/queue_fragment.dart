import 'dart:async';
import 'package:download_d/modules/downloads/views/widgets/edit_task_dialog.dart';
import 'package:download_d/modules/global/models/download_style_item.dart';
import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/services/download/singleton/download_file_service.dart';
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
      _settingsDisplaySubscription =
          BlocProvider.of<SettingsDisplayBloc>(context).listen((state) {
        if (state.downloadStyleItem != _downloadItemStyle) {
          setState(() {
            _downloadItemStyle = state.downloadStyleItem;
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
      stream: DownloadFileService().activeTaskCountStream,
      initialData: DownloadFileService().activeTasks,
      builder:
          (BuildContext context, AsyncSnapshot<List<DownloadTask>> snapshot) {
        if (snapshot.data?.length == 0) {
          return SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No hay descargas',
                  style: TextStyle(
                    fontSize: 21,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                SizedBox(height: 5),
                Icon(
                  Icons.download_rounded,
                  size: 40,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          );
        }

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
      onDismissed: (direction) async {
        await DownloadFileService().cancel(task.idCustom);
      },
      confirmDismiss: (direction) async {
        return true;
      },
      child: StreamBuilder(
        key: ValueKey(task.idCustom + 'stream1'),
        stream: DownloadFileService().statusTaskStream(task.idCustom),
        initialData: DownloadFileService().activeTask(task.idCustom)?.status ??
            DownloadTaskStatus.failed,
        builder: (BuildContext context, AsyncSnapshot status) {
          return StreamBuilder<DataSize>(
            key: ValueKey(task.idCustom + 'stream2'),
            stream: DownloadFileService().speedDownloadStream(task.idCustom),
            initialData:
                DownloadFileService().activeTask(task.idCustom)?.speedDownload,
            builder:
                (BuildContext context, AsyncSnapshot<DataSize> speedDownload) {
              return StreamBuilder<DataSize>(
                key: ValueKey(task.idCustom + 'stream3'),
                stream: DownloadFileService().receibedStream(task.idCustom),
                initialData: DownloadFileService()
                        .activeTask(task.idCustom)
                        ?.sizeDownloaded ??
                    DataSize.zero,
                builder:
                    (BuildContext context, AsyncSnapshot<DataSize> receibed) {
                  return QueueTile1(
                    key: ValueKey(task.idCustom + 'item'),
                    title: task.displayName,
                    status: status?.data ?? DownloadTaskStatus.undefined,
                    size: task.size,
                    downlaoded: receibed?.data ?? task.sizeDownloaded,
                    speedDownload: speedDownload.data ?? DataSize.zero,
                    onTapLeading: (DownloadTaskStatus status) {
                      if (status == DownloadTaskStatus.running ||
                          status == DownloadTaskStatus.enqueued)
                        DownloadFileService().pause(task.idCustom);
                      else
                        DownloadFileService().resume(task.idCustom);
                    },
                    showLinearProgress:
                        _downloadItemStyle == DownloadStyleItem.linear,
                    showCircularProgress:
                        _downloadItemStyle == DownloadStyleItem.circular,
                    onTap: () async {
                      bool resume=false;
                      if(status?.data==DownloadTaskStatus.running){
                        resume=true;
                        await DownloadFileService().pause(task.idCustom);
                      }
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return EditTaskDialog(
                            idTask: task.idCustom,
                          );
                        },
                      );
                      if(resume)await DownloadFileService().resume(task.idCustom);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
