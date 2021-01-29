import 'dart:async';
import 'package:async/async.dart';
import 'data_size.dart';
import 'download_task.dart';
import 'download_task_status.dart';

class ActiveDownload {
  DownloadTask task;
  final StreamController<DataSize> receivedStreamController;
  final StreamController<DataSize> speedDownloadStreamController;
  final StreamController<DownloadTaskStatus> statusStreamController;
  final CancelableOperation<void> cancelableOperation;
  final bool changingStatus;
  final void Function(DownloadTask task) onEmitStatus;

  ActiveDownload({
    this.task,
    this.receivedStreamController,
    this.statusStreamController,
    this.speedDownloadStreamController,
    this.cancelableOperation,
    this.changingStatus,
    this.onEmitStatus,
  });

  ActiveDownload copyWith({
    DownloadTask task,
    StreamController<DataSize> receivedStreamController,
    StreamController<DataSize> speedDownloadStreamController,
    StreamController<DownloadTaskStatus> statusStreamController,
    CancelableOperation<void> cancelableOperation,
    bool changingStatus,
    void Function(DownloadTask task) onEmitStatus,
  }) {
    return ActiveDownload(
      task: task ?? this.task,
      receivedStreamController:
          receivedStreamController ?? this.receivedStreamController,
      statusStreamController:
          statusStreamController ?? this.statusStreamController,
      speedDownloadStreamController:
          speedDownloadStreamController ?? this.speedDownloadStreamController,
      cancelableOperation: cancelableOperation ?? this.cancelableOperation,
      changingStatus: changingStatus ?? this.changingStatus,
      onEmitStatus: onEmitStatus ?? this.onEmitStatus,
    );
  }

  void emitStatus(DownloadTaskStatus status) {
    this.task=task.copyWith(
      status: status,
    );
    if (onEmitStatus != null)
      onEmitStatus(this.task.copyWith(
            status: status,
          ));
  }
}