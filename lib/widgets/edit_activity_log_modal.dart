import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/database_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/utils/responsive_size.dart';
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
  late Future<Map<String, dynamic>?> _sessionData;
  late final DatabaseService _dbService; // 주입받을 DatabaseService
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  TextEditingController timeController = TextEditingController(text: "00:00:00");

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false); // DatabaseService 주입
    _sessionData = _dbService.getSession(widget.sessionId);

    // 세션 데이터를 가져온 후 초기 시간 설정
    _sessionData.then(
      (sessionData) {
        if (sessionData != null) {
          final sessionDuration = sessionData['duration'] ?? 0;

          // 초 단위 시간을 시, 분, 초로 변환
          setState(() {
            hours = sessionDuration ~/ 3600;
            minutes = (sessionDuration % 3600) ~/ 60;
            seconds = sessionDuration % 60;

            // 텍스트 컨트롤러 업데이트
            timeController.text = formatTimeInput(hours, minutes, seconds);
          });
        }
      },
    );
  }

  int getTimeInSeconds() {
    return hours * 3600 + minutes * 60 + seconds;
  }

// 초 단위를 시:분:초 형식으로 포맷팅하는 함수
  String formatTimeInput(int h, int m, int s) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: AppColors.background(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      '취소',
                      style: TextStyle(color: AppColors.textPrimary(context)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoButton(
                    child: Text(
                      '확인',
                      style: TextStyle(color: AppColors.textPrimary(context)),
                    ),
                    onPressed: () {
                      setState(() {
                        timeController.text = formatTimeInput(hours, minutes, seconds);
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '시',
                              style: AppTextStyles.getTitle(context),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: hours),
                              itemExtent: 40,
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  hours = index;
                                });
                              },
                              children: List<Widget>.generate(24, (int index) {
                                return Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '분',
                              style: AppTextStyles.getTitle(context),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: minutes),
                              itemExtent: 40,
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  minutes = index;
                                });
                              },
                              children: List<Widget>.generate(60, (int index) {
                                return Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '초',
                              style: AppTextStyles.getTitle(context),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(initialItem: seconds),
                              itemExtent: 40,
                              onSelectedItemChanged: (int index) {
                                setState(() {
                                  seconds = index;
                                });
                              },
                              children: List<Widget>.generate(60, (int index) {
                                return Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          height: context.hp(60),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
          ),
          child: FutureBuilder(
            future: _sessionData,
            builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                  color: AppColors.textPrimary(context),
                ));
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('활동 기록을 찾을 수 없습니다.'));
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.hp(1)),
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
                    SizedBox(height: context.hp(2)),
                    Text('활동 시간', style: AppTextStyles.getHeadline(context)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showTimePicker(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: timeController,
                          decoration: InputDecoration(
                            hintText: "00:00:00",
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontFamily: 'chab',
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            suffixIcon: Icon(
                              Icons.access_time,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          style: AppTextStyles.getTimeDisplay(context).copyWith(
                            fontFamily: 'chab',
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                // 선택한 시간을 초 단위로 변환하여 사용
                                int additionalDurationSeconds = getTimeInSeconds();

                                await _dbService.updateSessionDuration(
                                  sessionId: widget.sessionId,
                                  additionalDurationSeconds: additionalDurationSeconds,
                                );

                                if (widget.onUpdate != null) widget.onUpdate!();
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
                                // 에러 처리
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
                              '수정',
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
}
