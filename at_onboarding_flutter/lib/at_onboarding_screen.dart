import 'package:at_onboarding_flutter/at_onboarding_config.dart';
import 'package:flutter/material.dart';

class AtOnboardingScreen extends StatefulWidget {
  final AtOnboardingConfig config;

  const AtOnboardingScreen({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  State<AtOnboardingScreen> createState() => _AtOnboardingScreenState();
}

class _AtOnboardingScreenState extends State<AtOnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 100,),
      color: Colors.red,
    );
  }
}
