import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

class EditActivityLogModal extends StatefulWidget {
  final String sessionId;

  const EditActivityLogModal({
    super.key,
    required this.sessionId,
  });

  @override
  State<EditActivityLogModal> createState() => _EditActivityLogModalState();
}

class _EditActivityLogModalState extends State<EditActivityLogModal> {
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  late final TimerProvider _timerProvider;

  late Future<Map<String, dynamic>?> _sessionData;
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  String duration = '00:00:00';
  String activityName = '활동이름';
  String activityIcon = 'category';
  String activityId = '';
  String activityColor = '';

  // 전체 활동 list
  late Future<List<Map<String, dynamic>>> futureActivityList;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);

    // 세션 불러오기
    _sessionData = _dbService.getSession(widget.sessionId);
    _sessionData.then(
      (sessionData) {
        if (sessionData != null) {
          final sessionDuration = sessionData['duration'] ?? 0;
          final _activityId = sessionData['activity_id'];
          final _activityName = sessionData['activity_name'];
          final _activityColor = sessionData['activity_color'];
          final _activityIcon = sessionData['activity_icon'];

          setState(() {
            // duration을 변수에 저장
            hours = sessionDuration ~/ 3600;
            minutes = (sessionDuration % 3600) ~/ 60;
            seconds = sessionDuration % 60;
            duration = formatTimeInput(hours, minutes, seconds);

            // 활동 정보를 변수에 저장
            activityId = _activityId;
            activityName = _activityName;
            activityIcon = _activityIcon;
            activityColor = _activityColor;
          });
        }
      },
    );

    // 활동 불러오기
    futureActivityList = _statsProvider.getActivities();
  }

  int getTimeInSeconds() {
    return hours * 3600 + minutes * 60 + seconds;
  }

// 초 단위를 시:분:초 형식으로 포맷팅하는 함수
  String formatTimeInput(int h, int m, int s) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void saveChanges() async {
    // 선택한 시간을 초 단위로 변환하여 사용
    int newDuration = getTimeInSeconds();

// 세션 시간 업데이트
    await _dbService.modifySession(
      sessionId: widget.sessionId,
      newDuration: newDuration,
      activityId: activityId,
      activityName: activityName,
      activityIcon: activityIcon,
      activityColor: activityColor,
    );

    _statsProvider.updateCurrentSessions();
    _timerProvider.refreshRemainingSeconds();

    final updatedSession = await _dbService.getSession(widget.sessionId);

    Navigator.of(context).pop(updatedSession);
    Fluttertoast.showToast(
      msg: "활동 기록이 업데이트 되었습니다.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.blueAccent.shade200,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _showTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: context.hp(60),
          padding: context.paddingSM,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: context.hp(1)),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: context.hp(2)),
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
                              style: AppTextStyles.getTitle(context).copyWith(
                                color: AppColors.textPrimary(context),
                              ),
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
                                    style: AppTextStyles.getBody(context),
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
                              style: AppTextStyles.getTitle(context).copyWith(
                                color: AppColors.textPrimary(context),
                              ),
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
                                    style: AppTextStyles.getBody(context),
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
                              style: AppTextStyles.getTitle(context).copyWith(
                                color: AppColors.textPrimary(context),
                              ),
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
                                    style: AppTextStyles.getBody(context),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.wp(2)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          setState(() {
                            duration = formatTimeInput(hours, minutes, seconds);
                          });
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        } catch (e) {
                          logger.d('Error updating activity time: $e');
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
                      child: Text(
                        '확인',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.hp(2)),
            ],
          ),
        );
      },
    );
  }

  void _showActivityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: context.hp(60),
          padding: context.paddingSM,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: context.hp(1)),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: context.hp(1)),
              Padding(
                padding: context.paddingSM,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '활동 선택하기',
                    style: AppTextStyles.getTitle(context),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: futureActivityList,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<Map<String, dynamic>> activities = [];
                    if (snapshot.hasData) {
                      activities = snapshot.data as List<Map<String, dynamic>>;
                    }

                    return Padding(
                      padding: context.paddingSM,
                      child: ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          final iconName = activity['activity_icon'];
                          final iconData = getIconImage(iconName);

                          return Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: activity['activity_name'] == activityName ? Colors.red[50] : null,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: Image.asset(
                                  iconData,
                                  width: context.xl,
                                  height: context.xl,
                                  errorBuilder: (context, error, stackTrace) {
                                    // 이미지를 로드하는 데 실패한 경우의 대체 표시
                                    return Container(
                                      width: context.xl,
                                      height: context.xl,
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      child: Icon(
                                        Icons.broken_image,
                                        size: context.xl,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['activity_name'],
                                      style: AppTextStyles.getBody(context).copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: activity['activity_name'] == activityName ? Colors.redAccent.shade200 : null),
                                    ),
                                    SizedBox(
                                      width: context.wp(4),
                                    ),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: ColorService.hexToColor(activity['activity_color']),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    activityId = activity['activity_id'];
                                    activityName = activity['activity_name'];
                                    activityIcon = activity['activity_icon'];
                                    activityColor = activity['activity_color'];
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
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
          padding: context.paddingSM,
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
                          color: AppColors.backgroundSecondary(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: context.hp(2)),
                    Text(
                      '활동 기록 수정',
                      style: AppTextStyles.getTitle(context),
                    ),
                    SizedBox(height: context.hp(2)),
                    Container(
                      width: context.wp(100),
                      padding: context.paddingSM,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary(context),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '활동 시간 수정 시 시작일시와 종료일시는 변경되지 않습니다.\n시간대별 히트맵은 수정된 활동시간이 반영되지 않습니다.',
                            style: AppTextStyles.getCaption(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.hp(4)),
                    GestureDetector(
                      onTap: () {
                        _showActivityPicker(context);
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: context.paddingSM,
                        decoration: BoxDecoration(
                          color: AppColors.background(context),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(16.0),
                          ),
                          border: Border.all(
                            color: AppColors.backgroundTertiary(context),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                '활동',
                                style: AppTextStyles.getBody(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Image.asset(
                                    getIconImage(activityIcon),
                                    width: context.xl,
                                    height: context.xl,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: context.xl,
                                        height: context.xl,
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        child: Icon(
                                          Icons.broken_image,
                                          size: context.xl,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: context.wp(2)),
                                  Flexible(
                                    child: Text(
                                      activityName,
                                      style: AppTextStyles.getBody(context).copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Transform(
                                    // 중심을 기준으로 좌우 대칭(수평 반전)하기
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                                    child: Icon(Icons.arrow_back_ios_new_rounded, size: context.lg)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: context.hp(2)),
                    GestureDetector(
                      onTap: () {
                        _showTimePicker(context);
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: context.paddingSM,
                        decoration: BoxDecoration(
                          color: AppColors.background(context),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(16.0),
                          ),
                          border: Border.all(
                            color: AppColors.backgroundTertiary(context),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                '활동 시간',
                                style: AppTextStyles.getBody(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(
                                duration,
                                style: AppTextStyles.getBody(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Transform(
                                    // 중심을 기준으로 좌우 대칭(수평 반전)하기
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                                    child: Icon(Icons.arrow_back_ios_new_rounded, size: context.lg)),
                              ),
                            ),
                          ],
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
                            child: Text(
                              '취소',
                              style: AppTextStyles.getBody(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: context.wp(2)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                saveChanges();
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
                            child: Text(
                              '저장',
                              style: AppTextStyles.getBody(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.hp(2)),
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
