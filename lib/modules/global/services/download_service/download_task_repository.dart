import 'dart:convert';
import 'package:download_d/db/DB.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'models/download_task.dart';
import 'models/download_task_status.dart';

class DownloadTaskRepository {
  static final DownloadTaskRepository _singleton =
      DownloadTaskRepository._internal();

  factory DownloadTaskRepository() {
    return _singleton;
  }

  static const String tableName = 'DOWNLOAD_TASK';
  static const String dataFormat = 'yyyy-MM-dd-hh:mm:ss.mmmuuu';

  DownloadTaskRepository._internal();

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
    @required int size,
    bool resumable = false,
    String displayName,
    bool showNotification=true,
    @required String mimeType,
    int index,
    DateTime completedAt,
  }) async {
    final db = DB.db;

    return db.insert(
      tableName,
      {
        'id_custom': idCustom,
        'url': url,
        'status': status.value,
        'progress': progress,
        'headers': jsonEncode(headers),
        'save_dir': saveDir,
        'file_name': fileName,
        'size': size,
        'resumable': resumable ? 1 : 0,
        'display_name': displayName ?? fileName,
        'show_notification' : showNotification ? 1 : 0,
        'mime_type': mimeType,
        'index': index,
        'created_at': DateFormat(dataFormat).format(DateTime.now()).toString(),
        'completed_at': completedAt != null
            ? DateFormat(dataFormat).format(completedAt).toString()
            : null,
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
    int size,
    bool resumable,
    String displayName,
    bool showNotification,
    String mimeType,
    List<String> fieldsIgnoreNull,
    Map<String, dynamic> whereEquals,
    Map<String, dynamic> whereDistinct,
    int index,
    bool canResume,
    DateTime completedAt,
  }) async {
    final db = DB.db;

    String where='';

    Map<String, dynamic> values = {};
    fieldsIgnoreNull = fieldsIgnoreNull ?? [];

    if (idCustom != null) values.addAll({'id_custom': url});
    if (url != null) values.addAll({'url': url});
    if (status != null) values.addAll({'status': status.value});
    if (progress != null) values.addAll({'progress': progress});
    if (headers != null) values.addAll({'headers': jsonEncode(headers)});
    if (saveDir != null) values.addAll({'save_dir': saveDir});
    if (fileName != null) values.addAll({'file_name': fileName});
    if (size != null) values.addAll({'size': size});
    if (resumable != null) values.addAll({'resumable': resumable ? 1 : 0});
    if (displayName != null) values.addAll({'display_name': displayName});
    if (showNotification != null) values.addAll({'show_notification': showNotification ? 1 : 0});
    if (mimeType != null) values.addAll({'type': mimeType});
    if (status != null) values.addAll({'status': status.value});
    if (index != null) values.addAll({'index': index});
    if (completedAt != null)
      values.addAll({
        'completed_at': DateFormat(dataFormat).format(completedAt).toString()
      });

      where =(whereEquals ?? {}).length == 0
            ? ''
            : whereEquals.entries
                .map<String>((MapEntry item) => '${item.key} = ?')
                .toList()
                .join(', ');

    where+=(whereDistinct ?? {}).length == 0
            ? ''
            : whereDistinct.entries
                .map<String>((MapEntry item) => '${item.key} != ?')
                .toList()
                .join(', ');


    print(where);

    int id = await db.update(tableName, values,
        where: where,
        whereArgs: whereEquals.length == 0
            ? null
            : whereEquals.entries
                .map<dynamic>((MapEntry item) => item.value)
                .toList());
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
    int limit = 10,
    DateTime createdAtGt,
  }) async {
    final db = DB.db;
    String query = '';
    List<String> where = [];
    if (createdAtGt != null)
      query = "SELECT * FROM `$tableName` " +
          "${where.length == 0 ? '' : 'WHERE'} ${where.join(' AND ')} " +
          "ORDER created_at DESC LIMIT $limit OFFSET $offset;";

    print(query);

    List<Map<String, dynamic>> res = await db.rawQuery(query);
    print(res);
    List<DownloadTask> rooms = res
        .map((item) => DownloadTask.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    return rooms;
  }

  Future<DownloadTask> findById(int id) {
    return _findByField({'id': id});
  }

  Future<DownloadTask> findByIdCustom(String idCustom) {
    return _findByField({'id_custom': idCustom});
  }

  Future<DownloadTask> _findByField(Map<String, dynamic> fields) async {
    final db = DB.db;
    List<Map<String, dynamic>> res = await db.query(tableName,
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
    final db = DB.db;
    List<MapEntry<String, dynamic>> where = fields.entries.map((e) {
      return e;
    }).toList();

    int affected = await db.delete(tableName,
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
