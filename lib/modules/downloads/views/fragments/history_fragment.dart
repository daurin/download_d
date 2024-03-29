import 'dart:async';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/services/download/singleton/download_file_service.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:intl/intl.dart';

class HistoryFragment extends StatefulWidget {
  HistoryFragment({Key key}) : super(key: key);

  @override
  _HistoryFragmentState createState() => _HistoryFragmentState();
}

class _HistoryFragmentState extends State<HistoryFragment> {
  List<DownloadTask> _downloadTask;
  int _lastOffset = 0;
  bool _isLoadingLoadTasks;
  bool _isFinishPagination = false;
  StreamSubscription<DownloadTask> _onCompleteTaskSubscription;

  GroupedItemScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _downloadTask = [];

    _scrollController=GroupedItemScrollController();

    _onCompleteTaskSubscription =
        DownloadFileService().onCompleteTaskStream.listen((event) async {
      await _loadHistory(startPagination: true);
      _scrollController.jumpTo(index: 0);
    });

    _loadHistory(startPagination: true);
  }

  @override
  void dispose() {
    _onCompleteTaskSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_downloadTask.length == 0) {
      return SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sin historial',
              style: TextStyle(
                fontSize: 21,
                color: Theme.of(context).hintColor,
              ),
            ),
            SizedBox(height: 5),
            Icon(
              Icons.history_rounded,
              size: 40,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: StickyGroupedListView<DownloadTask, String>(
        itemScrollController: _scrollController,
        padding: EdgeInsets.only(
          bottom: 100,
        ),
        elements: _downloadTask,
        groupBy: (DownloadTask element) =>
            DateFormat('yyyy-MM-dd').format(element.completedAt),
        floatingHeader: true,
        groupSeparatorBuilder: (DownloadTask element) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = DateTime(now.year, now.month, now.day - 1);
          final tomorrow = DateTime(now.year, now.month, now.day + 1);
          DateTime completedAt = DateTime(element.completedAt.year,
              element.completedAt.month, element.completedAt.day);
          String dateFormatted;
          if (completedAt == today)
            dateFormatted = 'Hoy';
          else if (completedAt == yesterday)
            dateFormatted = 'Ayer';
          else
            dateFormatted =
                DateFormat('yyyy-MM-dd', 'es').format(element.completedAt);
          return Container(
            child: ListTile(
              tileColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                dateFormatted,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          );
        },
        itemBuilder: (context, DownloadTask element) {
          return _buildItem(element);
        },
        itemComparator: (element1, element2) =>
            element1.completedAt.compareTo(element2.completedAt),
        order: StickyGroupedListOrder.DESC,
      ),
    );
  }

  Widget _buildItem(DownloadTask task) {
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
                'Limpiar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Icon(
                Icons.delete_forever_rounded,
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
        bool success =
            await DownloadFileService().deleteHistoryTask(task.idCustom);
        _downloadTask
            .removeWhere((element) => element.idCustom == task.idCustom);
        setState(() {});
        return success;
      },
      child: ListTile(
        title: Text(task.fileName),
        subtitle: Row(
          children: [
            Text(task.size.format()),
            Spacer(),
            if (Localizations.localeOf(context).toString() == 'es')
              Text(DateFormat.jm().format(task.completedAt))
            else
              Text(DateFormat.Hm().format(task.completedAt)),
          ],
        ),
        onTap: () async {
          OpenResult openResult = await OpenFile.open(task.path);
          print(openResult);
        },
      ),
    );
  }

  Future<void> _loadHistory({startPagination = false}) async {
    _isLoadingLoadTasks = true;
    if (startPagination) {
      _lastOffset = 0;
      _downloadTask.clear();
    }
    List<DownloadTask> downloads = await DownloadFileService().findTasks(
      offset: _lastOffset,
      limit: 10,
      statusAnd: [
        DownloadTaskStatus.complete,
      ],
    );
    if (downloads.length == 0) _isFinishPagination = true;
    _lastOffset += downloads.length;

    setState(() {
      _isLoadingLoadTasks = false;
      if (downloads.length > 0) _downloadTask.addAll(downloads);
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (!_isLoadingLoadTasks &&
          !_isFinishPagination &&
          notification.metrics.pixels >
              notification.metrics.maxScrollExtent - 100) {
        print('pagination!!!');
        _loadHistory();

        return true;
      }
    }
    return false;
  }
}
