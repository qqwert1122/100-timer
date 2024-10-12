import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart'; // 아이콘 유틸리티
import 'package:project1/widgets/edit_activity_log_modal.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> groupedLogs = [];
  final List<String> daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
  String selectedDay = '';
  Map<String, int> dayToIndexMap = {};

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final todayWeekdayIndex = (today.weekday + 6) % 7;
    selectedDay = daysOfWeek[todayWeekdayIndex];
    _initializeLogs();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  Future<void> _initializeLogs() async {
    try {
      final logData = await _dbService.getAllActivityLogs();
      final grouped = _groupLogsByDate(logData);
      setState(() {
        groupedLogs = grouped;
        dayToIndexMap = _calculateDayToIndexMap();
      });

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
    } catch (e) {
      print('로그 데이터를 가져오는 중 오류 발생: $e');
      // 오류 처리
    }
  }

  void _onScroll() {
    if (isProgrammaticScroll) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      const screenMiddle = 0.5;

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
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  : ScrollablePositionedList.builder(
                      itemScrollController: _scrollController,
                      itemPositionsListener: _itemPositionsListener,
                      itemCount: groupedLogs.length,
                      itemBuilder: (context, index) {
                        final logGroup = groupedLogs[index];
                        final date = logGroup['date'] as String;
                        final logs = logGroup['logs'] as List<Map<String, dynamic>>;

                        return _buildDateGroup(date, logs);
                      },
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

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> logs) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

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
                  key: ValueKey(log['activity_log_id']),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                // 초기값 설정

                                return const EditActivityLogModal();
                              });
                        },
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                      ),
                      SlidableAction(
                        onPressed: (context) {
                          _deleteLog(log['activity_log_id']);
                        },
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(getIconData(log['activity_icon'])),
                    title: Text(log['activity_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '시작',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(log['start_time']).toLocal())),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '종료',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Text(
                              log['end_time'] != null
                                  ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(log['end_time']).toLocal())
                                  : "진행 중",
                            ),
                          ],
                        ),
                        if (log['activity_duration'] != null && log['rest_time'] != null)
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
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(formatTime(log['activity_duration'] - log['rest_time'] as int)),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  const Icon(
                                    Icons.pause_circle_filled_rounded,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(formatTime(log['rest_time'] as int)),
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

  Future<void> _deleteLog(String logId) async {
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete) {
      try {
        await _dbService.deleteActivityLog(logId);
        await _initializeLogs();
      } catch (e) {
        print('로그 삭제 중 오류 발생: $e');
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
