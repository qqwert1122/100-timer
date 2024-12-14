import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class EditActivityLogModal extends StatefulWidget {
  final String sessionId;
  final VoidCallback? onUpdate; // 수정 후 호출할 콜백
  final VoidCallback? onDelete; // 삭제 후 호출할 콜백

  const EditActivityLogModal({
    super.key,
    required this.sessionId,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<EditActivityLogModal> createState() => _EditActivityLogModalState();
}

class _EditActivityLogModalState extends State<EditActivityLogModal> {
  int selectedValue = 0; // 선택된 시간 (분 단위)
  final List<int> values = List.generate(25, (index) => index * 5); // 0부터 120까지의 숫자 목록 생성
  late Future<Map<String, dynamic>?> _sessionData;
  late final DatabaseService _dbService; // 주입받을 DatabaseService

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false); // DatabaseService 주입
    _sessionData = _dbService.getSession(widget.sessionId);
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
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          height: 400,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: _sessionData,
            builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('에러: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('활동 기록을 찾을 수 없습니다.'));
              } else {
                final session = snapshot.data!;
                final sessionDuration = session['session_duration'] ?? 0;
                final restTime = session['rest_time'] ?? 0;
                final activityTime = sessionDuration - restTime;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 60,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white24 : Colors.grey[350],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                      child: Text(
                        '활동 기록 수정',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                size: 28,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "활동시간",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatTime(activityTime),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.pause_circle_filled_rounded,
                                size: 28,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "휴식시간",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                formatTime(restTime),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '기록보다',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ),
                          // 시간 선택 및 조정
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _showPicker(context),
                                child: Row(
                                  children: [
                                    Text(
                                      '$selectedValue분',
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
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                // 휴식 시간을 증가
                                int additionalRestSeconds = selectedValue * 60;

                                await _dbService.updateSessionDuration(
                                  sessionId: widget.sessionId,
                                  additionalDurationSeconds: additionalRestSeconds,
                                  type: "REST", // "휴식" 타입
                                );

                                if (widget.onUpdate != null) widget.onUpdate!();
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: "휴식 시간이 업데이트되었습니다.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.blueAccent.shade200,
                                  textColor: Colors.white,
                                  fontSize: 14.0,
                                );
                              } catch (e) {
                                print('Error updating rest time: $e');
                                Fluttertoast.showToast(
                                  msg: "휴식 시간 업데이트 중 오류가 발생했습니다.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.redAccent.shade200,
                                  textColor: Colors.white,
                                  fontSize: 14.0,
                                );
                              }
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
                            onPressed: () async {
                              try {
                                // 활동 시간을 증가
                                int additionalDurationSeconds = selectedValue * 60;

                                await _dbService.updateSessionDuration(
                                  sessionId: widget.sessionId,
                                  additionalDurationSeconds: additionalDurationSeconds,
                                  type: "DURATION", // "추가활동" 타입
                                );

                                if (widget.onDelete != null) widget.onDelete!();
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: "활동 시간이 업데이트되었습니다.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.blueAccent.shade200,
                                  textColor: Colors.white,
                                  fontSize: 14.0,
                                );
                              } catch (e) {
                                print('Error updating activity time: $e');
                                Fluttertoast.showToast(
                                  msg: "활동 시간 업데이트 중 오류가 발생했습니다.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.redAccent.shade200,
                                  textColor: Colors.white,
                                  fontSize: 14.0,
                                );
                              }
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
                );
              }
            },
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
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedValue ~/ 5),
                  itemExtent: 40,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      selectedValue = values[index];
                    });
                  },
                  children: values.map((value) {
                    return Center(
                      child: Text(
                        '$value 분',
                        style: const TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
              CupertinoButton(
                child: const Text(
                  '확인',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
