import 'package:download_d/modules/global/services/download/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/views/widgets/wrap_circular_progress_bar.dart';
import 'package:flutter/material.dart';

class QueueTile1 extends StatelessWidget {
  final String title;
  final int size;
  final int downlaoded;
  final DownloadTaskStatus status;
  final bool resumible;
  final int speedDownload;
  final bool showLinearProgress;
  final bool showCircularProgress;
  final void Function() onTapLeading;

  const QueueTile1({
    Key key,
    @required this.title,
    this.size = 0,
    this.downlaoded = 0,
    @required this.status,
    this.resumible = true,
    this.speedDownload,
    this.showLinearProgress = true,
    this.showCircularProgress = false,
    this.onTapLeading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String sizeFormatted = DataSize.formatBytes(size);
    final String downloadedFormatted = DataSize.formatBytes(downlaoded);
    // ignore: unused_local_variable
    String statusString;
    if (status == DownloadTaskStatus.canceled)
      statusString = 'Cancelado';
    else if (status == DownloadTaskStatus.paused)
      statusString = 'Pausado';
    else if (status == DownloadTaskStatus.running)
      statusString = 'Descargando';
    else if (status == DownloadTaskStatus.failed)
      statusString = 'Error';
    else if (status == DownloadTaskStatus.enqueued)
      statusString = 'En cola';
    else if (status == DownloadTaskStatus.complete)
      statusString = 'Descargado';
    else
      statusString = '';
    final int progress = (downlaoded * 100) ~/ size;

    List<String> subtitleItems = [
      // '$progress%',
      // '$downloadedFormatted/$sizeFormatted',
      // '$statusString'
    ];

    if (resumible) {
      subtitleItems.add('$progress%');
      subtitleItems.add('$downloadedFormatted/$sizeFormatted');
    }
    // subtitleItems.add('$statusString');
    subtitleItems.add('${DataSize.formatBytes(speedDownload)}/sec');

    return InkWell(
      onTap: () {},
      onLongPress: () {},
      child: Padding(
        padding: EdgeInsets.only(bottom: showLinearProgress ? 8 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                height: 45,
                width: 45,
                child: WrapCircularProgressBar(
                  enable: showCircularProgress,
                  value: progress*0.01,
                  child: RawMaterialButton(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    fillColor: Theme.of(context).primaryColor,
                    shape: CircleBorder(),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Theme.of(context).canvasColor,
                    ),
                    onPressed: onTapLeading,
                  ),
                ),
              ),
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text('$progress% • $downloadedFormatted/$sizeFormatted • $statusString'),
                  Text(
                    subtitleItems.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            if (resumible && showLinearProgress)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: LinearProgressIndicator(
                  value: progress * 0.01,
                ),
              ),
          ],
        ),
      ),
    );
  }

}
