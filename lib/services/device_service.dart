import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      return androidInfo.id;
    }

    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;

      return iosInfo.identifierForVendor ?? '';
    }

    throw UnsupportedError('Unsupported platform');
  }
}