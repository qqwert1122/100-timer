import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/models/log_filter_type.dart';
import 'package:project1/models/paging_mode.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/activity_logs/widgets/activity_log_bottom.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/log_filter_service.dart';
import 'package:project1/utils/log_processor.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/search_processor.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/widgets/date_range_picker_bottom_sheet.dart';
import 'package:project1/widgets/edit_activity_log_modal.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shimmer/shimmer.dart';
import 'package:showcaseview/showcaseview.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  static final GlobalKey logKey = GlobalKey(debugLabel: 'history');

  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> with AutomaticKeepAliveClientMixin {
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  late final LogFilterService _filterService;

  List<Map<String, dynamic>> groupedLogs = []; // ui에 표시될 logs
  final List<String> daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
  String selectedDay = '';
  Map<String, int> dayToIndexMap = {}; // 월,화,수,목,금,토,일 라벨이 붙을 위치를 저장

  // scroll 이벤트 관련
  Timer? _scrollDebounce;
  static const int _scrollDebounceMs = 200; // 스크롤 이벤트 처리 간격 (밀리초)

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool isProgrammaticScroll = false;

  int _currentWeekOffset = 0; // byWeek 전용 - type.all, type.activity
  int _currentItemOffset = 0; // byCount 전용 - type.dateRange, type.combined
  static const int _pageSize = 20; // byCount 조회 사이즈

  bool _isLoadingMore = false; // 중복 실행 방지 flag
  bool _hasMoreData = true; // 추가 load flag
  bool _loadingError = false;
  static const int _loadMoreThreshold = 3; // 스크롤 임계치 설정: 리스트 하단에서 몇 개 남았을 때 로드할지 결정
  static const int _maxStoredWeeks = 12; // 메모리에 최대 유지할 주차 수 (예, 12주치 데이터)

  DateTime? _earliestSessionDate;

  // 검색 조건 설정
  String? _selectedActivityName;
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _activities = []; // 활동 목록 저장
  bool get _isFilterApplied => _selectedActivityName != null || _selectedDateRange != null; // 필터 적용 여부 확인
  bool get _isActivityFiltered => _selectedActivityName != null; // 필터 적용 여부 확인
  bool get isDateFiltered => _selectedDateRange != null; // 필터 적용 여부 확인
  ActivityLogFilter _currentFilter = ActivityLogFilter.all();

  // 활동명 검색 기능
  TextEditingController searchController = TextEditingController();
  late FocusNode _searchFocusNode;
  Timer? _debounce;

  // log tile 최적화
  final Map<String, bool> _loadedLogItems = {};
  bool _isRenderOptimized = false; // 렌더링 최적화 플래그

  // Onboarding
  bool _needShowOnboarding = false; // Onboarding flag
  final _logKey = ActivityLogPage.logKey; // Onboarding GlobalKey

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _filterService = LogFilterService(_statsProvider, _dbService);

    _initializeBasicComponents();
    _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isRenderOptimized = true;
      });
      _preloadVisibleItems();
    });
  }

  void _initializeBasicComponents() {
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _itemPositionsListener.itemPositions.addListener(_onScroll);

    // 최초 1회만 온보딩
    _needShowOnboarding = !PrefsService().getOnboarding('history');
    if (_needShowOnboarding) {
      // 지연 실행하여 초기화 작업과 UI 렌더링 분리
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([_logKey]);
        }
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // 가장 오래된 세션의 날짜 조회
      _earliestSessionDate = await _dbService.getEarliestSessionDate();

      // UI가 준비되면 로그 로드 시작
      if (mounted) {
        await _initializeLogs(isInitialLoad: true);
      }
    } catch (e) {
      logger.e('초기 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _loadingError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // 타이머 해제
    _scrollDebounce?.cancel();
    _debounce?.cancel();

    // 리스너 제거
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _searchFocusNode.removeListener(() {});
    _searchFocusNode.dispose();

    // 컨트롤러 해제
    searchController.dispose();

    // 검색 프로세서 취소
    _searchProcessor.cancelCurrentSearch();

    // 캐시 최적화
    LogCache.clear(); // 메모리 절약을 위해 페이지 종료 시 캐시 비우기
    _loadedLogItems.clear();

    isProgrammaticScroll = false;
    super.dispose();
  }

  void _preloadVisibleItems() {
    if (!mounted || groupedLogs.isEmpty) return;

    // 초기에는 첫 화면에 보이는 아이템만 로드
    int loadedCount = 0;

    // 첫 배치 로드 (지연 없이)
    for (int groupIndex = 0; groupIndex < min(2, groupedLogs.length); groupIndex++) {
      final logs = groupedLogs[groupIndex]['logs'] as List<Map<String, dynamic>>;
      for (int i = 0; i < min(5, logs.length); i++) {
        _loadedLogItems[logs[i]['session_id']] = true;
        loadedCount++;
      }
    }

    if (mounted) setState(() {});

    // 나머지 점진적 로드
    _loadRemainingItemsBatched();
  }

// 배치 방식으로 나머지 항목 로드
  void _loadRemainingItemsBatched() {
    const int batchSize = 5; // 한 번에 로드할 항목 수
    const int batchDelay = 150; // 배치 간 딜레이 (밀리초)

    List<String> pendingItems = [];

    // 모든 아이템 ID 수집
    for (final group in groupedLogs) {
      final logs = group['logs'] as List<Map<String, dynamic>>;
      for (final log in logs) {
        final sessionId = log['session_id'];
        if (!_loadedLogItems.containsKey(sessionId)) {
          pendingItems.add(sessionId);
        }
      }
    }

    // 배치 처리 함수
    void processBatch(int startIndex) {
      if (!mounted) return;

      final endIndex = min(startIndex + batchSize, pendingItems.length);
      if (startIndex >= endIndex) return;

      // 현재 배치 처리
      setState(() {
        for (int i = startIndex; i < endIndex; i++) {
          _loadedLogItems[pendingItems[i]] = true;
        }
      });

      // 다음 배치 예약
      if (endIndex < pendingItems.length) {
        Future.delayed(Duration(milliseconds: batchDelay), () {
          processBatch(endIndex);
        });
      }
    }

    // 첫 배치 시작
    if (pendingItems.isNotEmpty) {
      Future.delayed(Duration(milliseconds: batchDelay), () {
        processBatch(0);
      });
    }
  }

  void refreshCurrentFilter() {
    logger.d('필터 타입 변경: ${_currentFilter.type}');

    final hasActivity = _selectedActivityName != null && _selectedActivityName!.isNotEmpty;
    final hasDateRange = _selectedDateRange != null;

    if (hasActivity && hasDateRange) {
      _currentFilter = ActivityLogFilter.combined(_selectedActivityName!, _selectedDateRange!);
    } else if (hasDateRange) {
      _currentFilter = ActivityLogFilter.dateRange(_selectedDateRange!);
    } else if (hasActivity) {
      _currentFilter = ActivityLogFilter.activity(_selectedActivityName!);
    } else {
      _currentFilter = ActivityLogFilter.all();
    }
  }

  Future<void> _initializeLogs({bool isInitialLoad = false}) async {
    logger.d('_initializeLogs 호출됨(isInitialLoad: $isInitialLoad), 현재 필터: ${_currentFilter.type}');

    if (_isLoadingMore && !isInitialLoad) {
      return;
    } // 중복 방지

    refreshCurrentFilter(); // 필터 확정

    setState(() {
      if (isInitialLoad) {
        _isLoadingMore = true;
      }
    });
    try {
      final mode = getPagingMode(_currentFilter.type);

      // 무거운 작업을 비동기로 실행
      await Future(() async {
        if (mode == PagingMode.byWeek) {
          await _loadByWeek(isInitialLoad: isInitialLoad);
        } else {
          await _loadByCount(isInitialLoad: isInitialLoad);
        }
      });
    } catch (e) {
      logger.e('데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _loadingError = true;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadByWeek({required bool isInitialLoad}) async {
    if (_isLoadingMore && !isInitialLoad) return;

    if (!isInitialLoad) {
      setState(() {
        _isLoadingMore = true;
        _loadingError = false;
      });
    }

    try {
      if (!isInitialLoad) {
        await Future.delayed(const Duration(milliseconds: 16)); // 프레임 간격
      }

      // 오프셋 초기화
      if (isInitialLoad) {
        _currentWeekOffset = 0;
        groupedLogs.clear();
        dayToIndexMap.clear();
      } else {
        _currentWeekOffset -= 1; // 과거 주차 이동
      }

      // 메모리 제한 체크
      if (!isInitialLoad && groupedLogs.length >= _maxStoredWeeks * 7) {
        logger.d('메모리 체크 진입');
        final positions = _itemPositionsListener.itemPositions.value;
        if (positions.isNotEmpty) {
          int maxIdx = positions.first.index;
          for (var position in positions) {
            if (position.index > maxIdx) maxIdx = position.index;
          }
          if (maxIdx < groupedLogs.length - _loadMoreThreshold) {
            logger.d('사용자가 아직 스크롤을 다하지 않음');
            setState(() => _isLoadingMore = false);
            return; // 더 내려가지 않으면 로드 중단
          }
        }
      }

      if (!isInitialLoad && _earliestSessionDate != null) {
        // 현재 주차의 시작 날짜 계산
        final now = DateTime.now();
        DateTime currentWeekStart = now.subtract(Duration(days: (-_currentWeekOffset) * 7 + now.weekday - 1));
        currentWeekStart = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

        DateTime earliestSessionWeekStart = _earliestSessionDate!.subtract(Duration(days: _earliestSessionDate!.weekday - 1));
        earliestSessionWeekStart = DateTime(earliestSessionWeekStart.year, earliestSessionWeekStart.month, earliestSessionWeekStart.day);

        // 현재 주차 시작이 가장 오래된 세션보다 이전인지 확인
        if (currentWeekStart.isBefore(earliestSessionWeekStart)) {
          setState(() {
            _hasMoreData = false;
            _isLoadingMore = false;
          });
          return; // 더 이상 데이터가 없으므로 로드 중단
        }
      }

      final String cacheKey = 'week_${_currentFilter.type}_$_currentWeekOffset';
      List<Map<String, dynamic>> grouped;

      final cachedData = LogCache.retrieve(cacheKey);
      if (cachedData != null) {
        grouped = cachedData; // 캐시된 데이터 사용
      } else {
        // 로딩 인디케이터 표시
        if (!isInitialLoad && mounted) {
          setState(() {}); // 필요한 경우에만 setState 호출
        }

        // 데이터 로드 전에 불필요한 연산 지연
        final logData = await Future(() async {
          // 데이터베이스 쿼리를 별도 격리
          final result = await _filterService.getLogsForFilter(_currentFilter, _currentWeekOffset);
          // UI 응답성을 위한 짧은 지연
          await Future.delayed(const Duration(milliseconds: 16));
          return result;
        });

        // Empty check
        if (logData.isEmpty) {
          grouped = [];
        } else {
          // compute 함수를 사용하여 무거운 연산 분리
          grouped = await compute(computeGroupLogs, logData);

          // 캐시에 저장 (빈 데이터는 저장하지 않음)
          if (grouped.isNotEmpty) {
            LogCache.store(cacheKey, grouped);
          }
        }
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1));
        _applyGroupedResult(
          grouped: grouped,
          isInitialLoad: isInitialLoad,
        );
      }

      _hasMoreData = true;
      logger.d('loadByWeek 종료');
    } catch (e, s) {
      logger.e('e : $e');
      _loadingError = true;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadByCount({required bool isInitialLoad}) async {
    if (_isLoadingMore && !isInitialLoad) return;
    setState(() {
      _isLoadingMore = true;
      _loadingError = false;
    });

    try {
      /* 1) 초기화 */
      if (isInitialLoad) {
        _currentItemOffset = 0;
        groupedLogs.clear();
        dayToIndexMap.clear();
      }
      final String cacheKey = 'count_${_currentFilter.type}_all';
      List<Map<String, dynamic>> groupedAll;

      if (LogCache.containsKey(cacheKey) && LogCache.retrieve(cacheKey)!.isNotEmpty) {
        // 캐시된 데이터 사용

        groupedAll = LogCache.retrieve(cacheKey)!;
      } else {
        // 전체 범위 한 번만 쿼리 후 백그라운드에서 처리
        final allLogs = await _filterService.getLogsForFilter(_currentFilter, 0);
        groupedAll = await compute(computeGroupLogs, allLogs);

        // 캐시에 저장
        LogCache.store(cacheKey, groupedAll);
      }

      final start = _currentItemOffset;
      final end = (_currentItemOffset + _pageSize).clamp(0, groupedAll.length);
      final sliced = groupedAll.sublist(start, end);

      if (mounted) {
        _applyGroupedResult(grouped: sliced, isInitialLoad: isInitialLoad);
      }

      _currentItemOffset = end;
      _hasMoreData = _currentItemOffset < groupedAll.length;
    } catch (e) {
      logger.e('e: $e');
      _loadingError = true;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _applyFilter({
    required bool clearActivityName,
    required bool clearDateRange,
    bool isRefreshNeeded = true,
  }) async {
    // 상태 변경 전 현재 필터 저장
    final previousFilter = _currentFilter;

    // UI 즉시 업데이트 (필터 상태만)
    setState(() {
      if (clearActivityName) _selectedActivityName = null;
      if (clearDateRange) _selectedDateRange = null;

      _hasMoreData = true;
    });

    try {
      // 필터 변경 시 캐시 및 데이터 처리 최적화
      bool majorFilterChange = false;

      // 필터 타입 체크로 주요 변경 감지
      refreshCurrentFilter();
      if (previousFilter.type != _currentFilter.type) {
        majorFilterChange = true;

        // 타입 변경 시 오프셋 리셋 (UI 스레드 빠른 처리)
        setState(() {
          _currentWeekOffset = 0;
          _currentItemOffset = 0;
        });
      }

      // 필터 변경이 작으면 일부 캐시만 제거 (패턴 기반)
      if (majorFilterChange) {
        // 비동기 캐시 클리어로 UI 블로킹 방지
        await LogCache.clearAsync();
      } else {
        // 관련 패턴 캐시만 제거 (더 효율적)
        if (clearActivityName) {
          await LogCache.removeByPatternAsync('activity_');
        }
        if (clearDateRange) {
          await LogCache.removeByPatternAsync('dateRange_');
        }
      }

      // 프레임 간격만큼 지연으로 UI 응답성 확보
      await Future.delayed(const Duration(milliseconds: 16));

      // 필요한 경우만 로그 새로고침
      if (isRefreshNeeded && mounted) {
        await _refreshLogs();
      }
    } catch (e) {
      print('필터 적용 오류: $e');
      // 오류 알림 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('필터 적용 중 오류가 발생했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _applyGroupedResult({
    required List<Map<String, dynamic>> grouped,
    required bool isInitialLoad,
  }) {
    final positions = _itemPositionsListener.itemPositions.value;
    final int visibleIndex = positions.isNotEmpty ? positions.map((e) => e.index).reduce(min) : 0;
    final String? visibleDate = visibleIndex < groupedLogs.length ? groupedLogs[visibleIndex]['date'] : null;

    setState(() {
      if (isInitialLoad) {
        groupedLogs = grouped;
      } else {
        groupedLogs.addAll(grouped);
      }
      dayToIndexMap = _calculateDayToIndexMap();
      _isLoadingMore = false; // 로딩 상태 업데이트를 여기서 통합
    });

    // 지연된 스크롤 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isInitialLoad && groupedLogs.isNotEmpty) {
        // 필터 변경으로 인한 새로고침인 경우 최상단으로
        if (_isFilterApplied) {
          _scrollController.jumpTo(index: 0);
        } else {
          // 일반 새로고침은 선택된 요일 위치로
          final idx = dayToIndexMap[selectedDay] ?? 0;
          _scrollToIndex(idx);
        }
      } else if (positions.isNotEmpty && _scrollController.isAttached) {
        _scrollController.jumpTo(index: positions.first.index);
      }
      _manageMemoryUsage(visibleDate);
    });
  }

  void _manageMemoryUsage(String? visibleDate) {
    if (groupedLogs.length <= _maxStoredWeeks * 7) return;

    Future.microtask(() {
      if (!mounted) return;

      final removeCount = groupedLogs.length - _maxStoredWeeks * 7;
      final newGroupedLogs = groupedLogs.sublist(removeCount);

      setState(() {
        groupedLogs = newGroupedLogs;
        dayToIndexMap = _calculateDayToIndexMap();
      });

      // 원래 보던 날짜 위치로 스크롤 복원
      if (visibleDate != null) {
        final newIdx = groupedLogs.indexWhere((g) => g['date'] == visibleDate);
        if (newIdx >= 0 && mounted && _scrollController.isAttached) {
          isProgrammaticScroll = true;
          _scrollController.jumpTo(index: newIdx);

          // 플래그 해제 타이머
          Timer(const Duration(milliseconds: 100), () {
            if (mounted) setState(() => isProgrammaticScroll = false);
          });
        }
      }
    });
  }

  void _onScroll() {
    if (isProgrammaticScroll || _itemPositionsListener.itemPositions.value.isEmpty) return;
    // 이미 활성화된 디바운스가 있다면 무시
    if (_scrollDebounce?.isActive ?? false) return;

    // 디바운스 적용 - 하나의 람다로 모든 스크롤 작업 처리
    _scrollDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final positions = _itemPositionsListener.itemPositions.value;
      // 요일 업데이트와 데이터 로드 체크 둘 다 수행
      _updateCurrentDay(positions);
      _checkIfNeedMoreData(positions);
    });
  }

