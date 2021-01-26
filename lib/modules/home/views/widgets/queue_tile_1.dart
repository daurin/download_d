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
  final void Function() onTap;
  final void Function() onLongPress;
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
    this.onTap,
    this.onLongPress,
    this.onTapLeading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String sizeFormatted = size?.format() ?? '0';
    final String downloadedFormatted = downlaoded?.format() ?? '0';
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
    else if (status == DownloadTaskStatus.failedConexion)
      statusString = 'Error de conexion';
    else if (status == DownloadTaskStatus.enqueued)
      statusString = 'En cola';
    else if (status == DownloadTaskStatus.complete)
      statusString = 'Descargado';
    else
      statusString = '';
    int progress = 0;
    if (downlaoded != null && size != null)
      progress = ((downlaoded?.inBytes ?? 0) * 100) ~/ size?.inBytes ?? 0;

    List<Widget> subtitleItems = [
      // '$progress%',
      // '$downloadedFormatted/$sizeFormatted',
      // '$statusString'
    ];

    if (resumible) {
      subtitleItems.add(Text('$progress%'));
      subtitleItems.add(Text(' • '));
      subtitleItems.add(Text('$downloadedFormatted/$sizeFormatted'));
    }
    // subtitleItems.add('$statusString');
    subtitleItems.add(Text(' • '));
    if (status == DownloadTaskStatus.running)
      subtitleItems.add(Text('${speedDownload?.format()}/sec'));
    else {
      subtitleItems.add(Text(
        statusString,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: status == DownloadTaskStatus.failed ||
                  status == DownloadTaskStatus.failedConexion
              ? Theme.of(context).errorColor
              : null,
        ),
      ));
    }

    return InkWell(
      key: ValueKey(title),
      onTap: onTap,
      onLongPress: onLongPress,
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
                  value: progress * 0.01,
                  child: RawMaterialButton(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    fillColor: Theme.of(context).primaryColor,
                    shape: CircleBorder(),
                    child: Builder(builder: (context) {
                      if (status == DownloadTaskStatus.running ||
                          status == DownloadTaskStatus.enqueued)
                        return Icon(
                          Icons.pause,
                          key: key,
                          color: Theme.of(context).primaryIconTheme.color,
                        );
                      else
                        return Icon(
                          Icons.play_arrow_rounded,
                          key: key,
                          color: Theme.of(context).primaryIconTheme.color,
                        );
                    }),
                    onPressed: onTapLeading == null
                        ? null
                        : () => onTapLeading(status),
                  ),
                ),
              ),
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text('$progress% • $downloadedFormatted/$sizeFormatted • $statusString'),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                          color: Theme.of(context).textTheme.caption.color,
                        ),
                    overflow: TextOverflow.ellipsis,
                    // child: Text(
                    //   subtitleItems.join(' • '),
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    // child: ListView.builder(
                    //   itemCount: subtitleItems.length,
                    //   physics: NeverScrollableScrollPhysics(),
                    //   scrollDirection: Axis.horizontal,
                    //   itemBuilder: (context, index) {
                    //     return subtitleItems[index];
                    //   },
                    //   // separatorBuilder: (context, index) => Text(' • '),
                    // ),
                    child: Row(
                      children: subtitleItems.map((e) => e).toList(),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            if (resumible && showLinearProgress)
              Padding(
                key: ValueKey('linearProgressbar' + title),
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
