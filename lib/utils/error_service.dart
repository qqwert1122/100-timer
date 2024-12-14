import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/device_info_service.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/device_info_service.dart';

class ErrorService {
  final AuthProvider _authProvider;
  final DeviceInfoService _deviceInfoService;

  ErrorService({
    required AuthProvider authProvider,
    required DeviceInfoService deviceInfoService,
  })  : _authProvider = authProvider,
        _deviceInfoService = deviceInfoService;

  /// DB 의존성 제거: ErrorService에서는 에러정보를 반환만 한다.

  Future<Map<String, dynamic>> createError({
    required String errorCode,
    required String errorMessage,
    String? errorAction,
    String? severityLevel,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final uid = _authProvider.user?.uid;

    final deviceInfo = await _deviceInfoService.getDeviceInfo();

    return {
      'uid': uid,
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
