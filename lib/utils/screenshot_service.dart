import 'dart:io';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/utils/logger_config.dart';

class ScreenshotService {
  static final ScreenshotService _instance = ScreenshotService._internal();
  factory ScreenshotService() => _instance;
  ScreenshotService._internal();

  /// 스크린샷을 캡처하고 갤러리에 저장합니다.
  ///
  /// [boundaryKey]: RepaintBoundary의 GlobalKey
  /// [fileName]: 저장할 파일명 (확장자 제외)
  /// [pixelRatio]: 이미지 품질 (기본값: 3.0)
  /// [imageQuality]: JPEG 품질 0-100 (PNG의 경우 무시됨)
  Future<ScreenshotResult> captureAndSave({
    required GlobalKey boundaryKey,
    required String fileName,
    double pixelRatio = 3.0,
    int imageQuality = 100,
  }) async {
    try {
      // 권한 확인 및 요청
      final permissionResult = await _requestPermission();
      if (!permissionResult.isGranted) {
        return ScreenshotResult(
          success: false,
          message: permissionResult.message,
          needsSettings: permissionResult.isPermanentlyDenied,
        );
      }

      // 스크린샷 캡처
      final captureResult = await _captureScreenshot(
        boundaryKey: boundaryKey,
        pixelRatio: pixelRatio,
      );

      if (!captureResult.success || captureResult.imageData == null) {
        return ScreenshotResult(
          success: false,
          message: captureResult.message,
        );
      }

      // 갤러리에 저장
      final saveResult = await _saveToGallery(
        imageData: captureResult.imageData!,
        fileName: fileName,
        quality: imageQuality,
      );

      // 성공 시 햅틱 피드백
      if (saveResult.success && (Platform.isIOS || Platform.isAndroid)) {
        HapticFeedback.mediumImpact();
      }

      return saveResult;
    } catch (e) {
      logger.e('ScreenshotService error: $e');
      return ScreenshotResult(
        success: false,
        message: '저장 중 오류가 발생했습니다.',
      );
    }
  }

  /// 권한 상태를 확인합니다.
  Future<bool> checkPermissionStatus() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.photos.isGranted;
      } else if (androidInfo.version.sdkInt >= 29) {
        return true; // 스코프 스토리지
      } else {
        return await Permission.storage.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }
    return false;
  }

  /// 권한을 요청합니다.
  Future<_PermissionResult> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13 이상: 먼저 저장을 시도
        // ImageGallerySaver는 Scoped Storage를 사용하므로
        // 대부분의 경우 권한 없이도 작동
        return await _requestAndroidPhotosPermission();
      } else if (androidInfo.version.sdkInt >= 29) {
        // Android 10-12: 권한 불필요
        return _PermissionResult(isGranted: true);
      } else {
        // Android 9 이하

        return await _requestAndroidStoragePermission();
      }
    } else if (Platform.isIOS) {
      return _PermissionResult(isGranted: true);
    }

    return _PermissionResult(
      isGranted: false,
      message: '지원하지 않는 플랫폼입니다.',
    );
  }

  Future<_PermissionResult> _requestAndroidPhotosPermission() async {
    try {
      final status = await Permission.photos.status;

      if (status.isGranted) {
        return _PermissionResult(isGranted: true);
      }

      if (status.isDenied) {
        // 권한 요청 다이얼로그 표시
        final result = await Permission.photos.request();

        if (result.isGranted) {
          return _PermissionResult(isGranted: true);
        } else if (result.isPermanentlyDenied) {
          return _PermissionResult(
            isGranted: false,
            isPermanentlyDenied: true,
            message: '사진 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
          );
        } else {
          return _PermissionResult(
            isGranted: false,
            message: '사진첩 저장을 위해 권한이 필요합니다.',
          );
        }
      }

      if (status.isPermanentlyDenied) {
        return _PermissionResult(
          isGranted: false,
          isPermanentlyDenied: true,
          message: '사진 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
        );
      }

      // 상태를 판단할 수 없는 경우
      return _PermissionResult(
        isGranted: false,
        message: '권한 상태를 확인할 수 없습니다.',
      );
    } catch (e) {
      logger.e('Permission error: $e');
      return _PermissionResult(
        isGranted: false,
        message: '권한 요청 중 오류가 발생했습니다.',
      );
    }
  }

  Future<_PermissionResult> _requestAndroidStoragePermission() async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return _PermissionResult(isGranted: true);
    }

    if (status.isDenied || status.isRestricted) {
      final result = await Permission.storage.request();

      if (result.isGranted) {
        return _PermissionResult(isGranted: true);
      } else if (result.isPermanentlyDenied) {
        return _PermissionResult(
          isGranted: false,
          isPermanentlyDenied: true,
          message: '저장소 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
        );
      } else {
        return _PermissionResult(
          isGranted: false,
          message: '저장소 접근 권한이 필요합니다.',
        );
      }
    }

    if (status.isPermanentlyDenied) {
      return _PermissionResult(
        isGranted: false,
        isPermanentlyDenied: true,
        message: '저장소 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
      );
    }

    return _PermissionResult(
      isGranted: false,
      message: '권한을 확인할 수 없습니다.',
    );
  }

  Future<_CaptureResult> _captureScreenshot({
    required GlobalKey boundaryKey,
    required double pixelRatio,
  }) async {
    try {
      final RenderRepaintBoundary? boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        return _CaptureResult(
          success: false,
          message: '화면을 캡처할 수 없습니다.',
        );
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return _CaptureResult(
          success: false,
          message: '스크린샷 생성에 실패했습니다.',
        );
      }

      return _CaptureResult(
        success: true,
        message: '스크린샷을 저장했습니다.',
        imageData: byteData.buffer.asUint8List(),
      );
    } catch (e) {
      logger.e('Screenshot capture error: $e');
      return _CaptureResult(
        success: false,
        message: '스크린샷 캡처 중 오류가 발생했습니다.',
      );
    }
  }

  Future<ScreenshotResult> _saveToGallery({
    required Uint8List imageData,
    required String fileName,
    required int quality,
  }) async {
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        imageData,
        name: fileName,
        quality: quality,
      );

      if (result['isSuccess'] == true || result['filePath'] != null) {
        return ScreenshotResult(
          success: true,
          message: '사진첩에 저장되었습니다! 📸',
          filePath: result['filePath'],
        );
      } else {
        return ScreenshotResult(
          success: false,
          message: '저장에 실패했습니다: ${result['errorMessage'] ?? '알 수 없는 오류'}',
        );
      }
    } catch (e) {
      logger.e('Gallery save error: $e');
      return ScreenshotResult(
        success: false,
        message: '갤러리 저장 중 오류가 발생했습니다.',
      );
    }
  }
}

// 결과 클래스들
class ScreenshotResult {
  final bool success;
  final String message;
  final String? filePath;
  final bool needsSettings;

  ScreenshotResult({
    required this.success,
    required this.message,
    this.filePath,
    this.needsSettings = false,
  });
}

class _PermissionResult {
  final bool isGranted;
  final bool isPermanentlyDenied;
  final String message;

  _PermissionResult({
    required this.isGranted,
    this.isPermanentlyDenied = false,
    this.message = '',
  });
}

class _CaptureResult {
  final bool success;
  final String message;
  final Uint8List? imageData;

  _CaptureResult({
    required this.success,
    required this.message,
    this.imageData,
  });
}
