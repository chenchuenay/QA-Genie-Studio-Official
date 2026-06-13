import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/features/monetization/ads/ad_units.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdUnits.nativeSuites,
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: AppColors.surface,
        cornerRadius: 14.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: AppColors.accent,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('❌ Native Ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 90, // Match suite card height
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
