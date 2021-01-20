import 'package:at_onboarding_flutter/services/onboarding_service.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/custom_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:at_onboarding_flutter/services/size_config.dart';

class CustomAppBar extends StatelessWidget with PreferredSizeWidget {
  final String title;
  final double elevation;
  final bool showBackButton;
  // final bool showLeadingIcon;
  // final Widget leadingButton;

  CustomAppBar({
    this.title,
    this.elevation = 0.0,
    this.showBackButton = false,
    // this.showLeadingIcon = false
  });
  @override
  Widget build(BuildContext context) {
    return AppBar(
        elevation: this.elevation,
        leading: this.showBackButton
            ? Icon(Icons.arrow_back)
            : OnboardingService.getInstance().logo,
        automaticallyImplyLeading: this.showBackButton,
        backgroundColor: ColorConstants.appColor,
        centerTitle: true,
        title: Text(this.title, style: CustomTextStyles.fontR16secondary));
  }

  @override
  Size get preferredSize => Size.fromHeight(70.toHeight);
}
