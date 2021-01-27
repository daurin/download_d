import 'package:download_d/app.dart';
import 'package:download_d/modules/global/repositories/local_storage.dart';
import 'package:flutter/material.dart';
import 'db/DB.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage().init();
  await DB.init();
  runApp(App());
}
