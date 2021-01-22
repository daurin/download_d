import 'dart:convert';
import 'package:intl/intl.dart';
import 'data_size.dart';
import '../download_task_repository.dart';
import 'download_task_status.dart';
import 'download_task_type.dart';

class DownloadTask {
  final int id;
  final String idCustom;
  final String url;
  final DownloadTaskStatus status;
  final int progress;
  final Map<String, dynamic> headers;
  final String saveDir;
  final String fileName;
  final DataSize size;
  final DataSize sizeDownloaded;
  final bool resumable;
  final String displayName;
  final bool showNotification;
  final String mimeType;
  final int index;
  final DataSize limitBandwidth;
  final DateTime createdAt;
  final DateTime completedAt;
  final Duration duration;
  final String thumbnailUrl;

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
    this.sizeDownloaded,
    this.resumable,
    this.displayName,
    this.showNotification,
    this.mimeType,
    this.index,
    this.limitBandwidth,
    this.createdAt,
    this.completedAt,
    this.duration,
    this.thumbnailUrl,
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
      size: map['size'] != null
          ? DataSize(bytes: int.parse(map['size'].toString()))
          : null,
      resumable: map['resumable'] == 1,
      displayName: map['display_name'],
      showNotification: map['show_notification'] == 1,
      mimeType: map['mime_type'],
      index: map['index'],
      limitBandwidth: map['limit_bandwidth'] != null
          ? DataSize(bytes: int.parse(map['limit_bandwidth'].toString()))
          : null,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(map['created_at'].toString())),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(map['completed_at'].toString())),
      duration: map['duration'] != null
          ? Duration(milliseconds: int.parse(map['duration'].toString()))
          : null,
      thumbnailUrl: map['thumbnail_url'],
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
    DataSize size,
    DataSize sizeDownloaded,
    bool resumable,
    String displayName,
    bool showNotification,
    String mimeType,
    int index,
    DataSize limitBandwidth,
    DateTime createdAt,
    DateTime completedAt,
    Duration duration,
    String thumbnailUrl,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      idCustom: idCustom ?? this.idCustom,
      url: url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      headers: headers ?? this.headers,
      saveDir: saveDir ?? this.saveDir,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      sizeDownloaded : sizeDownloaded ?? this.sizeDownloaded,
      resumable: resumable ?? this.resumable,
      displayName: displayName ?? this.displayName,
      showNotification: showNotification ?? this.showNotification,
      mimeType: mimeType ?? this.mimeType,
      index: index ?? this.index,
      limitBandwidth: limitBandwidth ?? this.limitBandwidth,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  String get path => saveDir + '/' + fileName;
  DownloadTaskType get type {
    if(mimeType.contains('image'))return DownloadTaskType.image;
    if(mimeType.contains('audio'))return DownloadTaskType.audio;
    if(mimeType.contains('video'))return DownloadTaskType.video;
    return null;
  }
}