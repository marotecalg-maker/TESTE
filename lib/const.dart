import 'dart:ui';

import 'package:kioku/ads/src/multi_ads_factory.dart';

import 'config/app_config.dart' as config;

// `isInterShowed` has one definition, in lib/config/app_config.dart; the ad
// networks import this file, so surface it from here too.
export 'config/app_config.dart' show isInterShowed;

class Constants {
  /// Remote config endpoint. The single source of truth is
  /// `Constants.jsonConfigUrl` in lib/config/app_config.dart — it must be the
  /// direct-download form (uc?export=download), not the file/d/ view link,
  /// which returns an HTML page instead of the JSON body.
  static String get jsonConfigUrl => config.Constants.jsonConfigUrl;

  static Color mainColor = const Color(0xff33FD24);
}

late MultiAds gAds;

/// True once the splash has fetched the config and [gAds] finished
/// initialising. Read it before touching [gAds]: on an offline launch the
/// splash never gets that far and [gAds] stays unassigned.
bool gAdsReady = false;
