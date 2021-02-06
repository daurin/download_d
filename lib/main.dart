import 'package:download_d/app.dart';
import 'package:download_d/modules/global/repositories/local_storage.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'db/DB.dart';
import 'modules/ads/ads_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage().init();
  await DB.init();
  await FirebaseAdMob.instance.initialize(appId: AdsHelper.appId);
  runApp(App());
}
