import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/widgets/edit_activity_log_modal.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({Key? key}) : super(key: key);

  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  List<Map<String, dynamic>> groupedLogs = [];
  final List<String> daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
  String selectedDay = '';
  Map<String, int> dayToIndexMap = {};

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool isProgrammaticScroll = false;

  int _currentWeekOffset = 0; // 현재 불러온 주차의 오프셋 (0: 이번 주, 1: 지난주, ...)
  bool _isLoadingMore = false; // 추가 데이터 로드 중인지 여부
  bool _hasMoreData = true; // 추가 데이터가 더 있는지 여부

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
    try {
      if (isInitialLoad) {
        _currentWeekOffset = 0;
        groupedLogs.clear();
        dayToIndexMap.clear();
        _hasMoreData = true;
      } else {
        _currentWeekOffset += 1;
      }

      print('_currentWeekOffset : $_currentWeekOffset');

      final logData = await _statsProvider.getSessionsForWeek(_currentWeekOffset);

      if (logData.isEmpty) {
        print('logdata is empty');
        setState(() {
          _hasMoreData = false;
        });
        return;
      }

      // 삭제되지 않은 세션 필터링
      final filteredLogs = logData.where((log) => log['is_deleted'] == 0).toList();

      final grouped = _groupLogsByDate(filteredLogs);

      setState(() {
        groupedLogs.addAll(grouped);
        dayToIndexMap = _calculateDayToIndexMap();
      });

      // 초기 로드시 현재 날짜로 스크롤
      if (isInitialLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final index = dayToIndexMap[selectedDay] ?? 0;
          setState(() {
            isProgrammaticScroll = true;
          });
          _scrollController.jumpTo(index: index);
          setState(() {
            isProgrammaticScroll = false;
          });
        });
      }

      // 메모리에서 오래된 데이터 제거 (최대 3주치 데이터 유지)
      if (groupedLogs.length > 21) {
        setState(() {
          groupedLogs.removeRange(0, groupedLogs.length - 21);
          dayToIndexMap = _calculateDayToIndexMap();
        });
      }
    } catch (e) {
      print('로그 데이터를 가져오는 중 오류 발생: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (isProgrammaticScroll) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      // 현재 화면에 보이는 아이템의 인덱스 목록
      final visibleIndices = positions.map((e) => e.index).toList();

      // 화면 중앙에 가장 가까운 아이템의 인덱스 찾기
      final screenMiddle = 0.5;

      final middlePosition = positions.reduce((closest, position) {
        final itemMiddle = (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
        final closestItemMiddle = (closest.itemLeadingEdge + closest.itemTrailingEdge) / 2;

        return (itemMiddle - screenMiddle).abs() < (closestItemMiddle - screenMiddle).abs() ? position : closest;
      });

      final index = middlePosition.index;

      if (index < groupedLogs.length) {
        String date = groupedLogs[index]['date'];
        String dayOfWeek = _getDayOfWeek(date);

        if (dayOfWeek != selectedDay) {
          setState(() {
            selectedDay = dayOfWeek;
          });
        }
      }

      // 스크롤이 끝에 도달했는지 확인
      final maxIndex = positions.map((e) => e.index).reduce(max);
      if (maxIndex >= groupedLogs.length - 1 && !_isLoadingMore && _hasMoreData) {
        _isLoadingMore = true;
        _initializeLogs();
      }
    }
  }

  void _refreshLogs() {
    _initializeLogs(isInitialLoad: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '활동 기록',
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDayButtons(),
            Expanded(
              child: groupedLogs.isEmpty
                  ? const Center(child: Text('활동 로그가 없습니다.'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        return false; // 추가 이벤트 처리를 막지 않음
                      },
                      child: ScrollablePositionedList.builder(
                        itemScrollController: _scrollController,
                        itemPositionsListener: _itemPositionsListener,
                        itemCount: groupedLogs.length + 1, // 로딩 인디케이터를 위해 +1
                        itemBuilder: (context, index) {
                          if (index == groupedLogs.length) {
                            // 데이터 로드 중 로딩 인디케이터 표시
                            return _isLoadingMore
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : !_hasMoreData
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        child: Center(child: Text('더 이상 데이터가 없습니다.')),
                                      )
                                    : const SizedBox.shrink();
                          }

                          final logGroup = groupedLogs[index];
                          final date = logGroup['date'] as String;
                          final logs = logGroup['logs'] as List<Map<String, dynamic>>;

                          return _buildDateGroup(date, logs, isDarkMode);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupLogsByDate(List<Map<String, dynamic>> logs) {
    Map<String, List<Map<String, dynamic>>> groupedLogs = {};

    for (var log in logs) {
      if (log.containsKey('start_time') && log['start_time'] != null) {
        String date = DateTime.parse(log['start_time']).toLocal().toIso8601String().substring(0, 10);

        if (!groupedLogs.containsKey(date)) {
          groupedLogs[date] = [];
        }

        groupedLogs[date]!.add(log);
      }
    }

    List<Map<String, dynamic>> groupedLogList = groupedLogs.entries.map((entry) {
      entry.value.sort((a, b) => DateTime.parse(b['start_time']).compareTo(DateTime.parse(a['start_time'])));
      return {'date': entry.key, 'logs': entry.value};
    }).toList();

    groupedLogList.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    return groupedLogList;
  }

  String formatDate(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString).toLocal();
    final now = DateTime.now();

    final isSameYear = dateTime.year == now.year;

    // 날짜와 시간 포맷 정의
    final timeFormatter = DateFormat('a h시 mm분'); // 오전/오후 h시 mm분
    final dateFormatter = isSameYear ? DateFormat('M월 d일') : DateFormat('yyyy년 M월 d일');

    // 포맷 결합

    String formattedTime = timeFormatter.format(dateTime).replaceAll('AM', '오전').replaceAll('PM', '오후');

    return '${dateFormatter.format(dateTime)} $formattedTime';
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

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> logs, bool isDarkMode) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime dateTime = formatter.parse(date);
    final String dayOfWeek = _getDayOfWeek(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 36, bottom: 4),
          child: Text('$date $dayOfWeek요일', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          width: double.infinity,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
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
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                // 초기값 설정
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
                    leading: Icon(getIconData(log['activity_icon'])),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          log['activity_name'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(vertical: 2.0),
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '시작',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Text(
                              formatDate(log['start_time']),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '종료',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Text(
                              log['end_time'] != null ? formatDate(log['end_time']) : "진행 중",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        if (log['session_duration'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(
                                    width: 3,
                                  ),
                                  Text(
                                    formatTime((log['session_duration'] as int)),
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
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

  Widget _buildDayButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(daysOfWeek.length, (index) {
          final isSelected = daysOfWeek[index] == selectedDay;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  selectedDay = daysOfWeek[index];
                });
                _scrollToDate(selectedDay);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: isSelected ? const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent) : null,
                child: Text(daysOfWeek[index], style: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.grey)),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _scrollToDate(String dayOfWeek) {
    final index = dayToIndexMap[dayOfWeek] ?? -1;
    if (index != -1) {
      setState(() {
        isProgrammaticScroll = true;
      });
      _scrollController
          .scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      )
          .then((_) {
        setState(() {
          isProgrammaticScroll = false;
        });
      });
    }
  }

  String _getDayOfWeek(String date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime dateTime = formatter.parse(date);
    int weekday = dateTime.weekday;
    int index = (weekday + 6) % 7;
    String dayName = daysOfWeek[index];
    return dayName;
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
        await _dbService.deleteSession(sessionId); // 데이터베이스에서 로그 삭제
        await _initializeLogs(isInitialLoad: true); // 화면 갱신
        Fluttertoast.showToast(
          msg: "로그가 삭제되었습니다.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
      } catch (e) {
        print('로그 삭제 중 오류 발생: $e');
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
              title: const Text(
                '정말 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: const Text('이 활동 로그를 삭제하면 복구할 수 없습니다.'),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text(
                    '삭제',
                    style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.w900),
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
}
