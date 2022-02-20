import 'package:at_onboarding_flutter/utils/color_constants.dart';
import 'package:at_onboarding_flutter/utils/strings.dart';
import 'package:flutter/material.dart';

import 'at_onboarding_config.dart';
import 'services/at_error_dialog.dart';
import 'services/sdk_service.dart';
import 'utils/app_constants.dart';

class AtOnboardingResetScreen extends StatefulWidget {
  final AtOnboardingConfig config;

  const AtOnboardingResetScreen({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  _AtOnboardingResetScreenState createState() =>
      _AtOnboardingResetScreenState();
}

class _AtOnboardingResetScreenState extends State<AtOnboardingResetScreen> {
  bool initialing = false;
  bool? loading = false;
  List<String> atsignsList = [];
  Map<String, bool?> atsignMap = <String, bool>{};
  bool isSelectAtsign = false;
  bool isSelectAll = false;

  @override
  void initState() {
    setup();
    super.initState();
  }

  void setup() async {
    if (mounted) {
      setState(() {
        initialing = true;
      });
    }
    atsignsList = await SDKService().getAtsignList() ?? [];
    for (String atsign in atsignsList) {
      atsignMap[atsign] = false;
    }
    if (mounted) {
      setState(() {
        initialing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) stateSet) {
      return AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text(Strings.resetDescription,
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
              SizedBox(
                height: 10,
              ),
              Divider(
                thickness: 0.8,
              )
            ],
          ),
          content: atsignsList == null
              ? Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  const Text(Strings.noAtsignToReset,
                      style: TextStyle(fontSize: 15)),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(AppConstants.closeButton,
                            style: TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 240, 94, 62)))),
                  )
                ])
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CheckboxListTile(
                        onChanged: (bool? value) {
                          isSelectAll = value!;
                          if (atsignMap.isNotEmpty) {
                            atsignMap.updateAll(
                                (String? key, bool? value1) => value1 = value);
                          }
                          // atsignMap[atsign] = value;
                          stateSet(() {});
                        },
                        value: isSelectAll,
                        checkColor: Colors.white,
                        activeColor: const Color.fromARGB(255, 240, 94, 62),
                        title: const Text('Select All',
                            style: TextStyle(
                              // fontSize: 14,
                              fontWeight: FontWeight.bold,
                            )),
                        // trailing: Checkbox,
                      ),
                      for (String atsign in atsignsList)
                        CheckboxListTile(
                          onChanged: (bool? value) {
                            if (atsignMap.isNotEmpty) {
                              atsignMap[atsign] = value;
                            }
                            stateSet(() {});
                          },
                          value:
                              atsignMap.isNotEmpty ? atsignMap[atsign] : true,
                          checkColor: Colors.white,
                          activeColor: const Color.fromARGB(255, 240, 94, 62),
                          title: Text(atsign),
                          // trailing: Checkbox,
                        ),
                      const Divider(thickness: 0.8),
                      if (isSelectAtsign)
                        const Text(Strings.resetErrorText,
                            style: TextStyle(color: Colors.red, fontSize: 14)),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(Strings.resetWarningText,
                          style: TextStyle(
                              color: ColorConstants.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(children: <Widget>[
                        TextButton(
                          onPressed: () {
                            Map<String, bool?> tempAtsignMap = <String, bool>{};
                            tempAtsignMap.addAll(atsignMap);
                            tempAtsignMap.removeWhere(
                                (String? key, bool? value) => value == false);
                            if (tempAtsignMap.keys.toList().isEmpty) {
                              isSelectAtsign = true;
                              stateSet(() {});
                            } else {
                              isSelectAtsign = false;
                              _resetDevice(tempAtsignMap.keys.toList());
                            }
                          },
                          child: const Text(AppConstants.removeButton,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 240, 94, 62))),
                        ),
                        const Spacer(),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(AppConstants.cancelButton,
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black)))
                      ])
                    ],
                  ),
                ));
    });
  }

  Future<void> _resetDevice(List<String> checkedAtsigns) async {
    Navigator.of(context).pop();
    setState(() {
      loading = true;
    });
    await SDKService().resetAtsigns(checkedAtsigns).then((void value) async {
      setState(() {
        loading = false;
      });
    }).catchError((Object error) {
      setState(() {
        loading = false;
      });
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AtErrorDialog.getAlertDialog(error, context);
          });
    });
  }
}
