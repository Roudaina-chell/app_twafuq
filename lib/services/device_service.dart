// services/device_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class DeviceService {
  /// Get a safe device ID that can be used as a Firestore document ID.
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;

      // Android device information can contain "/" characters,
      // especially in the fingerprint.
      // Firestore uses "/" as a path separator, so we replace it.
      final rawDeviceId = '${info.id}_${info.fingerprint}';

      return rawDeviceId
          .replaceAll('/', '_')
          .replaceAll('\\', '_')
          .trim();
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;

      final rawDeviceId =
          info.identifierForVendor ?? 'unknown_ios_device';

      return rawDeviceId
          .replaceAll('/', '_')
          .replaceAll('\\', '_')
          .trim();
    }

    return 'unknown_device';
  }

  /// Get a readable device name and platform.
  static Future<Map<String, String>> getDeviceLabel() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;

      final manufacturer = info.manufacturer.trim();
      final model = info.model.trim();

      final name = manufacturer.isNotEmpty &&
              !model.toLowerCase().startsWith(
                    manufacturer.toLowerCase(),
                  )
          ? '$manufacturer $model'
          : model;

      return {
        'name': name.isEmpty ? 'هاتف Android' : name,
        'platform': 'android',
      };
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;

      final name = info.name.isNotEmpty ? info.name : info.model;

      return {
        'name': name.isEmpty ? 'iPhone' : name,
        'platform': 'ios',
      };
    }

    return {
      'name': 'جهاز غير معروف',
      'platform': 'unknown',
    };
  }

  /// Check whether this device is already linked to another user.
  ///
  /// Returns the UID of the owner if the device exists.
  /// Returns null if the device is not registered.
  static Future<String?> checkDeviceOwner(String deviceId) async {
    // Make sure the ID is safe before using it as a document ID.
    final safeDeviceId = deviceId
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .trim();

    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(safeDeviceId)
        .get();

    if (doc.exists) {
      return doc.data()?['uid'] as String?;
    }

    return null;
  }

  /// Link a device to a user.
  static Future<void> linkDeviceToUser({
    required String deviceId,
    required String uid,
    required String method,
  }) async {
    // Make sure the ID is safe before using it as a document ID.
    final safeDeviceId = deviceId
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .trim();

    await FirebaseFirestore.instance
        .collection('devices')
        .doc(safeDeviceId)
        .set({
      'uid': uid,
      'method': method,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Register the current device inside the user's devices collection.
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
        .set(
      {
        'deviceId': deviceId,
        'name': label['name'],
        'platform': label['platform'],
        'method': method,
        'lastActive': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Remove the device from the user's devices collection.
  static Future<void> signOutDevice({
    required String uid,
    required String deviceId,
  }) async {
    final safeDeviceId = deviceId
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .trim();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(safeDeviceId)
        .delete();
  }
}