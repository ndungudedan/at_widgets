import 'dart:convert';
import 'dart:io';

import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_dimens.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/at_onboarding_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'at_onboarding_otp_screen.dart';
import 'screens/web_view_screen.dart';
import 'services/free_atsign_service.dart';
import 'widgets/custom_dialog.dart';

class AtOnboardingPairScreen extends StatefulWidget {
  final String atSign;

  ///will hide webpage references.
  final bool hideReferences;

  final Function({required String atSign, required String secret})?
      onGenerateSuccess;

  const AtOnboardingPairScreen({
    Key? key,
    required this.atSign,
    required this.hideReferences,
    required this.onGenerateSuccess,
  }) : super(key: key);

  @override
  State<AtOnboardingPairScreen> createState() => _AtOnboardingPairScreenState();
}

class _AtOnboardingPairScreenState extends State<AtOnboardingPairScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FreeAtsignService _freeAtsignService = FreeAtsignService();

  bool isParing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _dialogWidth = double.maxFinite;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _dialogWidth = 400;
    }

    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) stateSet) {
      return Stack(children: <Widget>[
        AbsorbPointer(
          absorbing: isParing,
          child: AlertDialog(
            title: Text(
              'Setting up your account',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: AtOnboardingDimens.fontLarge.toFont,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text('Enter your email',
                          style: TextStyle(
                              fontSize: AtOnboardingDimens.fontNormal)),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.help,
                        size: 18.toFont,
                      ),
                      onPressed: _showReferenceWebview,
                    )
                  ],
                ),
                TextFormField(
                  enabled: true,
                  // style: Theme.of(context).brightness == Brightness.dark
                  //     ? CustomTextStyles.fontR14secondary
                  //     : CustomTextStyles.fontR14primary,
                  validator: (String? value) {
                    if (value == null || value == '') {
                      return '@sign cannot be empty';
                    }
                    return null;
                  },
                  onChanged: (String value) {
                    stateSet(() {});
                  },
                  controller: _emailController,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(80),
                    // This inputFormatter function will convert all the input to lowercase.
                    TextInputFormatter.withFunction(
                        (TextEditingValue oldValue, TextEditingValue newValue) {
                      return newValue.copyWith(
                        text: newValue.text.toLowerCase(),
                        selection: newValue.selection,
                      );
                    })
                  ],
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    fillColor: Colors.blueAccent,
                    errorStyle: TextStyle(
                      fontSize: 12.toFont,
                    ),
                    prefixStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 15.toFont),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: ColorConstants.appColor,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AtOnboardingDimens.paddingSmall.toWidth),
                  ),
                ),
                SizedBox(
                  height: 10.toHeight,
                ),
                Text(
                  Strings.emailNote,
                  style: TextStyle(
                      fontSize: 13.toFont, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 10.toHeight,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: AtOnboardingPrimaryButton(
                    isLoading: isParing,
                    onPressed: _onSendCodePressed,
                    child: Center(
                      child: Text(
                        'Send Code',
                        style:
                            TextStyle(color: Colors.white, fontSize: 15.toFont),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              AtOnboardingSecondaryButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  Strings.cancelButton,
                  style: TextStyle(
                    fontSize: AtOnboardingDimens.fontNormal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ]);
    });
  }

  Future<CustomDialog?> showErrorDialog(
      BuildContext context, String? errorMessage) async {
    return showDialog<CustomDialog>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            context: context,
            isErrorDialog: true,
            showClose: true,
            message: errorMessage,
            onClose: () {},
          );
        });
  }

  void _showReferenceWebview() {
    Navigator.push(
        context,
        MaterialPageRoute<Widget>(
            builder: (BuildContext context) => const WebViewScreen(
                  title: Strings.faqTitle,
                  url: Strings.faqUrl,
                )));
  }

  void _onSendCodePressed() async {
    if (_emailController.text != '') {
      isParing = true;
      setState(() {});
      bool status = false;
      // if (!wrongEmail) {
      status =
          await registerPersona(widget.atSign, _emailController.text, context);
      // } else {
      //   status = await registerPersona(
      //       widget.atSign, _emailController.text, context,
      //       oldEmail: oldEmail);
      // }
      isParing = false;
      setState(() {});
      if (status) {
        _showOTPScreen();
      } else {
        //Todo:
      }
    }
  }

  Future<bool> registerPersona(
      String atsign, String email, BuildContext context,
      {String? oldEmail}) async {
    dynamic data;
    bool status = false;
    // String atsign;
    dynamic response = await _freeAtsignService.registerPerson(atsign, email,
        oldEmail: oldEmail);
    if (response.statusCode == 200) {
      data = response.body;
      data = jsonDecode(data);
      status = true;
      // atsign = data['data']['atsign'];
    } else {
      data = response.body;
      data = jsonDecode(data);
      String errorMessage = data['message'];
      if (errorMessage.contains('Invalid Email')) {
        oldEmail = email;
      }
      if (errorMessage.contains('maximum number of free @signs')) {
        await showlimitDialog(context);
      } else {
        await showErrorDialog(context, errorMessage);
      }
    }
    return status;
  }

  Future<AlertDialog?> showlimitDialog(BuildContext context) async {
    return showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.toFont,
                        letterSpacing: 0.5),
                    text:
                        'Oops! You already have the maximum number of free @signs. Please login to ',
                  ),
                  TextSpan(
                      text: 'https://my.atsign.com',
                      style: TextStyle(
                          fontSize: 16.toFont,
                          color: ColorConstants.appColor,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          String url = 'https://my.atsign.com';
                          if (!widget.hideReferences && await canLaunch(url)) {
                            await launch(url);
                          }
                        }),
                  TextSpan(
                    text: '  to select one of your existing @signs.',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.toFont,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(color: ColorConstants.appColor),
                  ))
            ],
          );
        });
  }

  void _showOTPScreen() async {
    final String atSign = widget.atSign;
    final String email = _emailController.text;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AtOnboardingOTPScreen(
        atSign: atSign,
        hideReferences: false,
        email: email,
        onGenerateSuccess: ({required String atSign, required String secret}) {
          Navigator.pop(context);
          widget.onGenerateSuccess?.call(atSign: atSign, secret: secret);
        },
      ),
    );
  }
}
