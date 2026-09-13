// services/device_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class DeviceService {
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return '${info.id}_${info.fingerprint}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_device';
  }

  static Future<Map<String, String>> getDeviceLabel() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      final manufacturer = info.manufacturer.trim();
      final model = info.model.trim();
      final name = manufacturer.isNotEmpty && !model.startsWith(manufacturer)
          ? '$manufacturer $model'
          : model;
      return {
        'name': name.isEmpty ? 'هاتف Android' : name,
        'platform': 'android',
      };
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      final name = info.name.isNotEmpty ? info.name : (info.model);
      return {'name': name.isEmpty ? 'iPhone' : name, 'platform': 'ios'};
    }
    return {'name': 'جهاز غير معروف', 'platform': 'unknown'};
  }

  static Future<String?> checkDeviceOwner(String deviceId) async {
    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .get();

    if (doc.exists) {
      return doc.data()?['uid'] as String?;
    }
    return null;
  }

  static Future<void> linkDeviceToUser({
    required String deviceId,
    required String uid,
    required String method,
  }) async {
    await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
      'uid': uid,
      'method': method,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> registerSession({
    required String uid,
    required String method,
  }) async {
    final deviceId = await getDeviceId();
    final label = await getDeviceLabel();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .set({
          'deviceId': deviceId,
          'name': label['name'],
          'platform': label['platform'],
          'method': method,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<void> signOutDevice({
    required String uid,
    required String deviceId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .delete();
  }
}
