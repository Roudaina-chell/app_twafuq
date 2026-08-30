// services/device_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class DeviceService {
  // خدمة باش نجيبو رقم يميز التلفون
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      // نجمعو شي معلومات باش يكون الرقم أكثر ثبات
      return '${info.id}_${info.fingerprint}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_device';
  }

  // نتحققو واش التلفون مربوط بحساب آخر
  // كيرجع null إلا التلفون فاضي (ماشي مستعمل)
  // كيرجع uid تاع الحساب الآخر إلا التلفون مستعمل
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

  // نربطو التلفون بالحساب الجديد بعد نجاح التسجيل
  static Future<void> linkDeviceToUser({
    required String deviceId,
    required String uid,
    required String method, // "email" wla "google"
  }) async {
    await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
      'uid': uid,
      'method': method,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
