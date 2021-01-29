import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqlite_api.dart';
import 'models/data_size.dart';
import 'models/download_task.dart';
import 'models/download_task_status.dart';
import 'models/download_task_type.dart';

class DownloadTaskRepository {
  Database _db;

  DownloadTaskRepository(Database db){
    this._db=db;
  }

  static const String tableName = 'DOWNLOAD_TASK';
  static const String dataFormat = 'yyyy-MM-dd-hh:mm:ss.mmmuuu';

  // "url" TEXT NOT NULL,
  //   "status" INTEGER NOT NULL,
  //   "progress" INTEGER NOT NULL,
  //   "headers" TEXT NOT NULL,
  //   "save_path" TEXT NOT NULL,
  //   "size" INTEGER NOT NULL,
  //   "size_saved" INTEGER NULL,
  //   "display_name" TEXT NOT NULL,
  //   "file_type" TEXT NOT NULL,
  //   "created_at" NUMERIC NOT NULL

  Future<int> add({
    @required String idCustom,
    @required String url,
    DownloadTaskStatus status = DownloadTaskStatus.enqueued,
    int progress = 0,
    Map<String, dynamic> headers,
    @required String saveDir,
    @required String fileName,
    @required DataSize size,
    bool resumable = false,
    String displayName,
    bool showNotification = true,
    @required String mimeType,
    int index,
    DataSize limitBandwidth,
    DateTime completedAt,
    Duration duration,
    String thumbnailUrl,
    Map<String,dynamic> metadata,
  }) async {
    

    return _db.insert(
      tableName,
      {
        'id_custom': idCustom,
        'url': url,
        'status': status.value,
        'progress': progress,
        'headers': jsonEncode(headers),
        'save_dir': saveDir,
        'file_name': fileName,
        'size': size.inBytes,
        'resumable': resumable ? 1 : 0,
        'display_name': displayName ?? fileName,
        'show_notification': showNotification ? 1 : 0,
        'mime_type': mimeType,
        'index': index,
        'limit_bandwidth': limitBandwidth?.inBytes ?? null,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'completed_at':
            completedAt != null ? completedAt.millisecondsSinceEpoch : null,
        'duration': duration != null ? duration.inMilliseconds : null,
        'thumbnail_url': thumbnailUrl,
        'metadata' : metadata != null ? jsonEncode(metadata) : null,
      },
    );
  }

  Future<int> update({
    String url,
    String idCustom,
    DownloadTaskStatus status,
    int progress,
    Map<String, dynamic> headers,
    String saveDir,
    String fileName,
    DataSize size,
    bool resumable,
    String displayName,
    bool showNotification,
    String mimeType,
    List<String> fieldsIgnoreNull,
    int index,
    DataSize limitBandwidth,
    bool canResume,
    DateTime completedAt,
    Duration duration,
    String thumbnailUrl,
    Map<String, dynamic> metadata,
    Map<String, dynamic> whereEquals,
    Map<String, dynamic> whereDistinct,
  }) async {
    

    String where = '';
    List<String> whereAndFields = [];
    List<dynamic> whereValues = [];

    Map<String, dynamic> values = {};
    fieldsIgnoreNull = fieldsIgnoreNull ?? [];

    if (idCustom != null) values.addAll({'id_custom': url});
    if (url != null) values.addAll({'url': url});
    if (progress != null) values.addAll({'progress': progress});
    if (headers != null) values.addAll({'headers': jsonEncode(headers)});
    if (saveDir != null) values.addAll({'save_dir': saveDir});
    if (fileName != null) values.addAll({'file_name': fileName});
    if (size != null) values.addAll({'size': size.inBytes});
    if (resumable != null) values.addAll({'resumable': resumable ? 1 : 0});
    if (displayName != null) values.addAll({'display_name': displayName});
    if (showNotification != null)
      values.addAll({'show_notification': showNotification ? 1 : 0});
    if (mimeType != null) values.addAll({'type': mimeType});
    if (status != null) values.addAll({'status': status.value});
    if (index != null) values.addAll({'index': index});
    if (limitBandwidth != null)
      values.addAll({'limit_bandwidth': limitBandwidth?.inBytes ?? null});
    if (completedAt != null)
      values.addAll({
        'completed_at': completedAt.millisecondsSinceEpoch,
      });
    if (duration != null) values.addAll({'duration': duration.inMilliseconds});
    if (thumbnailUrl != null) values.addAll({'thumbnail_url': thumbnailUrl});
    if (metadata != null) values.addAll({'metadata': jsonEncode(metadata)});

    where = (whereEquals ?? {}).length == 0
        ? ''
        : whereEquals.entries
            .map<String>((MapEntry item) => '${item.key} = ?')
            .toList()
            .join(', ');

    where += ' ';

    // where += (whereDistinct ?? {}).length == 0
    //     ? ''
    //     : whereDistinct.entries
    //         .map<String>((MapEntry item) => '${item.key} != ?')
    //         .toList()
    //         .join(', ');

    // if ((whereEquals ?? {}).length > 0)
    //   whereAndArguments.addAll(whereEquals.entries
    //       .map<dynamic>((MapEntry item) => item.value)
    //       .toList());
    // if ((whereDistinct ?? {}).length > 0)
    //   whereAndArguments.addAll(whereDistinct.entries
    //       .map<dynamic>((MapEntry item) => item.value)
    //       .toList());

    if ((whereEquals ?? {}).length > 0) {
      whereAndFields.addAll(whereEquals.entries
          .map<String>((MapEntry item) => '${item.key} == ?')
          .toList());
      whereValues.addAll(whereEquals.entries
          .map<dynamic>((MapEntry item) => item.value)
          .toList());
    }

    if ((whereDistinct ?? {}).length > 0) {
      whereAndFields.addAll(whereDistinct.entries
          .map<String>((MapEntry item) => '${item.key} != ?')
          .toList());
      whereValues.addAll(whereDistinct.entries
          .map<dynamic>((MapEntry item) => item.value)
          .toList());
    }

    print(where);

    int id = await _db.update(
      tableName,
      values,
      where: whereAndFields.join(' AND '),
      whereArgs: whereValues,
    );
    return id;
  }

