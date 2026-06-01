import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Gère les publicités AdMob (bannière + interstitiel).
///
/// ⚠️ Les identifiants ci-dessous sont les IDs de TEST officiels de Google.
/// Avant de publier, remplace-les par TES vrais identifiants AdMob
/// (et mets aussi ton App ID dans le manifest — voir setup.sh).
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const String bannerUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // test
  static const String interstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // test

  InterstitialAd? _interstitial;
  int _openCount = 0;

  /// Précharge un interstitiel (à appeler au démarrage).
  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Montre un interstitiel toutes les 3 ouvertures, puis exécute [onDone].
  /// Si aucune pub n'est prête, exécute directement [onDone].
  void maybeShowInterstitial(VoidCallback onDone) {
    _openCount++;
    final ad = _interstitial;
    if (ad != null && _openCount % 3 == 0) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          loadInterstitial();
          onDone();
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
          loadInterstitial();
          onDone();
        },
      );
      _interstitial = null;
      ad.show();
    } else {
      onDone();
    }
  }
}
