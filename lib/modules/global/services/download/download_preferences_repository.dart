import 'package:download_d/modules/global/models/download_style_item.dart';
import 'package:download_d/modules/global/repositories/local_storage.dart';

class DownloadPreferencesRepository {
  static final DownloadPreferencesRepository _instance =
      DownloadPreferencesRepository._internal();

  DownloadPreferencesRepository._internal();

  factory DownloadPreferencesRepository() {
    return _instance;
  }

  set downloadPath(String value) =>
      LocalStorage().setItem('default_path', value);
  String get downloadPath =>
      LocalStorage().getItem('default_path') ?? null;

  set simultaneousDownloads(int value) =>
      LocalStorage().setItem('simultaneous_downloads', value);
  int get simultaneousDownloads =>
      LocalStorage().getItem('simultaneous_downloads') ?? 1;

  set rateLimit(int value) => LocalStorage().setItem('rate_limit', value);
  int get rateLimit => LocalStorage().getItem('rate_limit') ?? 0;

  set keepBackground(bool value) =>
      LocalStorage().setItem('keep_background', value);
  bool get keepBackground => LocalStorage().getItem('keep_background') ?? true;

  set lastStatusIsPaused(bool value) =>
      LocalStorage().setItem('last_status_is_paused', value);
  bool get lastStatusIsPaused =>
      LocalStorage().getItem('last_status_is_paused') ?? true;

  // #region Auto restart
  set restart(bool value) => LocalStorage().setItem('restart', value);
  bool get restart => LocalStorage().getItem('restart') ?? false;

  set restartCount(int value) => LocalStorage().setItem('restart_count', value);
  int get restartCount => LocalStorage().getItem('restart_count') ?? 0;

  set restartInterval(int value) =>
      LocalStorage().setItem('restart_interval', value);
  int get restartInterval => LocalStorage().getItem('restart_interval') ?? 5;
  // #endregion Auto restart

  // #region Notifications
  set enabledNotifications(bool value) =>
      LocalStorage().setItem('enabled_notifications', value);
  bool get enabledNotifications => LocalStorage().getItem('enabled_notifications') ?? true;

  set showProgressBarNotifications(bool value) =>
      LocalStorage().setItem('show_progressbar_notification', value);
  bool get showProgressBarNotifications =>
      LocalStorage().getItem('show_progressbar_notification') ?? true;

  set notifyOnFinished(bool value) =>
      LocalStorage().setItem('notify_on_Finished', value);
  bool get notifyOnFinished =>
      LocalStorage().getItem('notify_on_Finished') ?? true;
  // #endregion Notifications
}
