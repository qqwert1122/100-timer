import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';

class EditActivityLogModal extends StatefulWidget {
  final String activityLogId;

  const EditActivityLogModal({
    super.key,
    required this.activityLogId,
  });

  @override
  State<EditActivityLogModal> createState() => _EditActivityLogModalState();
}

class _EditActivityLogModalState extends State<EditActivityLogModal> {
  final List<Map<String, dynamic>> items = [
    {'icon': Icons.play_circle_fill_rounded, 'text': '활동 시간', 'time': '2시간 42분'},
    {'icon': Icons.pause_circle_filled_rounded, 'text': '휴식 시간', 'time': '16분'},
    // 필요한 만큼 추가
  ];
  int selectedValue = 0; // 선택된 숫자 초기값
  final List<int> values = List.generate(25, (index) => index * 5); // 0부터 120까지의 숫자 목록 생성
  late Future<Map<String, dynamic>?> _activityLog;
  final DatabaseService dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _activityLog = dbService.getActivityLog(widget.activityLogId);
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

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          height: 400, // 모달창 높이 설정
          width: MediaQuery.of(context).size.width, // 모달창 가로 길이를 화면 크기로 설정
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '활동 기록 수정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _activityLog,
                  builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // 데이터 로딩 중 표시
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      // 에러 발생 시 표시
                      return Center(child: Text('에러: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      // 데이터가 없을 때 표시
                      return const Center(child: Text('활동 기록을 찾을 수 없습니다.'));
                    } else {
                      // 데이터 로드 완료 시 UI 표시
                      final activityLog = snapshot.data!;
                      final activityDuration = activityLog['activity_duration'] ?? 0; // 단위: 분
                      final restTime = activityLog['rest_time'] ?? 0; // 단위: 분

                      // selectedValue를 activityDuration으로 초기 설정
                      // 단, selectedValue가 0이면 표시할 밑줄을 적용할 수 있음
                      // 만약 초기값 설정이 필요하다면, setState를 사용하여 설정할 수 있습니다.

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "활동시간",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  formatTime(activityDuration),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.pause_circle_filled_rounded,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "휴식시간",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  formatTime(restTime),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '기록보다',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ),
                            // 위아래 버튼
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _showPicker(context), // 숫자 선택 피커 표시
                                  child: Row(
                                    children: [
                                      Text(
                                        '$selectedValue 분', // 현재 선택된 값 표시
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 36,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {}); // 필요한 경우 상태 업데이트
                        Navigator.pop(context); // 모달창 닫기
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '더 휴식했어요',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {}); // 필요한 경우 상태 업데이트
                        Navigator.pop(context); // 모달창 닫기
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '더 활동했어요',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedValue ~/ 5), // 초기 선택값 설정
                  itemExtent: 40, // 각 항목의 높이
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      selectedValue = values[index]; // 선택된 값 업데이트
                    });
                  },
                  children: List<Widget>.generate(values.length, (int index) {
                    return Center(
                      child: Text(
                        '${values[index]} 분', // 숫자 표시
                        style: const TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    );
                  }),
                ),
              ),
              CupertinoButton(
                child: const Text(
                  '확인',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(context); // 피커 닫기
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