  Future<int> deleteById(id) async {
    return _deleteByField({
      'id': id,
    });
  }

  Future<int> deleteByCustomId(String idCustom) async {
    return _deleteByField({
      'id_custom': idCustom,
    });
  }

  Future<List<DownloadTask>> find({
    int offset = 0,
    int limit,
    List<DownloadTaskStatus> statusAnd,
    List<DownloadTaskStatus> statusOr,
    DateTime createdAtGt,
    DownloadTaskType type,
  }) async {
    
    String query = '';
    List<String> whereAnd = [];
    List<String> whereOr = [];
    if (type != null) {
      whereAnd.add("mime_type LIKE '%${type.value}%'");
    }
    if (statusAnd != null) {
      statusAnd.forEach((element) {
        whereAnd.add("status='${element.value}'");
      });
    }
    if (statusOr != null) {
      statusOr.forEach((element) {
        whereOr.add("status='${element.value}'");
      });
    }

    query = "SELECT * FROM `$tableName` ";
    if (whereAnd.length > 0) {
      if (!query.contains('WHERE')) query += 'WHERE ';
      query += "${whereAnd.join(' AND ')} ";
    }
    if (whereOr.length > 0) {
      if (!query.contains('WHERE')) query += 'WHERE ';
      query += "${whereOr.join(' OR ')} ";
    }
    query += "ORDER BY created_at DESC LIMIT ${limit ?? -1} OFFSET $offset;";

    List<Map<String, dynamic>> res = await _db.rawQuery(query);
    List<DownloadTask> task = res
        .map((item) => DownloadTask.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    return task;
  }

  Future<DownloadTask> findById(int id) {
    return _findByField({'id': id});
  }

  Future<DownloadTask> findByIdCustom(String idCustom) {
    return _findByField({'id_custom': idCustom});
  }

  Future<DownloadTask> _findByField(Map<String, dynamic> fields) async {
    
    List<Map<String, dynamic>> res = await _db.query(tableName,
        where: (fields ?? {}).length == 0
            ? null
            : fields.entries
                .map<String>((MapEntry item) => '${item.key} = ?')
                .toList()
                .join(', '),
        whereArgs: fields.length == 0
            ? null
            : fields.entries
                .map<dynamic>((MapEntry item) => item.value)
                .toList());
    List<DownloadTask> tasks = res
        .map((Map<String, dynamic> item) => DownloadTask.fromMap(item))
        .toList();
    if (tasks.length == 0) return null;
    return tasks[0];
  }

  Future<int> _deleteByField(Map<String, dynamic> fields) async {
    
    List<MapEntry<String, dynamic>> where = fields.entries.map((e) {
      return e;
    }).toList();

    int affected = await _db.delete(tableName,
        where: where.length == 0
            ? null
            : where
                .map<String>((MapEntry item) => '${item.key} = ?')
                .toList()
                .join(', '),
        whereArgs: where.length == 0
            ? null
            : where.map<dynamic>((MapEntry item) => item.value).toList());
    return affected;
  }
}