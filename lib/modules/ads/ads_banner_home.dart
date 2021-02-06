import 'package:download_d/modules/settings/blocs/settings_display/settings_display_bloc.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ads_helper.dart';

class BannerHome extends AdsHelper{

  static const String idBannerHomePage =
      'ca-app-pub-1297213060387384/3655656868';

  static BannerAd bannerHomePage;

  static Future<void> show({
    void Function(MobileAdEvent) listener,
  }) async {
    if (bannerHomePage == null) {
      bannerHomePage = BannerAd(
        adUnitId: idBannerHomePage,
        // adUnitId: BannerAd.testAdUnitId,
        size: AdSize.fullBanner,
        targetingInfo: AdsHelper.targetingInfo,
        listener: listener,
      );
      await bannerHomePage.load();
      await bannerHomePage.show(
        anchorType: AnchorType.bottom,
        anchorOffset: 0.0,
        horizontalCenterOffset: 0.0,
      );
    }
  }

  static void hide() async {
    await bannerHomePage?.dispose();
    bannerHomePage = null;
  }
}
