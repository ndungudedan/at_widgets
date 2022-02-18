import 'dart:io';

import 'package:at_backupkey_flutter/utils/color_constants.dart';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_onboarding_flutter/at_onboarding_config.dart';
import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/custom_textstyles.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/custom_appbar.dart';
import 'package:at_onboarding_flutter/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';
import 'package:permission_handler/permission_handler.dart';

class AtOnboardingScreen extends StatefulWidget {
  final AtOnboardingConfig config;
  /// If true, shows the custom dialog to get an atsign
  final bool getAtSign;
  const AtOnboardingScreen({
    Key? key,
    required this.config,
    this.getAtSign = false,
  }) : super(key: key);

  @override
  State<AtOnboardingScreen> createState() => _AtOnboardingScreenState();
}

class _AtOnboardingScreenState extends State<AtOnboardingScreen> {

  late QrReaderViewController _controller;

  final bool scanQR = false;

  bool _isBackup = false;
  bool loading = false;
  bool _isServerCheck = false;
  bool _isContinue = true;
  bool permissionGrated = false;

  String? _pairingAtsign;
  String? _loadingMessage;

  @override
  void initState() {
    checkPermissions();
    if (widget.getAtSign == true) {
      // _getAtsignForm();
    }
    // if (widget.onboardStatus != null) {
    //   if (widget.onboardStatus == OnboardingStatus.ACTIVATE) {
    //     _isQR = true;
    //     loading = true;
    //     _getLoginWithAtsignDialog(context);
    //   }
    //   if (widget.onboardStatus == OnboardingStatus.RESTORE) {
    //     _isBackup = true;
    //   }
    // }
    super.initState();
  }

  Future<void> checkPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      PermissionStatus cameraStatus = await Permission.camera.status;
      PermissionStatus storageStatus = await Permission.storage.status;
      widget.config.logger.info('camera status => $cameraStatus');
      widget.config.logger.info('storage status is $storageStatus');
      if (cameraStatus.isRestricted && storageStatus.isRestricted) {
        await askPermissions(Permission.unknown);
      } else if (cameraStatus.isRestricted || cameraStatus.isDenied) {
        await askPermissions(Permission.camera);
      } else if (storageStatus.isRestricted || storageStatus.isDenied) {
        await askPermissions(Permission.storage);
      } else if (cameraStatus.isGranted && storageStatus.isGranted) {
        setState(() {
          permissionGrated = true;
        });
      }
    } else {
      // bypassing for desktop platforms
      setState(() {
        permissionGrated = true;
      });
    }
  }

  Future<void> askPermissions(Permission type) async {
    if (type == Permission.camera) {
      await Permission.camera.request();
    } else if (type == Permission.storage) {
      await Permission.storage.request();
    } else {
      await <Permission>[Permission.camera, Permission.storage].request();
    }
    setState(() {
      permissionGrated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    if (scanQR) {
      return Scaffold(
        backgroundColor: ColorConstants.backgroundColor,
        appBar: CustomAppBar(
          showBackButton: true,
          title: Strings.pairAtsignTitle,
        ),
        body: QrReaderView(
          width: 300.0,
          height: 300.0,
          callback: (QrReaderViewController controller) {
            _controller = controller;
            _controller.startCamera((String data, List<Offset> offsets) {
              // onScan(data, offsets, context);
            });
          },
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.symmetric(
            vertical: 25.toHeight, horizontal: 24.toHeight),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_isBackup) ...<Widget>[
                  SizedBox(
                    height: SizeConfig().screenHeight * 0.25,
                  ),
                  RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          style: CustomTextStyles.fontR16primary,
                          children: <InlineSpan>[
                            TextSpan(
                                text: _pairingAtsign ?? ', ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const TextSpan(
                                text: Strings.backupKeyDescription)
                          ])),
                  SizedBox(
                    height: 25.toHeight,
                  ),
                  Center(
                    child: CustomButton(
                      width: 230.toWidth,
                      buttonText: Strings.uploadZipTitle,
                      // onPressed: (Platform.isMacOS ||
                      //     Platform.isLinux ||
                      //     Platform.isWindows)
                      //     ? _uploadKeyFileForDesktop
                      //     : _uploadKeyFile,
                    ),
                  ),
                  SizedBox(
                    height: 25.toHeight,
                  ),
                ]
              ],
            ),
            loading
                ? _isServerCheck
                ? Padding(
              padding: EdgeInsets.only(
                  top: SizeConfig().screenHeight * 0.30),
              child: Center(
                child: Container(
                  color: ColorConstants.light,
                  child: Padding(
                    padding: EdgeInsets.all(8.0.toFont),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Center(
                              child: CircularProgressIndicator(
                                  valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                      ColorConstants
                                          .appColor)),
                            ),
                            SizedBox(width: 6.toWidth),
                            Flexible(
                              flex: 7,
                              child: Text(
                                  Strings.recurrServerCheck,
                                  textAlign: TextAlign.start,
                                  style: CustomTextStyles
                                      .fontR16primary),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CustomButton(
                            isInverted: true,
                            height: 35.0.toHeight,
                            width: 65.toWidth,
                            buttonText: Strings.stopButtonTitle,
                            onPressed: () {
                              _isContinue = false;
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
                : SizedBox(
              height: SizeConfig().screenHeight * 0.6,
              width: SizeConfig().screenWidth,
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                ColorConstants.appColor)),
                        SizedBox(height: 20.toHeight),
                        if (_loadingMessage != null)
                          Text(
                            _loadingMessage!,
                            style: TextStyle(
                                fontSize: 15.toFont,
                                fontWeight: FontWeight.w500),
                          )
                      ])),
            )
                : const SizedBox()
          ],
        ),
      ),
    );
  }
}
