import 'dart:io';

import 'package:at_backupkey_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/at_onboarding_config.dart';
import 'package:at_onboarding_flutter/screens/atsign_list_screen.dart';
import 'package:at_onboarding_flutter/services/free_atsign_service.dart';
import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/custom_textstyles.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AtOnboardingScreen extends StatefulWidget {
  final AtOnboardingConfig config;
  /// If true, shows the custom dialog to get an atsign
  final bool getAtSign;
  final bool isQR;
  final bool hideReferences;
  final bool hideQrScan;
  const AtOnboardingScreen({
    Key? key,
    required this.config,
    this.getAtSign = false,
    this.isQR = false,
    this.hideReferences = false,
    this.hideQrScan = false,
  }) : super(key: key);

  @override
  State<AtOnboardingScreen> createState() => _AtOnboardingScreenState();
}

class _AtOnboardingScreenState extends State<AtOnboardingScreen> {
  final TextEditingController _atsignController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final FreeAtsignService _freeAtsignService = FreeAtsignService();

  final bool scanQR = false;
  final bool showClose = false;
  late final Function? onClose;

  bool loading = false;
  bool permissionGrated = false;
  bool otp = false;
  bool pair = false;
  bool isfreeAtsign = false;
  bool isAtsignForm = true;
  bool isQrScanner = false;

  String? _loadingMessage;

  @override
  void initState() {
    checkPermissions();
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
    if (widget.isQR) {
      otp = true;
      pair = true;
      isfreeAtsign = true;
    }
    double _dialogWidth = double.maxFinite;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _dialogWidth = 400;
    }

