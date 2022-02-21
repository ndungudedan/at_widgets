import 'package:flutter/material.dart';

abstract class AtOnboardingButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? borderColor;
  final double? height;
  final double? width;
  final VoidCallback? onPressed;
  final Widget child;

  const AtOnboardingButton({
    Key? key,
    required this.backgroundColor,
    required this.borderColor,
    required this.height,
    required this.width,
    required this.onPressed,
    required this.child,
  }) : super(key: key);
}

class AtOnboardingPrimaryButton extends AtOnboardingButton {
  const AtOnboardingPrimaryButton({
    Key? key,
    Color? backgroundColor,
    Color? borderColor,
    double? height,
    double? width,
    VoidCallback? onPressed,
    required Widget child,
  }) : super(
          key: key,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          height: height,
          width: width,
          onPressed: onPressed,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return SizedBox(
      height: height,
      width: width,
      child: TextButton(
        onPressed: onPressed,
        child: Container(
          child: child,
        ),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                backgroundColor ?? themeData.primaryColor),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                        color: borderColor ?? themeData.primaryColor)))),
      ),
    );
  }
}

class AtOnboardingSecondaryButton extends AtOnboardingButton {
  const AtOnboardingSecondaryButton({
    Key? key,
    Color? backgroundColor,
    Color? borderColor,
    double? height,
    double? width,
    VoidCallback? onPressed,
    required Widget child,
  }) : super(
          key: key,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          height: height,
          width: width,
          onPressed: onPressed,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return SizedBox(
      height: height,
      width: width,
      child: TextButton(
        onPressed: onPressed,
        child: Container(
          child: child,
        ),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                backgroundColor ?? Colors.transparent),
            foregroundColor:
                MaterialStateProperty.all<Color>(themeData.primaryColor),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                        color: borderColor ?? themeData.primaryColor)))),
      ),
    );
  }
}
