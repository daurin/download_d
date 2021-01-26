import 'package:download_d/modules/global/models/download_style_item.dart';
import 'package:download_d/modules/settings/blocs/pref_apparence_local_storage.dart';
import 'package:flutter/material.dart';

class SettingsDisplayState {
  final ThemeMode themeMode;
  final DownloadStyleItem downloadStyleItem;

  SettingsDisplayState({
    this.themeMode,
    this.downloadStyleItem,
  });

  static SettingsDisplayState get initialState {
    return SettingsDisplayState(
      themeMode: PrefApparenceLocalStorage().getThemeMode(),
      downloadStyleItem: PrefApparenceLocalStorage().downloadStyleItem,
    );
  }

  SettingsDisplayState copyWith({
    ThemeMode themeMode,
    DownloadStyleItem downloadStyleItem,
  }) {
    return SettingsDisplayState(
      themeMode: themeMode ?? this.themeMode,
      downloadStyleItem: downloadStyleItem ?? this.downloadStyleItem,
    );
  }
}
