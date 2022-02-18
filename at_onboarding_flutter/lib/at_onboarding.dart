import 'package:at_onboarding_flutter/at_onboarding_screen.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'at_onboarding_config.dart';
import 'screens/onboarding_widget.dart';
import 'utils/app_constants.dart';

class _AtOnboarding {
  static start({
    required BuildContext context,
    required AtOnboardingConfig config,
  }) async {
    ColorConstants.darkTheme = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      barrierDismissible: false,
      // builder: (_) => OnboardingWidget(
      //   atsign: config.atsign,
      //   onboard: config.onboard,
      //   onError: config.onError,
      //   hideReferences: config.hideReferences,
      //   hideQrScan: config.hideQrScan,
      //   nextScreen: config.nextScreen,
      //   fistTimeAuthNextScreen: config.fistTimeAuthNextScreen,
      //   atClientPreference: config.atClientPreference,
      //   appColor: config.appColor,
      //   logo: config.logo,
      //   domain: config.domain ?? AppConstants.rootEnvironment.domain,
      //   appAPIKey: config.appAPIKey ?? AppConstants.rootEnvironment.apikey!,
      // ),
      builder: (_) => AtOnboardingScreen(config: config),
    );
  }
}
