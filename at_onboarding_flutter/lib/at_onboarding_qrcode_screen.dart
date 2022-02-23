import 'dart:io';

import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/at_onboarding_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';

import 'utils/at_onboarding_dimens.dart';

class AtOnboardingQRCodeScreen extends StatefulWidget {
  final Function({required String atSign, required String secret})?
      onScanSuccess;

  const AtOnboardingQRCodeScreen({
    Key? key,
    this.onScanSuccess,
  }) : super(key: key);

  @override
  _AtOnboardingQRCodeScreenState createState() =>
      _AtOnboardingQRCodeScreenState();
}

class _AtOnboardingQRCodeScreenState extends State<AtOnboardingQRCodeScreen> {
  QrReaderViewController? _controller;

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
                          ?.startCamera((String data, List<Offset> offsets) {
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

  Future<void> onScan(
      String data, List<Offset> offsets, BuildContext context) async {
    try {
      //Relate: https://github.com/atsign-foundation/at_widgets/issues/353
      //If added [await] will make an error because [stopCamera] invoke a channel method which don't have a return and waiting forever.
      //It's an issue in flutter_qr_reader package and no need [await] keyword
      _controller!.stopCamera();
      List<String> values = data.split(':');
      Navigator.pop(context);
      await widget.onScanSuccess?.call(atSign: values[0], secret: values[1]);

      // try again
      await _controller!.startCamera((String data, List<Offset> offsets) {
        onScan(data, offsets, context);
      });
    } catch (e) {
      print(e);
    }
  }
}
