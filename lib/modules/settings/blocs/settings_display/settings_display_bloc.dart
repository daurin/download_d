import 'package:download_d/modules/global/models/download_style_item.dart';
import 'package:download_d/modules/settings/blocs/pref_apparence_local_storage.dart';
import 'package:download_d/modules/settings/blocs/settings_display/settings_display_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsDisplayBloc extends Cubit<SettingsDisplayState> {

  SettingsDisplayBloc() : super(SettingsDisplayState.initialState);

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await PrefApparenceLocalStorage().setThemeMode(themeMode);
    emit(state.copyWith(
      themeMode: themeMode,
    ));
  }

  void setDownloadStyleItem(DownloadStyleItem value) {
    PrefApparenceLocalStorage().downloadStyleItem =value;
    emit(state.copyWith(
      downloadStyleItem: value,
    ));
  }

  setPaddingApp(EdgeInsets padding){
    emit(state.copyWith(
      paddingApp: padding,
    ));
  }

}
