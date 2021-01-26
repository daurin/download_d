import 'package:download_d/modules/settings/blocs/settings_display/settings_display_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> getBlocProvider() {
  return [
    // Global providers
    BlocProvider<SettingsDisplayBloc>(
      create: (_) => SettingsDisplayBloc(),
    ),
  ];
}
