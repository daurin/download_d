import 'dart:async';
import 'package:async/async.dart';

import 'data_size.dart';
import 'download_task.dart';
import 'download_task_status.dart';

class ActiveDownload {
  final DownloadTask task;
  final StreamController<DataSize> receivedStreamController;
  final StreamController<DataSize> speedDownloadStreamController;
  final StreamController<DownloadTaskStatus> statusStreamController;
  final CancelableOperation<void> cancelableOperation;
  final bool changingStatus;

  ActiveDownload({
    this.task,
    this.receivedStreamController,
    this.statusStreamController,
    this.speedDownloadStreamController,
    this.cancelableOperation,
    this.changingStatus,
  });

  ActiveDownload copyWith({
    DownloadTask task,
    StreamController<DataSize> receivedStreamController,
    StreamController<DataSize> statusStreamController,
    StreamController<DataSize> speedDownloadStreamController,
    CancelableOperation<void> cancelableOperation,
    bool changingStatus,
  }) {
    return ActiveDownload(
      task: task ?? this.task,
      receivedStreamController: receivedStreamController  ?? this.receivedStreamController,
      statusStreamController: statusStreamController ?? this.statusStreamController,
      speedDownloadStreamController: speedDownloadStreamController ?? this.speedDownloadStreamController,
      cancelableOperation: cancelableOperation ?? this.cancelableOperation,
      changingStatus: changingStatus ?? this.changingStatus,
    );
  }
}
