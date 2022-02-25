import 'package:at_sync_ui_flutter/at_sync_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';

class AtOnboardingQRCodeResult {
  final String atSign;
  final String secret;

  AtOnboardingQRCodeResult({
    required this.atSign,
    required this.secret,
  });
}

class AtOnboardingQRCodeScreen extends StatefulWidget {
  const AtOnboardingQRCodeScreen({
    Key? key,
  }) : super(key: key);

  @override
  _AtOnboardingQRCodeScreenState createState() =>
      _AtOnboardingQRCodeScreenState();
}

class _AtOnboardingQRCodeScreenState extends State<AtOnboardingQRCodeScreen> {
  QrReaderViewController? _controller;

  @override
  void dispose() {
    super.dispose();
    _controller?.stopCamera();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan your QR!'),
          actions: const [
            Center(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: AtSyncIndicator(color: Colors.white),
            )),
          ],
        ),
        body: Center(
          child: QrReaderView(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            callback: (QrReaderViewController controller) {
              _controller = controller;
              _controller?.startCamera((String data, List<Offset> offsets) {
                onScan(data, offsets, context);
              });
            },
          ),
        ),
      ),
    );
  }

  Future<void> onScan(
      String data, List<Offset> offsets, BuildContext context) async {
    try {
      //Relate: https://github.com/atsign-foundation/at_widgets/issues/353
      //If added [await] will make an error because [stopCamera] invoke a channel method which don't have a return and waiting forever.
      //It's an issue in flutter_qr_reader package and no need [await] keyword
      _controller!.stopCamera();
      List<String> values = data.split(':');
      Navigator.pop(context,
          AtOnboardingQRCodeResult(atSign: values[0], secret: values[1]));
      // try again
      await _controller!.startCamera((String data, List<Offset> offsets) {
        onScan(data, offsets, context);
      });
    } catch (e) {
      print(e);
    }
  }
}
