import 'dart:convert';

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

import 'at_onboarding_accounts_screen.dart';
import 'at_onboarding_reference_screen.dart';
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
  bool isResendingCode = false;

  String limitExceeded = 'limitExceeded';

  @override
  void dispose() {
    super.dispose();
    _pinCodeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isVerifing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setting up your account'),
          actions: [
            IconButton(
              onPressed: _showReferenceWebview,
              icon: const Icon(Icons.help),
            ),
          ],
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AtOnboardingDimens.borderRadius)),
            padding: const EdgeInsets.all(AtOnboardingDimens.paddingNormal),
            margin: const EdgeInsets.all(AtOnboardingDimens.paddingNormal),
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(
                    fontSize: AtOnboardingDimens.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 5.toHeight,
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
                Text(
                  'A verification code has been sent to ${widget.email}',
                  style:
                      const TextStyle(fontSize: AtOnboardingDimens.fontNormal),
                ),
                SizedBox(
                  height: 10.toHeight,
                ),
                AtOnboardingPrimaryButton(
                  height: 48,
                  borderRadius: 24,
                  width: double.infinity,
                  isLoading: isVerifing,
                  onPressed: _onVerifyPressed,
                  child: const Text('Verify & Login'),
                ),
                SizedBox(
                  height: 10.toHeight,
                ),
                AtOnboardingSecondaryButton(
                  height: 48,
                  borderRadius: 24,
                  width: double.infinity,
                  isLoading: isResendingCode,
                  onPressed: _onResendPressed,
                  child: const Text('Resend Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    AtOnboardingReferenceScreen.push(
      context: context,
      title: Strings.faqTitle,
      url: Strings.faqUrl,
    );
  }

  void _onVerifyPressed() async {
    isVerifing = true;
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

  void _onResendPressed() async {
    setState(() {
      isResendingCode = true;
    });
    // String atsign;
    dynamic response =
        await _freeAtsignService.registerPerson(widget.atSign, widget.email);
    if (response.statusCode == 200) {
      //Success
      final data = jsonDecode(response.body);
      _pinCodeController.text = '';
      // status = true;
      // atsign = data['data']['atsign'];
    } else {
      //Error
      final data = jsonDecode(response.body);
      String errorMessage = data['message'];
      // if (errorMessage.contains('Invalid Email')) {
      //   oldEmail = email;
      // }
      if (errorMessage.contains('maximum number of free @signs')) {
        await showlimitDialog(context);
      } else {
        await showErrorDialog(context, errorMessage);
      }
    }
    setState(() {
      isResendingCode = false;
    });
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
          final value = await _openAccountScreen(
            atsigns: atsigns,
            newAtsign: responseData['newAtsign'],
            email: email,
            otp: otp,
          );
          if (value == responseData['newAtsign']) {
            cramSecret = await validatePerson(
                value as String, email, otp, context,
                isConfirmation: true);
            return cramSecret;
          } else {
            if (value != null) {
              Navigator.pop(context);
            }
            return null;
          }
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

  Future<String?> _openAccountScreen({
    required List<String> atsigns,
    required String? newAtsign,
    required String email,
    required String? otp,
  }) async {
    await Navigator.push(
        context,
        MaterialPageRoute<dynamic>(
            builder: (_) => AtOnboardingAccountsScreen(
                  atsigns: atsigns,
                  newAtsign: newAtsign,
                ))).then((dynamic value) async {
      if (value == newAtsign) {
        final cramSecret = await validatePerson(value, email, otp, context,
            isConfirmation: true);
        return cramSecret;
      } else {
        if (value != null) {
          Navigator.pop(context);
        }
        return null;
      }
    });
    return null;
  }
}
