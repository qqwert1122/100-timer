import 'package:project1/utils/device_info_service.dart';

class ErrorService {
  final DeviceInfoService _deviceInfoService;

  ErrorService({
    required DeviceInfoService deviceInfoService,
  }) : _deviceInfoService = deviceInfoService;

  /// DB 의존성 제거: ErrorService에서는 에러정보를 반환만 한다.

  Future<Map<String, dynamic>> createError({
    required String errorCode,
    required String errorMessage,
    String? errorAction,
    String? severityLevel,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final deviceInfo = await _deviceInfoService.getDeviceInfo();

    return {
      'created_at': now,
      'error_code': errorCode,
      'error_message': errorMessage,
      'error_action': errorAction ?? '',
      'severity_level': severityLevel ?? 'low',
      'device_info': deviceInfo['deviceInfo'],
      'app_version': deviceInfo['appVersion'],
      'os_version': deviceInfo['osVersion'],
    };
  }
}
