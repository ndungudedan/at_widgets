import 'dart:convert';
import 'dart:io';

import 'package:at_onboarding_flutter/screens/atsign_list_screen.dart';
import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_dimens.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/at_onboarding_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/web_view_screen.dart';
import 'services/free_atsign_service.dart';
import 'utils/custom_textstyles.dart';
import 'widgets/custom_dialog.dart';

class AtOnboardingOTPScreen extends StatefulWidget {
  final String atSign;
  final String email;

  final Function({required String atSign, required String secret})?
      onGenerateSuccess;

  ///will hide webpage references.
  final bool hideReferences;

  const AtOnboardingOTPScreen({
    Key? key,
    required this.atSign,
    required this.email,
    required this.hideReferences,
    required this.onGenerateSuccess,
  }) : super(key: key);

  @override
  State<AtOnboardingOTPScreen> createState() => _AtOnboardingOTPScreenState();
}

class _AtOnboardingOTPScreenState extends State<AtOnboardingOTPScreen> {
  final TextEditingController _pinCodeController = TextEditingController();
  final FreeAtsignService _freeAtsignService = FreeAtsignService();

  bool isVerifing = false;

  String limitExceeded = 'limitExceeded';

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
          absorbing: isVerifing,
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
                  children: [
                    Flexible(
                      child: Text(
                        'Enter Verification Code',
                        style: SizeConfig().isTablet(context)
                            ? Theme.of(context).brightness == Brightness.dark
                                ? CustomTextStyles.fontR12secondary
                                : CustomTextStyles.fontR12primary
                            : Theme.of(context).brightness == Brightness.dark
                                ? CustomTextStyles.fontR14secondary
                                : CustomTextStyles.fontR14primary,
                      ),
                    ),
                    widget.hideReferences
                        ? const SizedBox()
                        : IconButton(
                            icon: Icon(
                              Icons.help,
                              color: ColorConstants.appColor,
                              size: 18.toFont,
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute<Widget>(
                                      builder: (BuildContext context) =>
                                          const WebViewScreen(
                                            title: Strings.faqTitle,
                                            url: Strings.faqUrl,
                                          )));
                            })
                  ],
                ),
                Text(
                  'A verification code has been sent to ${widget.email}',
                  style: Theme.of(context).brightness == Brightness.dark
                      ? CustomTextStyles.fontR14secondary
                      : CustomTextStyles.fontR14primary,
                ),
                PinCodeTextField(
                  controller: _pinCodeController,
                  animationType: AnimationType.none,
                  textCapitalization: TextCapitalization.characters,
                  appContext: context,
                  length: 4,
                  textStyle: Theme.of(context).brightness == Brightness.dark
                      ? CustomTextStyles.fontR16secondary
                      : CustomTextStyles.fontR16primary,
                  pinTheme: PinTheme(
                    selectedColor: Colors.black,
                    inactiveColor: Colors.grey[500],
                    activeColor: ColorConstants.appColor,
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 50,
                    fieldWidth: 45.toWidth,
                  ),
                  cursorHeight: 15.toFont,
                  cursorColor: Colors.grey,
                  // controller: _otpController,
                  keyboardType: TextInputType.text,
                  inputFormatters: <TextInputFormatter>[
                    UpperCaseInputFormatter(),
                  ],
                  onChanged: (String value) {},
                ),
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
                SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: SizeConfig().isTablet(context) ? 50.toHeight : null,
                    child: ElevatedButton(
                      onPressed: _onVerifyPressed,
                      child: Center(
                          child: Text(
                        'Verify & Login',
                        style:
                            TextStyle(color: Colors.white, fontSize: 15.toFont),
                      )),
                    )),
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

  void _onVerifyPressed() async {
    isVerifing = false;
    setState(() {});

    String? result = await validatePerson(
        widget.atSign, widget.email, _pinCodeController.text, context);

    isVerifing = false;
    setState(() {});
    if (result != null && result != limitExceeded) {
      List<String> params = result.split(':');
      Navigator.pop(context);
      widget.onGenerateSuccess?.call(atSign: params[0], secret: params[1]);
      // widget.onValidate!(
      //     params[0],
      //     params[1],
      //     false);
    }
  }

  Future<String?> validatePerson(
      String atsign, String email, String? otp, BuildContext context,
      {bool isConfirmation = false}) async {
    dynamic data;
    String? cramSecret;
    List<String> atsigns = <String>[];
    // String atsign;

    dynamic response = await _freeAtsignService
        .validatePerson(atsign, email, otp, confirmation: isConfirmation);
    if (response.statusCode == 200) {
      data = response.body;
      data = jsonDecode(data);
      //check for the atsign list and display them.
      if (data['data'] != null &&
          data['data'].length == 2 &&
          data['status'] != 'error') {
        dynamic responseData = data['data'];
        atsigns.addAll(List<String>.from(responseData['atsigns']));

        if (responseData['newAtsign'] == null) {
          Navigator.pop(context);
          //Todo
          // widget.onLimitExceed!(atsigns, responseData['message']);
          return limitExceeded;
        }
        //displays list of atsign along with newAtsign
        else {
          await Navigator.push(
              context,
              MaterialPageRoute<dynamic>(
                  builder: (_) => AtsignListScreen(
                        atsigns: atsigns,
                        newAtsign: responseData['newAtsign'],
                      ))).then((dynamic value) async {
            if (value == responseData['newAtsign']) {
              cramSecret = await validatePerson(value, email, otp, context,
                  isConfirmation: true);
              return cramSecret;
            } else {
              if (value != null) {
                Navigator.pop(context);
              }
              return null;
            }
          });
        }
      } else if (data['status'] != 'error') {
        cramSecret = data['cramkey'];
      } else {
        String? errorMessage = data['message'];
        await showErrorDialog(context, errorMessage);
      }
      // atsign = data['data']['atsign'];
    } else {
      data = response.body;
      data = jsonDecode(data);
      String? errorMessage = data['message'];
      await showErrorDialog(context, errorMessage);
    }
    return cramSecret;
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
}
