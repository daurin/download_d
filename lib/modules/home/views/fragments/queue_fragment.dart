import 'package:download_d/modules/global/services/download_service/models/download_task_status.dart';
import 'package:download_d/modules/home/views/widgets/queue_tile_1.dart';
import 'package:flutter/material.dart';

class QueueFragment extends StatelessWidget {
  const QueueFragment({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        QueueTile1(
          title: 'instalador de gpedit (1).zip',
          status: DownloadTaskStatus.running,
          size: 684864654,
          downlaoded: (684864654*0.4).toInt(),
          speedDownload: 6543,
        ),
      ],
    );
  }
}
