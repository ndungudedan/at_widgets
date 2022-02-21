import 'package:at_backupkey_flutter/utils/size_config.dart';
import 'package:at_onboarding_flutter/at_onboarding_reset_screen.dart';
import 'package:at_onboarding_flutter/at_onboarding_screen.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:flutter/material.dart';

import 'at_onboarding_config.dart';
import 'screens/onboarding_widget.dart';
import 'utils/app_constants.dart';

class AtOnboarding {
  static start({
    required BuildContext context,
    required AtOnboardingConfig config,
  }) async {
    ColorConstants.darkTheme = Theme.of(context).brightness == Brightness.dark;
    AppConstants.setApiKey(
        config.appAPIKey ?? (AppConstants.rootEnvironment.apikey ?? ''));
    AppConstants.rootDomain =
        config.domain ?? AppConstants.rootEnvironment.domain;
    SizeConfig().init(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AtOnboardingScreen(config: config),
    );
  }

  static reset({
    required BuildContext context,
    required AtOnboardingConfig config,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AtOnboardingResetScreen(config: config),
    );
  }
}
