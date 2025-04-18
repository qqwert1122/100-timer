import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/widgets/edit_activity_log_modal.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> with AutomaticKeepAliveClientMixin {
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  List<Map<String, dynamic>> groupedLogs = [];
  final List<String> daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
  String selectedDay = '';
  Map<String, int> dayToIndexMap = {};

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool isProgrammaticScroll = false;

  int _currentWeekOffset = 0; // 0: 이번 주, 1: 지난주, ...
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _loadingError = false;

  // 스크롤 임계치 설정: 리스트 하단에서 몇 개 남았을 때 로드할지 결정
  static const int _loadMoreThreshold = 3;
  // 메모리에 최대 유지할 주차 수 (예, 6주치 데이터)
  static const int _maxStoredWeeks = 6;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);

    final today = DateTime.now();
    final todayWeekdayIndex = (today.weekday + 6) % 7;
    selectedDay = daysOfWeek[todayWeekdayIndex];

    _initializeLogs(isInitialLoad: true);
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  Future<void> _initializeLogs({bool isInitialLoad = false}) async {
    if (_isLoadingMore && !isInitialLoad) return; // 중복 요청 방지
    setState(() {
      _isLoadingMore = true;
      _loadingError = false;
    });
    try {
      if (isInitialLoad) {
        _currentWeekOffset = 0;
        groupedLogs.clear();
        dayToIndexMap.clear();
        _hasMoreData = true;
      } else {
        _currentWeekOffset -= 1;
      }

      // 빈 데이터가 반환될 경우, 최대 maxAttempts 번까지 weekOffset을 증가시켜 데이터를 찾음
      List<Map<String, dynamic>> logData = [];
      const int maxAttempts = 10;
      int attempts = 0;
      while (attempts < maxAttempts) {
        debugPrint("Loading data for weekOffset: $_currentWeekOffset");
        logData = await _statsProvider.getSessionsForWeek(_currentWeekOffset);
        if (logData.isNotEmpty) {
          debugPrint("Data found for weekOffset: $_currentWeekOffset (${logData.length} records)");
          break;
        } else {
          debugPrint("No data for weekOffset: $_currentWeekOffset, trying next week");
          _currentWeekOffset -= 1;
          attempts++;
        }
      }

      if (logData.isEmpty) {
        debugPrint("No more data after $attempts attempts.");
        setState(() {
          _hasMoreData = false;
        });
        return;
      }

      // 삭제되지 않은 로그만 필터링
      final filteredLogs = logData.where((log) => log['is_deleted'] == 0).toList();

      final grouped = _groupLogsByDate(filteredLogs);

      setState(() {
        groupedLogs.addAll(grouped);
        dayToIndexMap = _calculateDayToIndexMap();
      });

      // 초기 로드시 현재 날짜에 해당하는 인덱스로 스크롤
      if (isInitialLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final index = dayToIndexMap[selectedDay] ?? 0;
          debugPrint('초기 로드 후 스크롤: selectedDay=$selectedDay, index=$index');
          _scrollToIndex(index);
        });
      }
      // 추가 데이터 로드 후 이전 스크롤 위치 유지
      else {
        final positions = _itemPositionsListener.itemPositions.value;
        if (positions.isNotEmpty) {
          final targetIndex = positions.first.index;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.isAttached && targetIndex < groupedLogs.length) {
              debugPrint('추가 데이터 로드 후 이전 위치로 복귀: targetIndex=$targetIndex');
              _scrollController.jumpTo(index: targetIndex);
            }
          });
        }
      }

      // 메모리 관리: 최대 _maxStoredWeeks 주치 데이터만 유지
      if (groupedLogs.length > _maxStoredWeeks * 7) {
        setState(() {
          final int itemsToRemove = groupedLogs.length - _maxStoredWeeks * 7;
          debugPrint('메모리 관리: $itemsToRemove 아이템 제거 전 groupedLogs.length=${groupedLogs.length}');
          groupedLogs.removeRange(0, itemsToRemove);
          dayToIndexMap = _calculateDayToIndexMap();
          debugPrint('메모리 관리 후 groupedLogs.length=${groupedLogs.length}');
        });
      }
    } catch (e) {
      debugPrint('로그 데이터를 가져오는 중 오류 발생: $e');
      setState(() {
        _loadingError = true;
      });
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
      debugPrint('_initializeLogs 종료, _isLoadingMore: $_isLoadingMore');
    }
  }

  void _onScroll() {
    if (isProgrammaticScroll) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      debugPrint('스크롤 위치 정보가 없음');
      return;
    }

    // 전체 positions 출력 (디버깅용)
    debugPrint(
        '현재 itemPositions: ${positions.map((e) => "index:${e.index}, leading:${e.itemLeadingEdge}, trailing:${e.itemTrailingEdge}").toList()}');

    // 화면 중앙에 가장 가까운 아이템 인덱스 계산
    const screenMiddle = 0.5;
    final middlePosition = positions.reduce((closest, position) {
      final itemMiddle = (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
      final closestMiddle = (closest.itemLeadingEdge + closest.itemTrailingEdge) / 2;
      return (itemMiddle - screenMiddle).abs() < (closestMiddle - screenMiddle).abs() ? position : closest;
    });
    debugPrint('중앙에 위치한 아이템 index: ${middlePosition.index}');

    final index = middlePosition.index;
    if (index < groupedLogs.length) {
      final date = groupedLogs[index]['date'];
      final dayOfWeek = _getDayOfWeek(date);
      debugPrint('현재 그룹 날짜: $date, 요일: $dayOfWeek, selectedDay: $selectedDay');
      if (dayOfWeek != selectedDay) {
        setState(() {
          selectedDay = dayOfWeek;
        });
      }
    }

    final maxIndex = positions.map((e) => e.index).reduce(max);
    debugPrint('maxIndex: $maxIndex, groupedLogs.length: ${groupedLogs.length}, threshold: ${groupedLogs.length - _loadMoreThreshold}');

    if ((groupedLogs.length <= _loadMoreThreshold || maxIndex >= groupedLogs.length - _loadMoreThreshold) &&
        !_isLoadingMore &&
        _hasMoreData) {
      debugPrint('임계치 도달, _loadMoreData() 호출');
      _loadMoreData();
    } else {
      debugPrint('임계치 미달: _isLoadingMore=$_isLoadingMore, _hasMoreData=$_hasMoreData');
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;
    debugPrint('_loadMoreData() 실행');
    await _initializeLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _isLoadingMore = false;
      _hasMoreData = true;
      _loadingError = false;
    });
    await _initializeLogs(isInitialLoad: true);
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
        debugPrint('스크롤 완료, 현재 index: $index');
      });
    }
  }

  List<Map<String, dynamic>> _groupLogsByDate(List<Map<String, dynamic>> logs) {
    Map<String, List<Map<String, dynamic>>> tempGroup = {};
    for (var log in logs) {
      if (log.containsKey('start_time') && log['start_time'] != null) {
        String date = DateTime.parse(log['start_time']).toLocal().toIso8601String().substring(0, 10);
        if (!tempGroup.containsKey(date)) {
          tempGroup[date] = [];
        }
        tempGroup[date]!.add(log);
      }
    }
    List<Map<String, dynamic>> groupedList = tempGroup.entries.map((entry) {
      entry.value.sort((a, b) => DateTime.parse(b['start_time']).compareTo(DateTime.parse(a['start_time'])));
      return {'date': entry.key, 'logs': entry.value};
    }).toList();
    groupedList.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    return groupedList;
  }

  Map<String, int> _calculateDayToIndexMap() {
    final Map<String, int> indexMap = {};
    for (int i = 0; i < groupedLogs.length; i++) {
      String date = groupedLogs[i]['date'];
      String dayOfWeek = _getDayOfWeek(date);
      if (!indexMap.containsKey(dayOfWeek)) {
        indexMap[dayOfWeek] = i;
      }
    }
    return indexMap;
  }

  String _getDayOfWeek(String date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime dateTime = formatter.parse(date);
    int weekday = dateTime.weekday;
    int index = (weekday + 6) % 7;
    return daysOfWeek[index];
  }

  String formatDate(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString).toLocal();
    final now = DateTime.now();
    final isSameYear = dateTime.year == now.year;
    final timeFormatter = DateFormat('a h시 mm분');
    final dateFormatter = isSameYear ? DateFormat('M월 d일') : DateFormat('yyyy년 M월 d일');
    String formattedTime = timeFormatter.format(dateTime).replaceAll('AM', '오전').replaceAll('PM', '오후');
    return '${dateFormatter.format(dateTime)} $formattedTime';
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

  Future<void> _deleteLog(String sessionId) async {
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete) {
      try {
        await _dbService.deleteSession(sessionId);
        await _refreshLogs();
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

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.background(context),
              title: const Text(
                '정말 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Neo',
                ),
              ),
              content: const Text('활동 기록을 삭제하면 복구할 수 없습니다.'),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Neo',
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
              padding: const EdgeInsets.all(8),
              decoration: isSelected ? const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent) : null,
              child: Text(
                daysOfWeek[index],
                style: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.grey),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> logs) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime dateTime = formatter.parse(date);
    final String dayOfWeek = _getDayOfWeek(date);
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            child: Column(
              children: logs.map((log) {
                return Slidable(
                  key: ValueKey(log['session_id']),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return EditActivityLogModal(
                                  sessionId: log['session_id'],
                                  onUpdate: _refreshLogs,
                                  onDelete: _refreshLogs,
                                );
                              });
                        },
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                      ),
                      SlidableAction(
                        onPressed: (context) {
                          HapticFeedback.lightImpact();
                          _deleteLog(log['session_id']);
                        },
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Image.asset(
                      getIconImage(log['activity_icon']),
                      width: context.xl,
                      height: context.xl,
                      errorBuilder: (context, error, stackTrace) {
                        // 이미지를 로드하는 데 실패한 경우의 대체 표시
                        return Container(
                          width: context.xl,
                          height: context.xl,
                          color: Colors.grey.withOpacity(0.2),
                          child: Icon(
                            Icons.broken_image,
                            size: context.xl,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                    title: Row(
                      children: [
                        Text(
                          log['activity_name'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
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
                        Row(
                          children: [
                            Text('시작', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(width: 15),
                            Text(
                              formatDate(log['start_time']),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text('종료', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(width: 15),
                            Text(
                              log['end_time'] != null ? formatDate(log['end_time']) : "진행 중",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        if (log['duration'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.play_circle_fill_rounded, color: Colors.grey, size: 18),
                                  const SizedBox(width: 3),
                                  Text(
                                    formatTime((log['duration'] as int)),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomWidget() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_loadingError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(height: 8),
              const Text('데이터 로드 중 오류 발생'),
              TextButton(
                onPressed: _loadMoreData,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    } else if (!_hasMoreData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('마지막 기록입니다')),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 기록', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
          )
        ],
        backgroundColor: AppColors.backgroundSecondary(context),
      ),
      body: Container(
        color: AppColors.backgroundSecondary(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: _buildDayButtons(),
            ),
            Expanded(
              child: Padding(
                padding: context.paddingSM,
                child: groupedLogs.isEmpty && !_isLoadingMore
                    ? const Center(child: Text('활동 로그가 없습니다.'))
                    : RefreshIndicator(
                        onRefresh: _refreshLogs,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) => false,
                          child: ScrollablePositionedList.builder(
                            itemScrollController: _scrollController,
                            itemPositionsListener: _itemPositionsListener,
                            itemCount: groupedLogs.length + 1,
                            itemBuilder: (context, index) {
                              if (index == groupedLogs.length) {
                                return _buildBottomWidget();
                              }
                              final logGroup = groupedLogs[index];
                              final date = logGroup['date'] as String;
                              final logs = logGroup['logs'] as List<Map<String, dynamic>>;
                              return _buildDateGroup(date, logs);
                            },
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
