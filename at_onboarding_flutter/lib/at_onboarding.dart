import 'package:at_backupkey_flutter/utils/size_config.dart';
import 'package:at_onboarding_flutter/at_onboarding_reset_screen.dart';
import 'package:at_onboarding_flutter/at_onboarding_screen.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:flutter/material.dart';

import 'at_onboarding_config.dart';
import 'at_onboarding_start_screen.dart';
import 'screens/onboarding_widget.dart';
import 'utils/app_constants.dart';

class AtOnboarding {
  static onboard({
    required BuildContext context,
    required AtOnboardingConfig config,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    ColorConstants.darkTheme = Theme.of(context).brightness == Brightness.dark;
    AppConstants.setApiKey(
        config.appAPIKey ?? (AppConstants.rootEnvironment.apikey ?? ''));
    AppConstants.rootDomain =
        config.domain ?? AppConstants.rootEnvironment.domain;
    SizeConfig().init(context);
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AtOnboardingStartScreen(config: config),
    );
    if (result is AtOnboardingResult) {
      switch (result) {
        case AtOnboardingResult.success:
          onSuccess?.call();
          break;
        case AtOnboardingResult.error:
          onError?.call();
          break;
        case AtOnboardingResult.notFound:
          start(context: context, config: config);
          break;
      }
    }
  }

  static start({
    required BuildContext context,
    required AtOnboardingConfig config,
    VoidCallback? onSuccess,
    VoidCallback? onError,
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
