import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceInfoService {
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = '';
    String osVersion = '';
    String appVersion = '1.0.0'; // 앱 버전 (필요 시 패키지에서 동적으로 가져올 수도 있음)

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = '${androidInfo.brand} ${androidInfo.model}';
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = '${iosInfo.name} ${iosInfo.model}';
      osVersion = 'iOS ${iosInfo.systemVersion}';
    }

    return {
      'deviceInfo': deviceName,
      'osVersion': osVersion,
      'appVersion': appVersion,
    };
  }
}
