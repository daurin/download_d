import 'dart:convert';
import 'package:intl/intl.dart';

import '../download_task_repository.dart';
import 'download_task_status.dart';
import 'download_task_type.dart';

class DownloadTask {
  final int id;
  final int idCustom;
  final String url;
  final DownloadTaskStatus status;
  final int progress;
  final Map<String, dynamic> headers;
  final String path;
  final int size;
  final int sizeSaved;
  final String displayName;
  final DownloadTaskType type;
  final int index;
  final DateTime createdAt;
  final DateTime completedAt;

  DownloadTask({
    this.id,
    this.idCustom,
    this.url,
    this.status,
    this.progress,
    this.headers,
    this.path,
    this.size,
    this.sizeSaved,
    this.displayName,
    this.type,
    this.index,
    this.createdAt,
    this.completedAt,
  });

  static DownloadTask fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'],
      idCustom: map['id_custom'],
      url: map['url'],
      status: DownloadTaskStatus(map['status']),
      progress: map['progress'],
      headers: jsonDecode(map['headers']),
      path: map['path'],
      size: map['size'],
      sizeSaved: map['size_saved'],
      displayName: map['display_name'],
      type: DownloadTaskType(map['type']),
      index: map['index'],
      createdAt: DateFormat(DownloadTaskRepository.dataFormat).parse(map['created_at']),
      completedAt: DateFormat(DownloadTaskRepository.dataFormat).parse(map['completed_at'])
    );
  }
}
