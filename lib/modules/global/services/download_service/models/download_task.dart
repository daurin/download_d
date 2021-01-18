import 'dart:convert';
import 'package:intl/intl.dart';

import '../download_task_repository.dart';
import 'download_task_status.dart';

class DownloadTask {
  final int id;
  final String idCustom;
  final String url;
  final DownloadTaskStatus status;
  final int progress;
  final Map<String, dynamic> headers;
  final String saveDir;
  final String fileName;
  final int size;
  final bool resumable;
  final String displayName;
  final bool showNotification;
  final String mimeType;
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
    this.saveDir,
    this.fileName,
    this.size,
    this.resumable,
    this.displayName,
    this.showNotification,
    this.mimeType,
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
      saveDir: map['save_dir'],
      fileName: map['file_name'],
      size: map['size'],
      resumable: map['resumable'] == 1,
      displayName: map['display_name'],
      showNotification: map['show_notification'] == 1,
      mimeType: map['mime_type'],
      index: map['index'],
      createdAt: map['created_at'] == null
          ? null
          : DateFormat(DownloadTaskRepository.dataFormat)
              .parse(map['created_at']),
      completedAt: map['completed_at'] == null
          ? null
          : DateFormat(DownloadTaskRepository.dataFormat)
              .parse(map['completed_at']),
    );
  }

  DownloadTask copyWith({
   int id,
   String idCustom,
   String url,
   DownloadTaskStatus status,
   int progress,
   Map<String, dynamic> headers,
   String saveDir,
   String fileName,
   int size,
   bool resumable,
   String displayName,
   bool showNotification,
   String mimeType,
   int index,
   DateTime createdAt,
   DateTime completedAt,
  }){
    return DownloadTask(
      id: id ?? this.id,
      idCustom: idCustom ?? this.idCustom,
      url : url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      headers: headers ?? this.headers,
      saveDir: saveDir ?? this.saveDir,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      resumable: resumable ?? this.resumable,
      displayName: displayName ?? this.displayName,
      showNotification: showNotification ?? this.showNotification,
      mimeType: mimeType ?? this.mimeType,
      index: index ?? this.index,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get path=> saveDir+'/'+fileName;
}
