import 'package:download_d/modules/global/models/download_style_item.dart';
import 'package:download_d/modules/global/repositories/local_storage.dart';
import 'package:flutter/material.dart';

class PrefApparenceLocalStorage {
  // static final PrefTheme _instance = PrefTheme._internal();

  // PrefTheme._internal();

  // factory PrefTheme() {
  //   return _instance;
  // }

  static Map<ThemeMode, String> _themeModeToString = {
    ThemeMode.dark: 'dark',
    ThemeMode.light: 'light',
    ThemeMode.system: 'system',
  };

  static Map<String, ThemeMode> _stringToThemeMode = {
    'dark': ThemeMode.dark,
    'light': ThemeMode.light,
    'system': ThemeMode.system,
  };

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await LocalStorage().setItem('theme_mode', _themeModeToString[themeMode]);
  }

  ThemeMode getThemeMode() {
    String value = LocalStorage()
        .getItem(
          'theme_mode',
          defaultValue: _themeModeToString[ThemeMode.system],
        )
        .toString();
    return _stringToThemeMode[value];
  }


  set downloadStyleItem(DownloadStyleItem value) =>
      LocalStorage().setItem('download_style_item', value.value);
  DownloadStyleItem get downloadStyleItem{
    String valueString=LocalStorage().getItem('download_style_item');
    if(valueString==null)return DownloadStyleItem.linear;
    return DownloadStyleItem.from(valueString);
  }
}
