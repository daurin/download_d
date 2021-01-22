import 'package:download_d/modules/global/services/download/download_service.dart';
import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/home/views/widgets/queue_tile_1.dart';
import 'package:flutter/material.dart';

class QueueFragment extends StatelessWidget {
  const QueueFragment({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DownloadTask>>(
      stream: DownloadService.activeTaskStream,
      initialData: DownloadService.activeTasks,
      builder:
          (BuildContext context, AsyncSnapshot<List<DownloadTask>> snapshot) {
        return ListView.builder(
          itemCount: snapshot.data.length,
          itemBuilder: (context, index) {
            DownloadTask task = snapshot.data[index];
            return _itemBuilder(task);
          },
        );
      },
    );
  }

  Widget _itemBuilder(DownloadTask task) {
    return StreamBuilder(
      key: ValueKey(task.idCustom),
      stream: DownloadService.statusStream(task.idCustom),
      initialData: DownloadService.activeTask(task.idCustom).status,
      builder: (BuildContext context, AsyncSnapshot status) {
        return StreamBuilder<DataSize>(
          stream: DownloadService.speedDownloadStream(task.idCustom),
          builder:
              (BuildContext context, AsyncSnapshot<DataSize> speedDownload) {
            return StreamBuilder<DataSize>(
              stream: DownloadService.receibedStream(task.idCustom),
              initialData: DataSize.zero,
              builder:
                  (BuildContext context, AsyncSnapshot<DataSize> receibed) {
                return QueueTile1(
                  key: ValueKey(task.idCustom+'item'),
                  title: task.displayName,
                  status: status.data,
                  size: task.size,
                  downlaoded: receibed?.data ?? task.sizeDownloaded,
                  speedDownload: speedDownload.data ?? DataSize.zero,
                  onTapLeading: (DownloadTaskStatus status){
                    if(status==DownloadTaskStatus.running)DownloadService.pause(task.idCustom);
                    else DownloadService.resume(task.idCustom);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
