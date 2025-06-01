import 'dart:async';

import 'package:project1/utils/log_processor.dart';
import 'package:project1/utils/logger_config.dart';

class SearchProcessor {
  static final SearchProcessor _instance = SearchProcessor._internal();
  factory SearchProcessor() => _instance;
  SearchProcessor._internal();

  // 현재 검색 작업 관리
  Completer<void>? _currentSearchOperation;

  // 작업 취소 플래그
  bool _cancelCurrentOperation = false;

  // 현재 실행 중인 검색 취소
  void cancelCurrentSearch() {
    _cancelCurrentOperation = true;
  }

  // 비동기 검색 실행 (무거운 작업 처리)
  Future<void> processSearch({
    required String query,
    String? previousQuery,
    required Function(String?) onQueryChanged,
    required Function() onBeforeSearch,
    required Function() onSearchComplete,
  }) async {
    // 현재 실행 중인 작업 취소
    cancelCurrentSearch();

    // 새 작업 설정
    _cancelCurrentOperation = false;
    _currentSearchOperation = Completer<void>();

    final isEmptyQuery = query.trim().isEmpty;

    // 변경이 없으면 작업 건너뛰기
    if (isEmptyQuery && previousQuery == null) {
      _currentSearchOperation?.complete();
      return;
    }

    // 사전 처리 콜백 호출
    onBeforeSearch();

    try {
      // 검색어 설정 (UI 스레드에서 빠르게 처리)
      onQueryChanged(isEmptyQuery ? null : query.trim());

      // 무거운 작업 실행 전 약간의 지연
      await Future.delayed(const Duration(milliseconds: 50));

      // 취소되었는지 확인
      if (_cancelCurrentOperation) {
        _currentSearchOperation?.complete();
        return;
      }

      // 필터 적용 전 캐시 정리 (별도 스레드)
      if (isEmptyQuery) {
        await LogCache.clearAsync();
      } else {
        // 관련 패턴만 제거하여 캐시 최적화
        await LogCache.removeByPatternAsync('activity_');
      }

      // 추가 지연으로 UI 응답성 유지
      await Future.delayed(const Duration(milliseconds: 50));

      // 검색 완료 콜백 (로그 초기화 등)
      onSearchComplete();
    } catch (e) {
      logger.e('검색 처리 오류: $e');
    } finally {
      // 작업 완료 표시
      if (!_currentSearchOperation!.isCompleted) {
        _currentSearchOperation?.complete();
      }
    }
  }
}