    return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) stateSet) {
      return Stack(children: <Widget>[
        Opacity(
            opacity: loading ? 0.3 : 1,
            child: AbsorbPointer(
                absorbing: loading,
                child: AlertDialog(
                  title: Text(
                    'Setting up your account',
                    style: TextStyle(
                        color: ColorConstants.appColor,
                        fontSize: 16.toFont),
                  ),
                  content: isAtsignForm && !isQrScanner
                      ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0.toFont),
                      child: SizedBox(
                        width: _dialogWidth,
                        child: ListView(
                          shrinkWrap: true,
                          children: <Widget>[
                            if (!isfreeAtsign &&
                                !widget.isQR &&
                                !isQrScanner) ...<Widget>[
                              SizedBox(height: 15.toHeight),
                              Text(
                                'Upload file @sign?',
                                style: Theme.of(context).brightness !=
                                    Brightness.dark
                                    ? CustomTextStyles.fontR12primary
                                    : CustomTextStyles.fontR12secondary,
                              ),
                              SizedBox(height: 5.toHeight),
                              SizedBox(
                                  width: MediaQuery.of(context)
                                      .size
                                      .width
                                      .toWidth,
                                  height: SizeConfig().isTablet(context)
                                      ? 50.toHeight
                                      : null,
                                  child: ElevatedButton(
                                    style: Theme.of(context).brightness ==
                                        Brightness.light
                                        ? ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty.all(
                                            Colors.grey[800]))
                                        : ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty.all(
                                            Colors.white)),
                                    onPressed: () async {
                                      ///TODO
                                    },
                                    child: Text(
                                      'Upload File',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .brightness ==
                                              Brightness.light
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 15.toFont),
                                    ),
                                  )),
                              SizedBox(height: 20.toHeight),
                              Text(
                                'Need an @sign?',
                                style: Theme.of(context).brightness !=
                                    Brightness.dark
                                    ? CustomTextStyles.fontR12primary
                                    : CustomTextStyles.fontR12secondary,
                              ),
                              SizedBox(height: 5.toHeight),
                              SizedBox(
                                  width: MediaQuery.of(context)
                                      .size
                                      .width
                                      .toWidth,
                                  height: SizeConfig().isTablet(context)
                                      ? 50.toHeight
                                      : null,
                                  child: ElevatedButton(
                                    style: Theme.of(context).brightness ==
                                        Brightness.light
                                        ? ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty.all(
                                            Colors.grey[800]))
                                        : ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty.all(
                                            Colors.white)),
                                    onPressed: () async {
                                      /// TODO
                                    },
                                    child: Text(
                                      'Generate Free @sign',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .brightness ==
                                              Brightness.light
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 15.toFont),
                                    ),
                                  )),
                              SizedBox(height: 20.toHeight),
                              widget.hideQrScan
                                  ? const SizedBox()
                                  : Text('Have a QR Code?',
                                  style: Theme.of(context).brightness !=
                                      Brightness.dark
                                      ? CustomTextStyles.fontR12primary
                                      : CustomTextStyles
                                      .fontR12secondary),
                              widget.hideQrScan
                                  ? const SizedBox()
                                  : SizedBox(height: 5.toHeight),
                              widget.hideQrScan
                                  ? const SizedBox()
                                  : (Platform.isAndroid || Platform.isIOS)
                                  ? SizedBox(
                                  width: MediaQuery.of(context)
                                      .size
                                      .width
                                      .toWidth,
                                  height:
                                  SizeConfig().isTablet(context)
                                      ? 50.toHeight
                                      : null,
                                  child: ElevatedButton(
                                    style: Theme.of(context)
                                        .brightness ==
                                        Brightness.light
                                        ? ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty
                                            .all(Colors
                                            .grey[800]))
                                        : ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty
                                            .all(Colors
                                            .white)),
                                    onPressed: () async {
                                      ///TODO
                                    },
                                    child: Text(
                                      'Scan QR code',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .brightness ==
                                              Brightness.light
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 15.toFont),
                                    ),
                                  ))
                                  : SizedBox(
                                  width: MediaQuery.of(context)
                                      .size
                                      .width,
                                  height:
                                  SizeConfig().isTablet(context)
                                      ? 50.toHeight
                                      : null,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty
                                            .all(Colors
                                            .grey[800])),
                                    onPressed: () async {

                                    },
                                    child: Text(
                                      'Upload QR code',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.toFont),
                                    ),
                                  )),
                            ],
                            if (isfreeAtsign) ...<Widget>[
                              SizedBox(height: 15.toHeight),
                              !otp
                                  ? !pair
                                  ? SizedBox(
                                  width: MediaQuery.of(context)
                                      .size
                                      .width,
                                  height:
                                  SizeConfig().isTablet(context)
                                      ? 50.toHeight
                                      : null,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                        MaterialStateProperty
                                            .all(Colors
                                            .grey[800])),
                                    onPressed: () async {
                                      ///TODO
                                    },
                                    child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                        children: <Widget>[
                                          Center(
                                              child: Text(
                                                'Refresh',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                    15.toFont),
                                              )),
                                          const Icon(
                                            Icons.refresh,
                                            color: Colors.white,
                                            size: 30,
                                          )
                                        ]),
                                  ))
                                  : Column(children: <Widget>[
                                SizedBox(
                                    width: MediaQuery.of(context)
                                        .size
                                        .width,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                          MaterialStateProperty.all(
                                              (_emailController
                                                  .text !=
                                                  '')
                                                  ? Colors.grey[
                                              800]
                                                  : Colors.grey[
                                              400])),
                                      onPressed: () async {
                                        if (_emailController
                                            .text !=
                                            '') {
                                          loading = true;
                                          stateSet(() {});
                                          bool status = false;

                                          loading = false;
                                          stateSet(() {});
                                        }
                                      },
                                      child: Center(
                                          child: Text(
                                            'Send Code',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.toFont),
                                          )),
                                    )),
                                SizedBox(
                                  height: 10.toHeight,
                                ),
                                Text(
                                  Strings.emailNote,
                                  style: TextStyle(
                                      fontSize: 13.toFont,
                                      fontWeight:
                                      FontWeight.w600),
                                ),
                                Center(
                                    child: TextButton(
                                        onPressed: () {
                                          pair = false;
                                          stateSet(() {});
                                        },
                                        child: Text(
                                          'Back',
                                          style: TextStyle(
                                              color: Colors
                                                  .grey[700]),
                                        )))
                              ])
                                  : Column(children: <Widget>[
                                SizedBox(
                                    width: MediaQuery.of(context)
                                        .size
                                        .width,
                                    height:
                                    SizeConfig().isTablet(context)
                                        ? 50.toHeight
                                        : null,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                          MaterialStateProperty.all(
                                              (_emailController
                                                  .text !=
                                                  '' ||
                                                  widget.isQR)
                                                  ? Colors
                                                  .grey[800]
                                                  : Colors.grey[
                                              400])),
                                      onPressed: () async {
                                        if ((_emailController.text !=
                                            '') ||
                                            widget.isQR) {
                                          loading = true;
                                          stateSet(() {});


                                          loading = false;
                                          stateSet(() {});

                                        }
                                      },
                                      child: Center(
                                          child: Text(
                                            'Verify & Login',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.toFont),
                                          )),
                                    )),
                                SizedBox(height: 10.toHeight),
                                TextButton(
                                    onPressed: () async {
                                      if ((_emailController.text !=
                                          '') ||
                                          widget.isQR) {
                                        loading = true;
                                        stateSet(() {});

                                        loading = false;
                                        stateSet(() {});
                                      }
                                    },
                                    child: Text(
                                      'Resend Code',
                                      style: TextStyle(
                                          color:
                                          ColorConstants.appColor,
                                          fontSize: 15.toFont),
                                    )),
                                SizedBox(height: 10.toHeight),
                                if (!widget.isQR)
                                  TextButton(
                                      onPressed: () {
                                        otp = false;

                                        stateSet(() {});
                                      },
                                      child: Text(
                                        'Wrong email?',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15.toFont),
                                      )),
                                if (widget.isQR)
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Back',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15.toFont),
                                      ))
                              ]),
                              if (!pair) ...<Widget>[
                                SizedBox(height: 15.toHeight),
                                SizedBox(
                                    width:
                                    MediaQuery.of(context).size.width,
                                    height: SizeConfig().isTablet(context)
                                        ? 50.toHeight
                                        : null,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                          MaterialStateProperty.all(
                                              ColorConstants.appColor)),
                                      onPressed: () async {
                                        pair = true;
                                        _emailController.text = '';
                                        stateSet(() {});
                                      },
                                      child: Center(
                                          child: Text(
                                            'Pair',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.toFont),
                                          )),
                                    )),
                                const SizedBox(height: 10),
                                Center(
                                    child: TextButton(
                                        onPressed: () {
                                          isfreeAtsign = false;
                                          _atsignController.text = '';
                                          stateSet(() {});
                                        },
                                        child: Text(
                                          'Back',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12.toFont),
                                        )))
                              ]
                            ]
                          ],
                        ),
                      ))
                      // : _getMessage(widget.message, widget.isErrorDialog),
                  : Container(),
                  actions: showClose
                      ? <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onClose!();
                      },
                      child: Text(
                        Strings.closeTitle,
                        style: TextStyle(
                            color: ColorConstants.appColor,
                            fontSize: 14.toFont),
                      ),
                    ),
                  ]
                      : null,
                ))),
      ]);
    });
  }
}
