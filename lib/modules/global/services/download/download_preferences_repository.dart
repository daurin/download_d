import 'package:download_d/modules/global/repositories/local_storage.dart';

class DownloadPreferencesRepository {
  String key='key';

  DownloadPreferencesRepository({this.key=''});

  set downloadPath(String value) =>
      LocalStorage().setItem('default_path$key', value);
  String get downloadPath =>
      LocalStorage().getItem('default_path$key') ?? null;

  set simultaneousDownloads(int value) =>
      LocalStorage().setItem('simultaneous_downloads$key', value);
  int get simultaneousDownloads =>
      LocalStorage().getItem('simultaneous_downloads$key') ?? 1;

  set rateLimit(int value) => LocalStorage().setItem('rate_limit$key', value);
  int get rateLimit => LocalStorage().getItem('rate_limit$key') ?? 0;

  set keepBackground(bool value) =>
      LocalStorage().setItem('keep_background$key', value);
  bool get keepBackground => LocalStorage().getItem('keep_background$key') ?? true;

  set lastStatusIsPaused(bool value) =>
      LocalStorage().setItem('last_status_is_paused$key', value);
  bool get lastStatusIsPaused =>
      LocalStorage().getItem('last_status_is_paused$key') ?? true;

  // #region Auto restart
  set restart(bool value) => LocalStorage().setItem('restart$key', value);
  bool get restart => LocalStorage().getItem('restart$key') ?? false;

  set restartCount(int value) => LocalStorage().setItem('restart_count$key', value);
  int get restartCount => LocalStorage().getItem('restart_count$key') ?? 0;

  set restartInterval(int value) =>
      LocalStorage().setItem('restart_interval$key', value);
  int get restartInterval => LocalStorage().getItem('restart_interval$key') ?? 5;
  // #endregion Auto restart

  // #region Notifications
  set enabledNotifications(bool value) =>
      LocalStorage().setItem('enabled_notifications$key', value);
  bool get enabledNotifications => LocalStorage().getItem('enabled_notifications$key') ?? true;

  set showProgressBarNotifications(bool value) =>
      LocalStorage().setItem('show_progressbar_notification$key', value);
  bool get showProgressBarNotifications =>
      LocalStorage().getItem('show_progressbar_notification$key') ?? true;

  set notifyOnFinished(bool value) =>
      LocalStorage().setItem('notify_on_Finished$key', value);
  bool get notifyOnFinished =>
      LocalStorage().getItem('notify_on_Finished$key') ?? true;
  // #endregion Notifications
}