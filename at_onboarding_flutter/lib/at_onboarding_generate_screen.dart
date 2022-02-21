import 'dart:convert';
import 'dart:io';

import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/web_view_screen.dart';
import 'services/free_atsign_service.dart';
import 'utils/custom_textstyles.dart';
import 'widgets/custom_dialog.dart';

class AtOnboardingGenerateScreen extends StatefulWidget {
  const AtOnboardingGenerateScreen({Key? key}) : super(key: key);

  @override
  State<AtOnboardingGenerateScreen> createState() =>
      _AtOnboardingGenerateScreenState();
}

class _AtOnboardingGenerateScreenState
    extends State<AtOnboardingGenerateScreen> {
  final TextEditingController _atsignController = TextEditingController();
  final FreeAtsignService _freeAtsignService = FreeAtsignService();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    double _dialogWidth = double.maxFinite;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _dialogWidth = 400;
    }

    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) stateSet) {
      return Stack(children: <Widget>[
        Opacity(
            opacity: loading ? 0.3 : 1,
            child: AbsorbPointer(
                absorbing: loading,
                child: AlertDialog(
                    title: Text(
                      'Setting up your account',
                      style: TextStyle(
                          color: ColorConstants.appColor, fontSize: 16.toFont),
                    ),
                    content: Column(
                      children: [
                        TextFormField(
                          enabled: false,
                          style: Theme.of(context).brightness == Brightness.dark
                              ? CustomTextStyles.fontR14secondary
                              : CustomTextStyles.fontR14primary,
                          validator: (String? value) {
                            if (value == null || value == '') {
                              return '@sign cannot be empty';
                            }
                            return null;
                          },
                          onChanged: (String value) {
                            stateSet(() {});
                          },
                          controller: _atsignController,
                          inputFormatters: <TextInputFormatter>[
                            LengthLimitingTextInputFormatter(80),
                            // This inputFormatter function will convert all the input to lowercase.
                            TextInputFormatter.withFunction(
                                (TextEditingValue oldValue,
                                    TextEditingValue newValue) {
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
                            hintText: Strings.atsignHintText,
                            prefixText: '@',
                            prefixStyle: TextStyle(
                                color: ColorConstants.appColor,
                                fontSize: 15.toFont),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: ColorConstants.appColor,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                'Free @sign',
                                style: SizeConfig().isTablet(context)
                                    ? Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? CustomTextStyles.fontR12secondary
                                        : CustomTextStyles.fontR12primary
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? CustomTextStyles.fontR14secondary
                                        : CustomTextStyles.fontR14primary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.help,
                                color: ColorConstants.appColor,
                                size: 18.toFont,
                              ),
                              onPressed: _showReferenceWebview,
                            )
                          ],
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: SizeConfig().isTablet(context)
                                ? 50.toHeight
                                : null,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.grey[800])),
                              // key: Key(''),
                              onPressed: () async {
                                loading = true;
                                stateSet(() {});
                                _atsignController.text =
                                    await getFreeAtsign(context) ?? '';
                                loading = false;
                                stateSet(() {});
                              },
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Center(
                                        child: Text(
                                      'Refresh',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.toFont),
                                    )),
                                    const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 30,
                                    )
                                  ]),
                            )),
                        SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: SizeConfig().isTablet(context)
                                ? 50.toHeight
                                : null,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      ColorConstants.appColor)),
                              onPressed: () async {
                                //Todo
                                // _emailController.text = '';
                                // stateSet(() {});
                              },
                              child: Center(
                                  child: Text(
                                'Pair',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15.toFont),
                              )),
                            )),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          //Todo
                          // widget.onClose!();
                        },
                        child: Text(
                          Strings.closeTitle,
                          style: TextStyle(
                              color: ColorConstants.appColor,
                              fontSize: 14.toFont),
                        ),
                      ),
                    ]))),
      ]);
    });
  }

  Future<String?> getFreeAtsign(BuildContext context) async {
    dynamic data;
    String? atsign;
    dynamic response = await _freeAtsignService.getFreeAtsigns();
    if (response.statusCode == 200) {
      data = response.body;
      data = jsonDecode(data);
      atsign = data['data']['atsign'];
    } else {
      data = response.body;
      data = jsonDecode(data);
      String? errorMessage = data['message'];
      await showErrorDialog(context, errorMessage);
    }
    return atsign;
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
}
