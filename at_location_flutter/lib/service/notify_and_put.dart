import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_commons/at_commons.dart';
// ignore: implementation_imports
import 'package:at_client/src/service/notification_service.dart';
import 'package:at_utils/at_logger.dart';
import 'dart:convert';


class NotifyAndPut {
  NotifyAndPut._();
  static final NotifyAndPut _instance = NotifyAndPut._();
  factory NotifyAndPut() => _instance;
  final _logger = AtSignLogger('NotifyAndPut');

  Future<bool> imagePut(
      AtKey atKey, AtKey imageKey, dynamic value, dynamic imageData,
      {bool saveDataIfUndelivered = false}) async {
    try {
      /// because .notify and .put will append the namespace
      /// and we dont want atKey.namespace.namespace
      atKey = removeNamespaceFromKey(atKey);
      imageKey = removeNamespaceFromKey(imageKey);

      if (!atKey.sharedBy!.contains('@')) {
        atKey.sharedBy = '@' + atKey.sharedBy!;
      }
      if (!atKey.sharedWith!.contains('@')) {
        atKey.sharedWith = '@' + atKey.sharedWith!;
      }

      if (!imageKey.sharedBy!.contains('@')) {
        imageKey.sharedBy = '@' + imageKey.sharedBy!;
      }

      if (!imageKey.sharedWith!.contains('@')) {
        imageKey.sharedWith = '@' + imageKey.sharedWith!;
      }

      imageKey.sharedWith = null;
      bool res = await AtClientManager.getInstance().atClient.put(
            removeNamespaceFromKey(imageKey),
            imageData,
          );
      if (res) {
        var result =
            await AtClientManager.getInstance().notificationService.notify(
                  NotificationParams.forUpdate(
                    atKey,
                    value: value,
                  ),
                );

        _logger.finer(
            'notifyAndPut result for $atKey - $result ${result.atClientException}');

        if ((saveDataIfUndelivered) ||
            (result.notificationStatusEnum ==
                NotificationStatusEnum.delivered)) {
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
      }

      return false;
    } catch (e) {
      _logger.severe('Error in notifyAndPut $e');
      return false;
    }
  }

  Future<bool> notifyAndPut(
    AtKey atKey,
    dynamic value, {
    bool saveDataIfUndelivered = false,
    AtKey? imageKey,
    dynamic imageData,
  }) async {
    try {
      if (imageKey != null) {
        imageKey = removeNamespaceFromKey(imageKey);
        if (!imageKey.sharedBy!.contains('@')) {
          imageKey.sharedBy = '@' + imageKey.sharedBy!;
        }

        if (!imageKey.sharedWith!.contains('@')) {
          imageKey.sharedWith = '@' + imageKey.sharedWith!;
        }
         /* var result =
          await AtClientManager.getInstance().notificationService.notify(
                NotificationParams.forUpdate(
                  imageKey,
                  value: base64.encode(imageData),
                ),
              );
              if (result.notificationStatusEnum != NotificationStatusEnum.delivered) {
        return false;
      } */


        imageKey.sharedWith = null;
         bool res = await AtClientManager.getInstance().atClient.put(
              removeNamespaceFromKey(imageKey),
              imageData,
            ); 
        if (!res) {
          return false;
        } else {/* 
         var value = (await AtClientManager.getInstance().atClient.get(imageKey)).value;
OperationEnum operation = OperationEnum.update;
bool res = await AtClientManager.getInstance().atClient.notify(imageKey, base64.encode(imageData), operation);
print(res); */
      } 
      }

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

      _logger.finer(
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
      _logger.severe('Error in notifyAndPut $e');
      return false;
    }
  }
  

  AtKey removeNamespaceFromKey(AtKey atKey) {
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
