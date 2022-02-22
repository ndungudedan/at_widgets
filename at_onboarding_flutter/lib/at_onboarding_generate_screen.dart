import 'dart:convert';
import 'dart:io';

import 'package:at_onboarding_flutter/at_onboarding_pair_screen.dart';
import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_dimens.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/at_onboarding_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/web_view_screen.dart';
import 'services/free_atsign_service.dart';
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

  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    _getFreeAtsign();
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
          absorbing: loading,
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
                TextFormField(
                  enabled: false,
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
                  controller: _atsignController,
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
                    hintText: Strings.atsignHintText,
                    prefixText: '@',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text('Free @sign',
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
                  child: AtOnboardingSecondaryButton(
                    onPressed: () async {
                      loading = true;
                      stateSet(() {});
                      _atsignController.text = await _getFreeAtsign() ?? '';
                      loading = false;
                      stateSet(() {});
                    },
                    isLoading: isGenerating,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Center(
                            child: Text(
                          'Refresh',
                          style: TextStyle(fontSize: 15.toFont),
                        )),
                        const Icon(
                          Icons.refresh,
                          size: 20,
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: SizeConfig().isTablet(context) ? 50.toHeight : null,
                    child: AtOnboardingPrimaryButton(
                      onPressed: _showPairScreen,
                      child: const Text(
                        'Pair',
                        style: TextStyle(
                          fontSize: AtOnboardingDimens.fontNormal,
                        ),
                      ),
                    )),
              ],
            ),
            actions: <Widget>[
              AtOnboardingSecondaryButton(
                onPressed: () {
                  Navigator.pop(context);
                  //Todo
                  // widget.onClose!();
                },
                child: const Text(
                  Strings.closeTitle,
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

  Future<String?> _getFreeAtsign() async {
    setState(() {
      isGenerating = true;
    });
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
      await showErrorDialog(errorMessage);
    }
    setState(() {
      isGenerating = false;
    });
    return atsign;
  }

  Future<CustomDialog?> showErrorDialog(String? errorMessage) async {
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

  void _showPairScreen() async {
    final String atSign = _atsignController.text;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          AtOnboardingPairScreen(atSign: atSign, hideReferences: false),
    );
  }
}
