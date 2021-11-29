import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_client/src/service/notification_service.dart';

class NotifyAndPut {
  NotifyAndPut._();
  static final NotifyAndPut _instance = NotifyAndPut._();
  factory NotifyAndPut() => _instance;

  Future<bool> notifyAndPut(AtKey atKey, dynamic value,
      {bool saveDataIfUndelivered = false}) async {
    try {
      /// because .notify and .put will append the namespace
      /// and we dont want atKey.namespace.namespace
      atKey = removeNamespaceFromKey(atKey);

      if (!atKey.sharedBy!.contains('@')) {
        atKey.sharedBy = '@' + atKey.sharedBy!;
      }

      if (!atKey.sharedWith!.contains('@')) {
        atKey.sharedWith = '@' + atKey.sharedWith!;
      }

      var result =
          await AtClientManager.getInstance().notificationService.notify(
                NotificationParams.forUpdate(
                  atKey,
                  value: value,
                ),
              );

      print(
          'notifyAndPut result for $atKey - $result ${result.atClientException}');

      if ((saveDataIfUndelivered) ||
          (result.notificationStatusEnum == NotificationStatusEnum.delivered)) {
        /// because .notify and .put will append the namespace
        /// and we dont want atKey.namespace.namespace
        atKey = removeNamespaceFromKey(atKey);

        atKey.sharedWith = null;
        await AtClientManager.getInstance().atClient.put(
              atKey,
              value,
            );
        return true;
      }
      return false;
    } catch (e) {
      print('Error in notifyAndPut $e');
      return false;
    }
  }

  AtKey removeNamespaceFromKey(AtKey atKey) {
    print('namespace: ' +
        (AtClientManager.getInstance().atClient.getPreferences()!.namespace ??
            ''));
    if (AtClientManager.getInstance().atClient.getPreferences()!.namespace !=
        null) {
      if (atKey.key!.contains('.' +
          AtClientManager.getInstance()
              .atClient
              .getPreferences()!
              .namespace!)) {
        atKey.key = atKey.key!.replaceAll(
            ('.' +
                AtClientManager.getInstance()
                    .atClient
                    .getPreferences()!
                    .namespace!),
            '');
      }
    }

    return atKey;
  }

  String removeNamespaceFromString(String _id) {
    var _namespace =
        AtClientManager.getInstance().atClient.getPreferences()!.namespace;
    if ((_namespace != null) && (_id.contains('.' + _namespace))) {
      _id = _id.replaceAll(('.' + _namespace), '');
    }

    return _id;
  }
}