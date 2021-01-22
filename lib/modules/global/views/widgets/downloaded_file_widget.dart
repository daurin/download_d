import 'package:download_d/modules/global/services/download/download_service.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:flutter/material.dart';

class DowloadedFileWidget extends StatefulWidget {
  final String idTask;
  final bool enabled;

  final Widget Function(
      BuildContext context, AsyncSnapshot<DownloadTask> snapshot,) builder;

  DowloadedFileWidget({
    Key key,
    @required this.idTask,
    this.enabled = true,
    this.builder,
  }) : super(key: key);

  @override
  _DowloadedFileWidgetState createState() => _DowloadedFileWidgetState();
}

class _DowloadedFileWidgetState extends State<DowloadedFileWidget> {
  AsyncSnapshot<DownloadTask> _snapshot;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _snapshot = AsyncSnapshot<DownloadTask>.waiting();
      _loadDownloadTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _snapshot);
  }

  void _loadDownloadTask() async {
    try {
      DownloadTask task = await DownloadService.findTask(widget.idTask);
      setState(() {
        if (task != null)
          _snapshot =
              AsyncSnapshot<DownloadTask>.withData(ConnectionState.done, task);
        else
          _snapshot = AsyncSnapshot<DownloadTask>.nothing();
      });
    } catch (err) {
      setState(() {
        _snapshot =
            AsyncSnapshot<DownloadTask>.withError(ConnectionState.done, err);
      });
    }
  }
}
