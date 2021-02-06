import 'dart:io';

import 'package:download_d/modules/global/blocs/connectivty_cubit/connectivity_cubit.dart';
import 'package:download_d/modules/global/blocs/providers/bloc_providers.dart';
import 'package:download_d/modules/home/views/pages/home_page/home_page.dart';
import 'package:download_d/modules/settings/blocs/settings_display/settings_display_bloc.dart';
import 'package:download_d/modules/settings/blocs/settings_display/settings_display_state.dart';
import 'package:download_d/themes/dark_theme.dart';
import 'package:download_d/themes/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      print('detached');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getBlocProvider(),
      child: BlocBuilder<SettingsDisplayBloc, SettingsDisplayState>(
          builder: (context, state) {
        return MaterialApp(
          title: 'Flutter Demo',
          home: HomePage(),
          theme: lightTheme(context),
          darkTheme: darkTheme(context),
          themeMode: state.themeMode,
          // locale: Locale('es'),
          supportedLocales: [
            const Locale('en'),
            const Locale('es'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (context, widget) {
            return Container(
              color: Theme.of(context).canvasColor,
              padding: state.paddingApp,
              child: widget,
            );
          },
        );
      }),
    );
  }
}