// 현재 표시된 요일 업데이트
  void _updateCurrentDay(Iterable<ItemPosition> positions) {
    if (positions.isEmpty) return;

    const screenMiddle = 0.5;
    double closestDistance = double.infinity;
    ItemPosition? closestPosition;

    // reduce 사용을 피하여 루프로 구현 (성능 개선)
    for (final position in positions) {
      final itemMiddle = (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
      final distance = (itemMiddle - screenMiddle).abs();

      if (distance < closestDistance) {
        closestDistance = distance;
        closestPosition = position;
      }
    }

    if (closestPosition == null) return;

    final index = closestPosition.index;
    if (index >= groupedLogs.length) return;

    final date = groupedLogs[index]['date'];
    final dayOfWeek = _getDayOfWeek(date);

    // 불필요한 상태 업데이트 방지
    if (dayOfWeek != selectedDay) {
      setState(() {
        selectedDay = dayOfWeek;
      });
    }
  }

// 추가 데이터 로드 필요 여부 확인
  void _checkIfNeedMoreData(Iterable<ItemPosition> positions) {
    if (_isLoadingMore || !_hasMoreData || positions.isEmpty) return;
    int maxIndex = positions.first.index;
    for (final pos in positions) {
      if (pos.index > maxIndex) {
        maxIndex = pos.index;
      }
    }

    final shouldLoadMore = maxIndex >= groupedLogs.length - _loadMoreThreshold;

    if (shouldLoadMore) {
      // 비동기로 지연 실행하여 UI 응답성 유지
      Future.microtask(() {
        if (mounted) _loadMoreData();
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;
    final mode = getPagingMode(_currentFilter.type);

    if (mode == PagingMode.byWeek) {
      await _loadByWeek(isInitialLoad: false);
    } else {
      await _loadByCount(isInitialLoad: false);
    }
  }

  Future<void> _refreshLogs() async {
    // 현재 필터 상태 저장
    final bool wasFilterApplied = _isFilterApplied;
    logger.d('_refreshLogs 호출됨, 현재 필터: ${_currentFilter.type}');

    setState(() {
      _isLoadingMore = false;
      _hasMoreData = true;
      _loadingError = false;
      _loadedLogItems.clear();
    });

    try {
      // 필터 상태 변경 시 필요한 작업만 수행
      if (wasFilterApplied && !_isFilterApplied) {
        // 비동기 처리로 빠르게 UI 업데이트
        setState(() => _currentWeekOffset = 0);

        // 캐시 일부 또는 전체 초기화 (상황에 따라)
        await LogCache.removeByPatternAsync('week_');
      }

      // 작은 지연으로 UI 응답성 유지
      await Future.delayed(const Duration(milliseconds: 16));

      if (mounted) {
        await _initializeLogs(isInitialLoad: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.isAttached) {
            _scrollController.jumpTo(index: 0);
          }
        });
      }
    } catch (e) {
      print('새로고침 오류: $e');
      if (mounted) {
        setState(() => _loadingError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데이터를 불러오는 중 오류가 발생했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _scrollToIndex(int index) {
    if (_scrollController.isAttached && index < groupedLogs.length) {
      setState(() {
        isProgrammaticScroll = true;
      });
      _scrollController
          .scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        setState(() {
          isProgrammaticScroll = false;
        });
        logger.d('스크롤 완료, 현재 index: $index');
      });
    }
  }

  Map<String, int> _calculateDayToIndexMap() {
    final Map<String, int> indexMap = {};

    // 일괄 처리 최적화: 미리 계산된 캐시를 활용할 수 있는 방안 모색
    int lastProcessedIndex = 0;
    for (int i = 0; i < groupedLogs.length; i++) {
      // 첫 항목만 찾아내면 되므로 중복 처리 방지
      if (i < lastProcessedIndex) continue;

      String date = groupedLogs[i]['date'];
      String dayOfWeek = _getDayOfWeek(date);

      if (!indexMap.containsKey(dayOfWeek)) {
        indexMap[dayOfWeek] = i;
        lastProcessedIndex = i;
      }
    }

    return indexMap;
  }

  final Map<String, String> _dayOfWeekCache = {};

  String _getDayOfWeek(String date) {
    if (_dayOfWeekCache.containsKey(date)) {
      return _dayOfWeekCache[date]!;
    }

    // 없으면 계산하고 캐싱
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime dateTime = formatter.parse(date);
    int weekday = dateTime.weekday;
    int index = (weekday + 6) % 7;
    final result = daysOfWeek[index];

    // 캐시에 저장 (캐시 크기 제한 필요할 수 있음)
    if (_dayOfWeekCache.length > 100) {
      _dayOfWeekCache.clear(); // 간단히 주기적으로 캐시 비우기
    }
    _dayOfWeekCache[date] = result;

    return result;
  }

  final Map<String, String> _formattedDateCache = {};

  String formatDate(String dateTimeString) {
    if (_formattedDateCache.containsKey(dateTimeString)) {
      return _formattedDateCache[dateTimeString]!;
    }

    final dateTime = DateTime.parse(dateTimeString).toLocal();
    final now = DateTime.now();
    final isSameYear = dateTime.year == now.year;
    final timeFormatter = DateFormat('a h시 mm분');
    final dateFormatter = isSameYear ? DateFormat('M월 d일') : DateFormat('yyyy년 M월 d일');
    String formattedTime = timeFormatter.format(dateTime).replaceAll('AM', '오전').replaceAll('PM', '오후');

    final result = '${dateFormatter.format(dateTime)} $formattedTime';

    // 캐시에 저장 (캐시 크기 제한 필요할 수 있음)
    if (_formattedDateCache.length > 500) {
      _formattedDateCache.clear();
    }
    _formattedDateCache[dateTimeString] = result;

    return result;
  }

  String formatTime(int? seconds) {
    if (seconds == null || seconds == 0) return '-';
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    String formattedTime = '';
    if (hours > 0) formattedTime += '$hours시간';
    if (minutes > 0) formattedTime += ' $minutes분';
    if (remainingSeconds > 0) formattedTime += ' $remainingSeconds초';
    return formattedTime.trim();
  }

  void _onDateRangeSelected(DateTimeRange? dateRange) async {
    if (dateRange == null) return;

    logger.d('날짜 범위 선택: $dateRange, 현재 활동명: $_selectedActivityName');
    try {
      // 유효성 검사 (빠른 처리)
      if (dateRange.start.isAfter(dateRange.end)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효하지 않은 날짜 범위입니다.')),
        );
        return;
      }

      if (dateRange.end.difference(dateRange.start).inDays > 365) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('날짜 범위가 너무 큽니다. 1년 이내로 선택해주세요.')),
        );
        return;
      }

      // UI 즉시 업데이트 (날짜 범위만)
      setState(() {
        _selectedDateRange = dateRange;
        _isLoadingMore = true; // 로딩 표시
        selectedDay = '';
      });

      // 별도 비동기 작업으로 캐시 및 필터 처리
      await Future(() async {
        await LogCache.removeByPatternAsync('dateRange_'); // 관련 캐시만 제거
        await Future.delayed(const Duration(milliseconds: 16)); // 다음 프레임까지 대기
        refreshCurrentFilter(); // 필터 갱신

        // 로그 새로고침 (비동기)
        if (mounted) {
          await _refreshLogs();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.isAttached) {
              _scrollController.jumpTo(index: 0);
            }
          });
        }
      });
    } catch (e) {
      print('날짜 범위 적용 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('날짜 범위 적용 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  void _clearFilters() async {
    _searchProcessor.cancelCurrentSearch();

    setState(() {
      _isLoadingMore = true; // 로딩 표시
      selectedDay = '';
    });
    await _applyFilter(clearActivityName: true, clearDateRange: true, isRefreshNeeded: true);

    // 검색 필드 초기화
    if (mounted) {
      setState(() {
        searchController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.isAttached) {
          _scrollController.jumpTo(index: 0);
        }
      });
    }
  }

  int _getTotalLogCount() {
    int total = 0;
    for (var group in groupedLogs) {
      total += (group['logs'] as List).length;
    }
    return total;
  }

  Future<void> _editActivityLog(String sessionId) async {
    final updatedLog = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => EditActivityLogModal(
        sessionId: sessionId,
      ),
    );

    if (updatedLog != null) {
      _updateSingleLogItem(sessionId, updatedLog);
    }
  }

  void _updateSingleLogItem(String sessionId, Map<String, dynamic> updatedLog) {
    setState(() {
      // 1. UI 데이터 업데이트 (groupedLogs)
      bool found = false;

      for (var i = 0; i < groupedLogs.length; i++) {
        final logs = groupedLogs[i]['logs'] as List<Map<String, dynamic>>;
        final logIndex = logs.indexWhere((log) => log['session_id'] == sessionId);

        if (logIndex >= 0) {
          found = true;

          // 날짜 확인
          final oldDate = groupedLogs[i]['date'] as String;
          final newDateStr = updatedLog['start_time'].substring(0, 10);

          if (oldDate == newDateStr) {
            // 같은 날짜 그룹 내 업데이트
            logs[logIndex] = updatedLog;
          } else {
            // 날짜 변경됨 - 항목 이동 필요
            logs.removeAt(logIndex);

            // 기존 그룹이 비었으면 제거
            if (logs.isEmpty) {
              groupedLogs.removeAt(i);
            }

            // 새 날짜 그룹 찾기
            int newGroupIndex = groupedLogs.indexWhere((g) => g['date'] == newDateStr);

            if (newGroupIndex >= 0) {
              // 기존 그룹에 추가
              (groupedLogs[newGroupIndex]['logs'] as List<Map<String, dynamic>>).add(updatedLog);
              // 시간순 정렬
              (groupedLogs[newGroupIndex]['logs'] as List<Map<String, dynamic>>)
                  .sort((a, b) => (b['start_time'] as String).compareTo(a['start_time'] as String));
            } else {
              // 새 그룹 생성
              groupedLogs.add({
                'date': newDateStr,
                'logs': [updatedLog]
              });

              // 날짜순 정렬
              groupedLogs.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
            }

            // 요일 인덱스 맵 업데이트
            dayToIndexMap = _calculateDayToIndexMap();
          }
          break;
        }
      }

      // 2. 캐시 업데이트
      if (found) {
        LogCache.updateLogInCache(sessionId, updatedLog);
      }
    });
  }

  Future<void> _deleteLog(String sessionId) async {
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete) {
      try {
        await _dbService.deleteSession(sessionId);
        _removeSingleLogItem(sessionId);
        Fluttertoast.showToast(
          msg: "로그가 삭제되었습니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
      } catch (e) {
        debugPrint('로그 삭제 중 오류 발생: $e');
        Fluttertoast.showToast(
          msg: "로그 삭제 중 오류가 발생했습니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
      }
    }
  }

  void _removeSingleLogItem(String sessionId) {
    setState(() {
      // 1. UI 데이터에서 제거
      for (var i = 0; i < groupedLogs.length; i++) {
        final logs = groupedLogs[i]['logs'] as List<Map<String, dynamic>>;
        final originalLength = logs.length;

        logs.removeWhere((log) => log['session_id'] == sessionId);

        // 항목이 제거되었는지 확인
        if (logs.length < originalLength) {
          // 그룹이 비어있으면 제거
          if (logs.isEmpty) {
            groupedLogs.removeAt(i);
            // 요일 인덱스 맵 업데이트
            dayToIndexMap = _calculateDayToIndexMap();
          }
          break;
        }
      }

      // 2. 캐시에서 제거
      LogCache.removeLogFromCache(sessionId);
    });
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.background(context),
              title: Text(
                '정말 삭제하시겠습니까?',
                style: AppTextStyles.getTitle(context).copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'neo',
                ),
              ),
              content: const Text('활동 기록을 삭제하면 복구할 수 없습니다.'),
              actions: <Widget>[
                TextButton(
                  child: Text('취소',
                      style: AppTextStyles.getBody(context).copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w900,
                      )),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    '삭제',
                    style: AppTextStyles.getBody(context).copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'neo',
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildDayButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(daysOfWeek.length, (index) {
          final isSelected = daysOfWeek[index] == selectedDay;
          return TextButton(
            onPressed: dayToIndexMap.containsKey(daysOfWeek[index])
                ? () {
                    setState(() {
                      selectedDay = daysOfWeek[index];
                    });
                    _scrollToIndex(dayToIndexMap[selectedDay]!);
                  }
                : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 0),
            ),
            child: Container(
              padding: context.paddingHorizXS,
              decoration: isSelected ? const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent) : null,
              child: Text(
                daysOfWeek[index],
                style: AppTextStyles.getBody(context).copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary(context),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  final _searchProcessor = SearchProcessor();

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel(); // 디바운스가 있다면 취소

    _debounce = Timer(const Duration(milliseconds: 600), () {
      // 별도의 검색 프로세서로 무거운 작업 처리
      _searchProcessor.processSearch(
          query: query,
          previousQuery: _selectedActivityName,
          onQueryChanged: (newQuery) {
            if (mounted) {
              setState(() {
                _selectedActivityName = newQuery;
                refreshCurrentFilter();
              });
            }
          },
          onBeforeSearch: () {
            // 검색 시작 전 UI 업데이트
            if (mounted) {
              setState(() {
                _hasMoreData = true;
                _isLoadingMore = true; // 로딩 표시
              });
            }
          },
          onSearchComplete: () {
            // 별도 비동기 작업으로 로그 초기화
            Future.microtask(() async {
              if (mounted) {
                await _initializeLogs(isInitialLoad: true);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _scrollController.isAttached) {
                    _scrollController.jumpTo(index: 0);
                  }
                });
              }
            });
          });
    });
  }

  void _clearSearch() {
    // 현재 검색 작업 취소
    _searchProcessor.cancelCurrentSearch();

    // 검색 컨트롤러 지우기
    searchController.clear();

    // 전체 검색 프로세스 실행 (빈 쿼리로)
    _searchProcessor.processSearch(
        query: '',
        previousQuery: _selectedActivityName,
        onQueryChanged: (newQuery) {
          if (mounted) {
            setState(() {
              _selectedActivityName = null;
              refreshCurrentFilter();
            });
          }
        },
        onBeforeSearch: () {
          if (mounted) {
            setState(() {
              _hasMoreData = true;
              _isLoadingMore = true;
            });
          }
        },
        onSearchComplete: () {
          Future.microtask(() async {
            if (mounted) {
              await _initializeLogs(isInitialLoad: true);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _scrollController.isAttached) {
                  _scrollController.jumpTo(index: 0);
                }
              });
            }
          });
        });
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        SizedBox(height: context.hp(1)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onChanged: (query) {
                  _onSearchChanged(query);
                },
                onSubmitted: (query) {
                  if (_debounce?.isActive ?? false) {
                    _debounce!.cancel(); // 사용자가 엔터를 누르면 즉시 디바운스 취소 후 검색 실행
                  }
                  _searchProcessor.processSearch(
                      query: query,
                      previousQuery: _selectedActivityName,
                      onQueryChanged: (newQuery) {
                        if (mounted) {
                          setState(() {
                            _selectedActivityName = newQuery;
                            refreshCurrentFilter();
                          });
                        }
                      },
                      onBeforeSearch: () {
                        if (mounted) {
                          setState(() {
                            _hasMoreData = true;
                            _isLoadingMore = true;
                          });
                        }
                      },
                      onSearchComplete: () {
                        Future.microtask(() async {
                          if (mounted) {
                            await _initializeLogs(isInitialLoad: true);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _scrollController.isAttached) {
                                _scrollController.jumpTo(index: 0);
                              }
                            });
                          }
                        });
                      });
                },
                decoration: InputDecoration(
                  hintText: "활동 이름을 검색하세요",
                  hintStyle: AppTextStyles.getBody(context).copyWith(color: AppColors.textSecondary(context)),
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none, // 테두리 없음
                    borderRadius: BorderRadius.circular(8), // 원하는 둥근 정도로 조정 가능
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide.none, // 포커스 상태에서도 테두리 없음
                    borderRadius: BorderRadius.circular(8), // 원하는 둥근 정도로 조정 가능
                  ),
                  filled: true,
                  fillColor: AppColors.background(context),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: context.xs,
                    horizontal: context.sm,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _searchFocusNode.hasFocus || searchController.text.isNotEmpty ? Icons.clear : Icons.search_rounded,
                    ),
                    onPressed: _clearSearch,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isFilterApplied) ...[
          SizedBox(height: context.hp(1)),
          Padding(
            padding: context.paddingHorizXS,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 ${_getTotalLogCount()}건 조회',
                  style: AppTextStyles.getCaption(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                if (_selectedDateRange != null)
                  Text(
                    '${DateFormat('yy.MM.dd').format(_selectedDateRange!.start)} ~ ${DateFormat('yy.MM.dd').format(_selectedDateRange!.end)}',
                    style: AppTextStyles.getCaption(context).copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    try {
      DateTimeRange? initialRange;

      try {
        if (_selectedDateRange != null) {
          initialRange = _selectedDateRange;
        } else {
          initialRange = DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          );
        }
      } catch (e) {
        logger.e('초기 날짜 범위 설정 오류: $e');
        initialRange = DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );
      }

      // 바텀시트 표시 - 정적 메서드 사용
      final result = await DateRangePickerBottomSheet.show(
        context,
        initialDateRange: initialRange,
      );

      if (result != null) {
        logger.d('날짜 범위 선택 결과: $result');
        _onDateRangeSelected(result);
      }
    } catch (e) {
      logger.e('날짜 범위 선택 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('날짜 선택 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> logs, {required bool isFirstGroup}) {
    final String dayOfWeek = _getDayOfWeek(date);
    const int initialVisibleItems = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: context.spacing_xs,
            right: context.spacing_xs,
            top: context.spacing_sm,
          ),
          child: Text(
            '$date $dayOfWeek요일',
            style: AppTextStyles.getBody(context).copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: logs.length <= initialVisibleItems
                // 적은 수의 로그는 바로 표시
                ? Column(
                    children: [for (int i = 0; i < logs.length; i++) _buildLogItem(logs[i], isFirstGroup && i == 0)],
                  )
                // 많은 수의 로그는 처음 일부만 표시하고 나머지는 접어두기
                : Column(
                    children: [
                      // 처음 몇 개는 바로 표시
                      for (int i = 0; i < initialVisibleItems; i++) _buildLogItem(logs[i], isFirstGroup && i == 0),

                      // 나머지는 접기
                      ExpansionTile(
                        title: Text(
                          '${logs.length - initialVisibleItems}개 더보기',
                          style: AppTextStyles.getBody(context),
                        ),
                        shape: const Border(bottom: BorderSide.none),
                        collapsedShape: const Border(bottom: BorderSide.none),
                        children: [for (int i = initialVisibleItems; i < logs.length; i++) _buildLogItem(logs[i], false)],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log, bool isShowcaseTarget) {
    final String sessionId = log['session_id'];

    // 아직 로드되지 않은 항목은 Shimmer 표시
    if (_isRenderOptimized && !_loadedLogItems.containsKey(sessionId)) {
      return _buildShimmerLogItem();
    }

    final captionStyle = AppTextStyles.getCaption(context).copyWith(color: Colors.grey.shade500);

    Widget tile = RepaintBoundary(
      child: Slidable(
        key: ValueKey(log['session_id']),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                Future.microtask(() => _editActivityLog(log['session_id']));
              },
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              icon: Icons.edit,
            ),
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                Future.microtask(() => _deleteLog(log['session_id']));
              },
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete,
            ),
          ],
        ),
        child: ListTile(
          leading: IconCache.getIcon(log['activity_icon'], context.xl, context.xl),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  log['activity_name'] ?? '',
                  style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: context.sm,
                height: context.sm,
                decoration: BoxDecoration(
                  color: ColorService.hexToColor(log['activity_color']),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시작 시간
              _buildInfoRow('시작', formatDate(log['start_time']), captionStyle),

              // 종료 시간
              _buildInfoRow('종료', log['end_time'] != null ? formatDate(log['end_time']) : "진행 중", captionStyle),

              // 소요 시간 (있는 경우만)
              if (log['duration'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: Colors.grey, size: 18),
                      const SizedBox(width: 3),
                      Text(
                        formatTime((log['duration'] as int)),
                        style: captionStyle.copyWith(fontSize: context.sm),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );

    // Showcase 래핑 (필요한 경우에만)
    if (isShowcaseTarget) {
      tile = Showcase(
        key: _logKey,
        description: '왼쪽으로 드래그해서 기록 수정/삭제',
        targetBorderRadius: BorderRadius.circular(8),
        overlayOpacity: 0.5,
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildShimmerLogItem() {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundSecondary(context),
      highlightColor: AppColors.background(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: context.xl,
                      height: context.xl,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, TextStyle style) {
    return Row(
      children: [
        Text(label, style: style),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            value,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '활동 기록',
              style: AppTextStyles.getTitle(context),
            ),
            Row(
              children: [
                if (isDateFiltered)
                  Padding(
                    padding: context.paddingHorizXS,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _clearFilters();
                        searchController.clear();
                      },
                      child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            LucideIcons.filterX,
                            size: context.lg,
                            color: AppColors.textPrimary(context),
                          )),
                    ),
                  ),
                Padding(
                  padding: context.paddingHorizXS,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showDateRangePicker();
                    },
                    child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          LucideIcons.calendarDays,
                          size: context.lg,
                          color: isDateFiltered ? AppColors.primary(context) : AppColors.textPrimary(context),
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.backgroundSecondary(context),
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.backgroundSecondary(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: context.paddingHorizSM,
                  child: _buildSearchBar(),
                ),
                Align(
                  alignment: Alignment.center,
                  child: _buildDayButtons(),
                ),
                Expanded(
                  child: Padding(
                    padding: context.paddingHorizSM,
                    child: groupedLogs.isEmpty && !_isLoadingMore
                        ? const Center(child: Text('활동 로그가 없습니다.'))
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) => false,
                            child: RepaintBoundary(
                              child: ScrollablePositionedList.builder(
                                itemScrollController: _scrollController,
                                itemPositionsListener: _itemPositionsListener,
                                itemCount: groupedLogs.length + 1,
                                initialScrollIndex: dayToIndexMap[selectedDay] ?? 0,
                                minCacheExtent: MediaQuery.of(context).size.height * 1.5,
                                itemBuilder: (context, index) {
                                  if (index == groupedLogs.length) {
                                    return ActivityLogBottom(
                                      isLoadingMore: _isLoadingMore,
                                      loadingError: _loadingError,
                                      loadMoreData: () => _loadMoreData(),
                                      hasMoreData: _hasMoreData,
                                    );
                                  }

                                  if (_isRenderOptimized) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      final positions = _itemPositionsListener.itemPositions.value;
                                      final visibleIndices = positions.map((pos) => pos.index).toList();

                                      // 화면에 표시된 항목과 주변 항목 로드 우선순위 지정
                                      if (visibleIndices.contains(index) || visibleIndices.any((i) => (i - index).abs() <= 2)) {
                                        _loadLogItemsForGroup(index);
                                      }
                                    });
                                  }

                                  final logGroup = groupedLogs[index];
                                  final date = logGroup['date'] as String;
                                  final logs = logGroup['logs'] as List<Map<String, dynamic>>;
                                  final isFirstGroup = index == 0;
                                  return _buildDateGroup(date, logs, isFirstGroup: isFirstGroup);
                                },
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isLoadingMore) return const SizedBox.shrink();

    return Positioned.fill(
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.textSecondary(context),
        ),
      ),
    );
  }

  void _loadLogItemsForGroup(int groupIndex) {
    if (groupIndex >= groupedLogs.length) return;

    final logs = groupedLogs[groupIndex]['logs'] as List<Map<String, dynamic>>;
    final toLoad = <String>[];

    // 아직 로드되지 않은 항목 확인
    for (final log in logs) {
      final sessionId = log['session_id'];
      if (!_loadedLogItems.containsKey(sessionId)) {
        toLoad.add(sessionId);
      }
    }

    // 로드할 항목이 있으면 상태 업데이트
    if (toLoad.isNotEmpty) {
      setState(() {
        for (final id in toLoad) {
          _loadedLogItems[id] = true;
        }
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}
