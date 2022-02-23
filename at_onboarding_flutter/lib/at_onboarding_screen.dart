import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:at_backupkey_flutter/utils/color_constants.dart';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_onboarding_flutter/at_onboarding_config.dart';
import 'package:at_onboarding_flutter/at_onboarding_generate_screen.dart';
import 'package:at_onboarding_flutter/at_onboarding_qrcode_screen.dart';
import 'package:at_onboarding_flutter/services/onboarding_service.dart';
import 'package:at_onboarding_flutter/services/size_config.dart';
import 'package:at_onboarding_flutter/utils/at_onboarding_dimens.dart';
import 'package:at_onboarding_flutter/utils/custom_textstyles.dart';
import 'package:at_onboarding_flutter/utils/response_status.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:at_onboarding_flutter/widgets/custom_button.dart';
import 'package:at_onboarding_flutter/widgets/custom_dialog.dart';
import 'package:at_onboarding_flutter/widgets/custom_strings.dart';
import 'package:at_utils/at_logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'screens/private_key_qrcode_generator.dart';
import 'widgets/at_onboarding_button.dart';

class AtOnboardingScreen extends StatefulWidget {
  final AtOnboardingConfig config;

  /// If true, shows the custom dialog to get an atsign
  final bool getAtSign;

  // final bool isQR;
  final bool hideReferences;
  final bool hideQrScan;

  final onboardStatus = OnboardingStatus.ACTIVATE;

  final VoidCallback? onBoardingSuccess;

  const AtOnboardingScreen({
    Key? key,
    required this.config,
    this.getAtSign = false,
    // this.isQR = false,
    this.hideReferences = false,
    this.hideQrScan = false,
    this.onBoardingSuccess,
  }) : super(key: key);

  @override
  State<AtOnboardingScreen> createState() => _AtOnboardingScreenState();
}

class _AtOnboardingScreenState extends State<AtOnboardingScreen> {
  final AtSignLogger _logger = AtSignLogger('At Onboarding');
  final OnboardingService _onboardingService = OnboardingService.getInstance();

  final bool scanQR = false;
  final bool showClose = false;
  late final Function? onClose;

  bool loading = false;
  bool permissionGrated = false;

  // bool otp = false;
  // bool pair = false;
  // bool isfreeAtsign = false;
  // bool isAtsignForm = true;
  // bool isQrScanner = false;
  bool _isServerCheck = false;
  bool _isContinue = true;
  String? _pairingAtsign;

  final String _incorrectKeyFile =
      'Unable to fetch the keys from chosen file. Please choose correct file';
  final String _failedFileProcessing =
      'Failed in processing files. Please try again';

  @override
  void initState() {
    checkPermissions();
    super.initState();
  }

  Future<void> checkPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      PermissionStatus cameraStatus = await Permission.camera.status;
      PermissionStatus storageStatus = await Permission.storage.status;
      _logger.info('camera status => $cameraStatus');
      _logger.info('storage status is $storageStatus');
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

