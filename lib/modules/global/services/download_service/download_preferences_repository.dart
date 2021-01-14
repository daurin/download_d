import 'package:download_d/modules/global/repositories/local_storage.dart';

class DownloadPreferencesRepository {
  static final DownloadPreferencesRepository _instance =
      DownloadPreferencesRepository._internal();

  DownloadPreferencesRepository._internal();

  factory DownloadPreferencesRepository() {
    return _instance;
  }

  set simultaneousDownloads(int value) =>
      LocalStorage().setItem('simultaneous_downloads', value);
  int get simultaneousDownloads =>
      LocalStorage().getItem('simultaneous_downloads') ?? 1;

  set rateLimit(int value) => LocalStorage().setItem('rate_limit', value);
  int get rateLimit => LocalStorage().getItem('rate_limit') ?? 0;

  set keepBackground(bool value) => LocalStorage().setItem('keep_background', value);
  bool get keepBackground => LocalStorage().getItem('keep_background') ?? true;

  // #region Auto restart
  set restart(bool value) => LocalStorage().setItem('restart', value);
  bool get restart => LocalStorage().getItem('restart') ?? false;

  set restartCount(int value) =>
      LocalStorage().setItem('restart_count', value);
  int get restartCount => LocalStorage().getItem('restart_count') ?? 0;

  set restartInterval(int value) =>
      LocalStorage().setItem('restart_interval', value);
  int get restartInterval =>
      LocalStorage().getItem('restart_interval') ?? 5;
  // #endregion Auto restart

  // #region Notifications
  set notifications(bool value) =>
      LocalStorage().setItem('notifications', value);
  bool get notifications => LocalStorage().getItem('notifications') ?? false;

  set notifyOnFinished(bool value) =>
      LocalStorage().setItem('notify_on_Finished', value);
  bool get notifyOnFinished => LocalStorage().getItem('notify_on_Finished') ?? false;
  // #endregion Notifications
}
