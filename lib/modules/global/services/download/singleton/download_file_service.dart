import 'package:download_d/modules/global/services/download/models/data_size.dart';
import 'package:download_d/modules/global/services/download/models/download_task.dart';
import 'package:download_d/modules/global/services/download/models/download_task_status.dart';
import 'package:download_d/modules/global/services/download/models/download_task_type.dart';
import 'package:flutter/foundation.dart';
import '../download_preferences_repository.dart';
import '../download_service.dart';

class DownloadFileService {
  DownloadService _downloadService;

  static final DownloadFileService _instance =
      DownloadFileService._internal();
  factory DownloadFileService() {
    return _instance;
  }
  DownloadFileService._internal() {
    print(_downloadService);
    _downloadService = DownloadService();
  }

  DownloadTask activeTask(String idTask) => _downloadService.activeTask(idTask);

  Stream<List<DownloadTask>> get activeTaskCountStream =>
      _downloadService.activeTaskCountStream;

  List<DownloadTask> get activeTasks => _downloadService.activeTasks;

  Future<void> addTask({
    String id,
    @required String url,
    @required String saveDir,
    String fileName,
    Map<String, dynamic> headers,
    bool autoStart = false,
    int index,
    DataSize limitBandwidth,
    String displayName,
    Duration duration,
    String thumbnailUrl,
    Map<String,dynamic> metadata,
  }) {
    return _downloadService.addTask(
      id: id,
      url: url,
      saveDir: saveDir,
      fileName: fileName,
      headers: headers,
      autoStart: autoStart,
      index: index,
      limitBandwidth: limitBandwidth,
      displayName: displayName,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      metadata: metadata,
    );
  }

  Future<bool> cancel(
    String idTask, {
    bool deleteFile = true,
    bool clearHistory = true,
  }) {
    return _downloadService.cancel(
      idTask,
      clearHistory: clearHistory,
      deleteFile: deleteFile,
    );
  }

  Future<void> cancelAll({bool deleteFile = true, bool clearHistory = false}) {
    return _downloadService.cancelAll(
      deleteFile: deleteFile,
      clearHistory: clearHistory,
    );
  }

  Future<bool> deleteHistoryTask(String idTask) {
    return _downloadService.deleteHistoryTask(idTask);
  }

  Future<DownloadTask> findTask(String idTask) {
    return _downloadService.findTask(idTask);
  }

  Stream<DownloadTask> get onCompleteTaskStream =>
      _downloadService.onCompleteTaskStream;
  Stream<DownloadTask> get statusChangeTaskStream =>
      _downloadService.statusChangeTaskStream;

  Future<void> pause(String idTask, {bool resumeEnqueueTask = true}) {
    return _downloadService.pause(
      idTask,
      resumeEnqueueTask: resumeEnqueueTask,
    );
  }

  Future<void> pauseAll({bool resumeEnqueueTask = true}) {
    return _downloadService.pauseAll(resumeEnqueueTask: resumeEnqueueTask);
  }

  DownloadPreferencesRepository get preferences => _downloadService.preferences;

  Stream<DataSize> receibedStream(String idTask) {
    return _downloadService.receibedStream(idTask);
  }

  Future<bool> resume(String idTask) {
    return _downloadService.resume(idTask);
  }

  Future<void> resumeAll() {
    return _downloadService.resumeAll();
  }

  Future<void> resumeEnqueue() {
    return _downloadService.resumeEnqueue();
  }

  Future<void> retry(String idTask) {
    return _downloadService.retry(idTask);
  }

  Stream<DataSize> speedDownloadStream(String idTask) {
    return _downloadService.speedDownloadStream(idTask);
  }

  Future<void> init({bool resume = true}) {
    return _downloadService.start(
      id: 'downloads_media',
      resume: resume,
    );
  }

  Stream<List<DownloadTask>> get statusStream => _downloadService.statusStream;

  Stream<DownloadTaskStatus> statusTaskStream(String idTask) {
    return _downloadService.statusTaskStream(idTask);
  }

  Future<void> stop() {
    return _downloadService.stop();
  }

  Future<List<DownloadTask>> findTasks({
    List<DownloadTaskStatus> statusAnd,
    int offset = 0,
    int limit,
    DownloadTaskType type,
  }) {
    return _downloadService.findTasks(
      statusAnd: statusAnd,
      offset: offset,
      limit: limit,
      type: type,
    );
  }
}