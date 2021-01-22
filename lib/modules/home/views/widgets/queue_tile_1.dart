import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/views/widgets/wrap_circular_progress_bar.dart';
import 'package:flutter/material.dart';

class QueueTile1 extends StatelessWidget {
  final String title;
  final DataSize size;
  final DataSize downlaoded;
  final DownloadTaskStatus status;
  final bool resumible;
  final DataSize speedDownload;
  final bool showLinearProgress;
  final bool showCircularProgress;
  final void Function(DownloadTaskStatus status) onTapLeading;

  const QueueTile1({
    Key key,
    @required this.title,
    this.size,
    this.downlaoded,
    @required this.status,
    this.resumible = true,
    this.speedDownload,
    this.showLinearProgress = true,
    this.showCircularProgress = false,
    this.onTapLeading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String sizeFormatted = DataSize.formatBytes(size?.inBytes??0);
    final String downloadedFormatted = DataSize.formatBytes(downlaoded?.inBytes??0);
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
    int progress = 0;
    if(downlaoded!=null && size!=null)progress=((downlaoded?.inBytes??0) * 100) ~/ size?.inBytes??0;

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
    subtitleItems.add('${DataSize.formatBytes(speedDownload?.inBytes??0)}/sec');

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
                    child: Builder(
                      builder: (context) {
                        if(status==DownloadTaskStatus.running)return Icon(
                          Icons.pause,
                          color: Theme.of(context).canvasColor,
                        );
                        else return Icon(
                          Icons.play_arrow_rounded,
                          color: Theme.of(context).canvasColor,
                        );

                      }
                    ),
                    onPressed: ()=>onTapLeading(status),
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
