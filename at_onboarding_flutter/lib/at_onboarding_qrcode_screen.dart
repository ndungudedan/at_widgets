import 'dart:io';

import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/at_onboarding_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';

import 'utils/at_onboarding_dimens.dart';

class AtOnboardingQRCodeScreen extends StatefulWidget {
  const AtOnboardingQRCodeScreen({Key? key}) : super(key: key);

  @override
  _AtOnboardingQRCodeScreenState createState() =>
      _AtOnboardingQRCodeScreenState();
}

class _AtOnboardingQRCodeScreenState extends State<AtOnboardingQRCodeScreen> {
  late QrReaderViewController _controller;

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
          absorbing: false,
          child: AlertDialog(
            title: Text(
              'Scan your QR!',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: AtOnboardingDimens.fontLarge.toFont,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 320.0,
                  height: 320.0,
                  child: QrReaderView(
                    width: 300.0,
                    height: 300.0,
                    callback: (QrReaderViewController controller) {
                      _controller = controller;
                      _controller
                          .startCamera((String data, List<Offset> offsets) {
                        onScan(data, offsets, context);
                      });
                    },
                  ),
                ),
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

  Future<void> onScan(
      String data, List<Offset> offsets, BuildContext context) async {
    await _controller.stopCamera();
    dynamic message;
    // if (_isCram(data)) {
    //   List<String> params = data.split(':');
    //   if (params[1].length < 128) {
    //     await _showAlertDialog(CustomStrings().invalidCram(params[0]));
    //   } else if (OnboardingService.getInstance().formatAtSign(params[0]) !=
    //       _pairingAtsign &&
    //       _pairingAtsign != null) {
    //     await _showAlertDialog(CustomStrings().atsignMismatch(_pairingAtsign));
    //   } else if (params[1].length == 128) {
    //     message = await _processSharedSecret(params[0], params[1]);
    //   } else {
    //     await _showAlertDialog(CustomStrings().invalidData);
    //   }
    // } else {
    //   await _showAlertDialog(CustomStrings().invalidData);
    // }
    // setState(() {
    //   loading = false;
    // });
    // if (message != ResponseStatus.authSuccess) {
    //   scanCompleted = false;
    //   await _controller.startCamera((String data, List<Offset> offsets) {
    //     if (!scanCompleted) {
    //       onScan(data, offsets, context);
    //       scanCompleted = true;
    //     }
    //   });
    // }
  }
}
