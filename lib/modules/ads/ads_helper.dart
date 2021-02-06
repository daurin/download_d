import 'package:firebase_admob/firebase_admob.dart';

abstract class AdsHelper {
  static const String appId = 'ca-app-pub-1297213060387384~4394981328';
  static MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    testDevices: [],
    keywords: ['files', 'videos', 'games', 'downloads', 'internet', 'web'],
  );
}
