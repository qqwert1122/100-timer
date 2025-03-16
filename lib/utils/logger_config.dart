// logger_config.dart 파일 생성
import 'package:logger/logger.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late Logger logger;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal() {
    logger = Logger(printer: SimplePrinter());
  }
}

// 편의를 위한 전역 인스턴스
final logger = AppLogger().logger;
