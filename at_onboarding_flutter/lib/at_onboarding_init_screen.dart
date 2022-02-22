import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_onboarding_flutter/services/onboarding_service.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_dimens.dart';
import 'package:at_sync_ui_flutter/at_sync_material.dart';
import 'package:flutter/material.dart';

import 'at_onboarding_config.dart';

enum AtOnboardingResult {
  success, //Authenticate success
  error, //Authenticate error
  notFound, //Done have
}

class AtOnboardingInitScreen extends StatefulWidget {
  final AtOnboardingConfig config;

  const AtOnboardingInitScreen({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  _AtOnboardingInitScreenState createState() => _AtOnboardingInitScreenState();
}

class _AtOnboardingInitScreenState extends State<AtOnboardingInitScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final OnboardingService _onboardingService =
        OnboardingService.getInstance();
    _onboardingService.setAtClientPreference = widget.config.atClientPreference;
    try {
      final result = await _onboardingService.onboard();
      debugPrint("AtOnboardingInitScreen: result - $result");
      Navigator.pop(context, AtOnboardingResult.success);
    } catch (e) {
      debugPrint("AtOnboardingInitScreen: error - $e");
      //Todo
      if (e == OnboardingStatus.ATSIGN_NOT_FOUND ||
          e == OnboardingStatus.PRIVATE_KEY_NOT_FOUND) {
        Navigator.pop(context, AtOnboardingResult.notFound);
      } else {
        Navigator.pop(context, AtOnboardingResult.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AtOnboardingDimens.paddingNormal),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AtSyncIndicator(),
            SizedBox(width: AtOnboardingDimens.paddingSmall),
            Text('Onboarding'),
          ],
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              BorderRadius.circular(AtOnboardingDimens.dialogBorderRadius),
        ),
      ),
    );
  }
}