  Future<void> _uploadKeyFile() async {
    try {
      if (!permissionGrated) {
        await checkPermissions();
      }
      _isServerCheck = false;
      _isContinue = true;
      String? fileContents, aesKey, atsign;
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.any, allowMultiple: true);
      setState(() {
        loading = true;
      });
      for (PlatformFile pickedFile in result?.files ?? <PlatformFile>[]) {
        String? path = pickedFile.path;
        if (path == null) {
          throw const FileSystemException(
              'FilePicker.pickFiles returned a null path');
        }
        File selectedFile = File(path);
        int length = selectedFile.lengthSync();
        if (length < 10) {
          await showErrorDialog(context, _incorrectKeyFile);
          return;
        }

        if (pickedFile.extension == 'zip') {
          Uint8List bytes = selectedFile.readAsBytesSync();
          Archive archive = ZipDecoder().decodeBytes(bytes);
          for (ArchiveFile file in archive) {
            if (file.name.contains('atKeys')) {
              fileContents = String.fromCharCodes(file.content);
            } else if (aesKey == null &&
                atsign == null &&
                file.name.contains('_private_key.png')) {
              List<int> bytes = file.content as List<int>;
              String path = (await path_provider.getTemporaryDirectory()).path;
              File file1 = await File(path + 'test').create();
              file1.writeAsBytesSync(bytes);
              String result = await FlutterQrReader.imgScan(file1.path);
              List<String> params = result.replaceAll('"', '').split(':');
              atsign = params[0];
              aesKey = params[1];
              await File(path + 'test').delete();
              //read scan QRcode and extract atsign,aeskey
            }
          }
        } else if (pickedFile.name.contains('atKeys')) {
          fileContents = File(path.toString()).readAsStringSync();
        } else if (aesKey == null &&
            atsign == null &&
            pickedFile.name.contains('_private_key.png')) {
          //read scan QRcode and extract atsign,aeskey
          String result = await FlutterQrReader.imgScan(path.toString());
          List<String> params = result.split(':');
          atsign = params[0];
          aesKey = params[1];
        } else {
          Uint8List result1 = selectedFile.readAsBytesSync();
          fileContents = String.fromCharCodes(result1);
          bool result = _validatePickedFileContents(fileContents);
          _logger.finer('result after extracting data is......$result');
          if (!result) {
            await showErrorDialog(context, _incorrectKeyFile);
            setState(() {
              loading = false;
            });
            return;
          }
        }
      }
      if (aesKey == null && atsign == null && fileContents != null) {
        List<String> keyData = fileContents.split(',"@');
        List<String> params = keyData[1]
            .toString()
            .substring(0, keyData[1].length - 2)
            .split('":"');
        atsign = params[0];
        aesKey = params[1];
      }
      if (fileContents == null || (aesKey == null && atsign == null)) {
        await showErrorDialog(context, _incorrectKeyFile);
        setState(() {
          loading = false;
        });
        return;
      } else if (OnboardingService.getInstance().formatAtSign(atsign) !=
              _pairingAtsign &&
          _pairingAtsign != null) {
        await showErrorDialog(
            context, CustomStrings().atsignMismatch(_pairingAtsign));
        setState(() {
          loading = false;
        });
        return;
      }
      await _processAESKey(atsign, aesKey, fileContents);
      setState(() {
        loading = false;
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      _logger.severe('Uploading backup zip file throws $error');
      await showErrorDialog(context, _failedFileProcessing);
    }
  }

  Future<void> _uploadKeyFileForDesktop() async {
    try {
      _isServerCheck = false;
      _isContinue = true;
      String? fileContents, aesKey, atsign;
      setState(() {
        loading = true;
      });

      String? path = await _desktopKeyPicker();
      if (path == null) {
        return;
      }

      File selectedFile = File(path);
      int length = selectedFile.lengthSync();
      if (length < 10) {
        await showErrorDialog(context, _incorrectKeyFile);
        return;
      }

      fileContents = File(path).readAsStringSync();

      if (aesKey == null && atsign == null && fileContents.isNotEmpty) {
        List<String> keyData = fileContents.split(',"@');
        List<String> params = keyData[1]
            .toString()
            .substring(0, keyData[1].length - 2)
            .split('":"');
        atsign = params[0];
        aesKey = params[1];
      }
      if (fileContents.isEmpty || (aesKey == null && atsign == null)) {
        await showErrorDialog(context, _incorrectKeyFile);
        setState(() {
          loading = false;
        });
        return;
      } else if (OnboardingService.getInstance().formatAtSign(atsign) !=
              _pairingAtsign &&
          _pairingAtsign != null) {
        await showErrorDialog(
            context, CustomStrings().atsignMismatch(_pairingAtsign));
        setState(() {
          loading = false;
        });
        return;
      }
      await _processAESKey(atsign, aesKey, fileContents);
      setState(() {
        loading = false;
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      _logger.severe('Uploading backup zip file throws $error');
      await showErrorDialog(context, _failedFileProcessing);
    }
  }

  Future<String?> _desktopKeyPicker() async {
    try {
      XTypeGroup typeGroup = XTypeGroup(
        label: 'images',
        extensions: <String>['atKeys'],
      );
      List<XFile> files =
          await openFiles(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      if (files.isEmpty) {
        return null;
      }
      XFile file = files[0];
      return file.path;
    } catch (e) {
      _logger.severe('Error in desktopImagePicker $e');
      return null;
    }
  }

  Future<void> _processAESKey(
      String? atsign, String? aesKey, String contents) async {
    dynamic authResponse;
    assert(aesKey != null || aesKey != '');
    assert(atsign != null || atsign != '');
    assert(contents != '');
    setState(() {
      loading = true;
    });
    try {
      bool isExist = await _onboardingService.isExistingAtsign(atsign);
      if (isExist) {
        setState(() {
          loading = false;
        });
        await showErrorDialog(context, CustomStrings().pairedAtsign(atsign));
        return;
      }
      authResponse = await _onboardingService.authenticate(atsign,
          jsonData: contents, decryptKey: aesKey);
      if (authResponse == ResponseStatus.authSuccess) {
        if (_onboardingService.nextScreen == null) {
          Navigator.pop(context);
          _onboardingService.onboardFunc(_onboardingService.atClientServiceMap,
              _onboardingService.currentAtsign);
        } else {
          _onboardingService.onboardFunc(_onboardingService.atClientServiceMap,
              _onboardingService.currentAtsign);
          await Navigator.pushReplacement(
              context,
              MaterialPageRoute<Widget>(
                  builder: (BuildContext context) =>
                      _onboardingService.nextScreen!));
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (e == ResponseStatus.serverNotReached && _isContinue) {
        _isServerCheck = _isContinue;
        await _processAESKey(atsign, aesKey, contents);
      } else if (e == ResponseStatus.authFailed) {
        _logger.severe('Error in authenticateWithAESKey');
        await showErrorDialog(context, 'Auth Failed');
      } else if (e == ResponseStatus.timeOut) {
        await showErrorDialog(context, 'Response Time out');
      } else {
        _logger.warning(e);
      }
    }
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

  bool _validatePickedFileContents(String fileContents) {
    bool result = fileContents
            .contains(BackupKeyConstants.PKAM_PRIVATE_KEY_FROM_KEY_FILE) &&
        fileContents
            .contains(BackupKeyConstants.PKAM_PUBLIC_KEY_FROM_KEY_FILE) &&
        fileContents
            .contains(BackupKeyConstants.ENCRYPTION_PRIVATE_KEY_FROM_FILE) &&
        fileContents
            .contains(BackupKeyConstants.ENCRYPTION_PUBLIC_KEY_FROM_FILE) &&
        fileContents.contains(BackupKeyConstants.SELF_ENCRYPTION_KEY_FROM_FILE);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    // if (widget.isQR) {
    //   otp = true;
    //   pair = true;
    //   isfreeAtsign = true;
    // }
    double _dialogWidth = double.maxFinite;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _dialogWidth = 400;
    }

    return AbsorbPointer(
      absorbing: loading,
      child: AlertDialog(
        title: Text(
          'Setting up your account',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: AtOnboardingDimens.fontLarge,
          ),
        ),
        content: SizedBox(
          width: _dialogWidth,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              SizedBox(height: 5.toHeight),
              AtOnboardingPrimaryButton(
                onPressed:
                    (Platform.isMacOS || Platform.isLinux || Platform.isWindows)
                        ? _uploadKeyFileForDesktop
                        : _uploadKeyFile,
                child: Text(
                  'Upload backup key file',
                  style: TextStyle(fontSize: 16.toFont),
                ),
                isLoading: loading,
              ),
              const Text(
                'Upload your backup key file from stored location which was generated during the pairing process of your @sign.',
                style: TextStyle(fontSize: AtOnboardingDimens.fontSmall),
              ),
              SizedBox(height: 20.toHeight),
              const Text(
                'Need an @sign?',
                style: TextStyle(fontSize: AtOnboardingDimens.fontNormal),
              ),
              SizedBox(height: 5.toHeight),
              AtOnboardingPrimaryButton(
                onPressed: () async {
                  _showGenerateScreen(context: context);
                },
                child: const Text(
                  'Generate Free @sign',
                  style: TextStyle(fontSize: AtOnboardingDimens.fontLarge),
                ),
              ),
              SizedBox(height: 20.toHeight),
              if (!widget.hideQrScan)
                const Text(
                  'Have a QR Code?',
                  style: TextStyle(fontSize: AtOnboardingDimens.fontNormal),
                ),
              if (!widget.hideQrScan) SizedBox(height: 5.toHeight),
              if (!widget.hideQrScan)
                (Platform.isAndroid || Platform.isIOS)
                    ? AtOnboardingPrimaryButton(
                        onPressed: () async {
                          _showQRCodeScreen(context: context);
                        },
                        child: const Text(
                          'Scan QR code',
                          style:
                              TextStyle(fontSize: AtOnboardingDimens.fontLarge),
                        ),
                      )
                    : AtOnboardingPrimaryButton(
                        onPressed: () async {},
                        child: Text(
                          'Upload QR code',
                          style: TextStyle(
                              color: Colors.white, fontSize: 15.toFont),
                        ),
                      ),
            ],
          ),
        ),
        actions: <Widget>[
          AtOnboardingSecondaryButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              Strings.closeTitle,
            ),
          ),
        ],
      ),
    );
  }

  void _showGenerateScreen({
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AtOnboardingGenerateScreen(
        onGenerateSuccess: ({required String atSign, required String secret}) {
          _processSharedSecret(atSign, secret);
        },
      ),
    );
  }


  void _showQRCodeScreen({
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AtOnboardingQRCodeScreen(),
    );
  }

  Future<dynamic> _processSharedSecret(String atsign, String secret,
      {bool isScanner = false}) async {
    dynamic authResponse;
    try {
      setState(() {
        loading = true;
      });
      bool isExist = await _onboardingService.isExistingAtsign(atsign);
      if (isExist) {
        setState(() {
          loading = false;
        });
        await _showAlertDialog(CustomStrings().pairedAtsign(atsign));
        return;
      }
      authResponse = await _onboardingService.authenticate(atsign,
          cramSecret: secret, status: widget.onboardStatus);
      if (authResponse == ResponseStatus.authSuccess) {
        if (widget.onboardStatus == OnboardingStatus.ACTIVATE ||
            widget.onboardStatus == OnboardingStatus.RESTORE) {
          _onboardingService.onboardFunc(_onboardingService.atClientServiceMap,
              _onboardingService.currentAtsign);
          if (_onboardingService.nextScreen == null) {
            if (isScanner) Navigator.pop(context);
            Navigator.pop(context);
            widget.onBoardingSuccess?.call();
            return;
          }
          if (isScanner) Navigator.pop(context);
          await Navigator.pushReplacement(
              context,
              MaterialPageRoute<OnboardingService>(
                  builder: (BuildContext context) =>
                      _onboardingService.nextScreen!));
        } else {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute<PrivateKeyQRCodeGenScreen>(
                builder: (BuildContext context) =>
                    const PrivateKeyQRCodeGenScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (e == ResponseStatus.authFailed) {
        _logger.severe('Error in authenticateWith cram secret');
        await _showAlertDialog(e, title: 'Auth Failed');
      } else if (e == ResponseStatus.serverNotReached && _isContinue) {
        _isServerCheck = _isContinue;
        await _processSharedSecret(atsign, secret);
      } else if (e == ResponseStatus.timeOut) {
        await _showAlertDialog(e, title: 'Response Time out');
      }
    }
    return authResponse;
  }

  Future<void> _showAlertDialog(dynamic errorMessage,
          {bool? isPkam,
          String? title,
          bool? getClose,
          Function? onClose}) async =>
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
                context: context,
                hideReferences: widget.hideReferences,
                hideQrScan: widget.hideQrScan,
                isErrorDialog: true,
                showClose: true,
                message: errorMessage,
                title: title,
                onClose: getClose == true ? onClose : () {});
          });
}
