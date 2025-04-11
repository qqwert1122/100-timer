import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/add_activity_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';

class ActivityPicker extends StatefulWidget {
  final String selectedActivity;
  final Function(String, String, String, String) onSelectActivity;

  const ActivityPicker({
    super.key,
    required this.selectedActivity,
    required this.onSelectActivity,
  });

  @override
  _ActivityPickerState createState() => _ActivityPickerState();
}

class _ActivityPickerState extends State<ActivityPicker> {
  late Future<List<Map<String, dynamic>>> _activityListFuture;
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  late final defaultAcitivty;

  @override
  void initState() {
    super.initState();
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _refreshActivityList();
    defaultAcitivty = _statsProvider.getDefaultActivity();
  }

  void _refreshActivityList() {
    setState(() {
      _activityListFuture = _statsProvider.getActivities();
    });
  }

  Future<void> _navigateToAddActivityPage(BuildContext context) async {
    final newActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddActivityPage(),
      ),
    );

    if (newActivity != null) {
      _refreshActivityList();
    }
  }

  Future<void> _navigateToEditActivityPage(
      BuildContext context, String activityId, String activityName, String activityIcon, String activityColor) async {
    final updatedActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityPage(
          isEdit: true,
          activityId: activityId,
          activityName: activityName,
          activityIcon: activityIcon,
          activityColor: activityColor,
        ),
      ),
    );

    if (updatedActivity != null) {
      _refreshActivityList();
    }
  }

  Future<void> _deleteActivity(BuildContext context, String activityId, String activityName) async {
    final shouldDelete = await _showDeleteConfirmationDialog(context, activityName);
    if (shouldDelete) {
      await _dbService.deleteActivity(activityId);
      _refreshActivityList();
      if (widget.selectedActivity == activityName) {
        widget.onSelectActivity(defaultAcitivty['acitivty_id'], '전체', 'category_rounded', '#B7B7B7');
      }
      Fluttertoast.showToast(
        msg: "활동이 삭제되었습니다",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context, String activity) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('정말 삭제하시겠습니까?', style: AppTextStyles.getTitle(context).copyWith(color: Colors.redAccent)),
              content: Text(
                '활동을 삭제할 경우 같은 이름으로 재생성 할 수는 있으나 복구할 수 없습니다.',
                style: AppTextStyles.getBody(context),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    '취소',
                    style: AppTextStyles.getTitle(context).copyWith(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    '삭제',
                    style: AppTextStyles.getTitle(context).copyWith(color: Colors.redAccent),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(90),
      padding: context.paddingSM,
      decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          )),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: context.paddingXS,
              width: context.wp(20),
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textPrimary(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: context.paddingSM,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('활동 선택하기', style: AppTextStyles.getTitle(context)),
            ),
          ),
          SizedBox(height: context.hp(1)),
          Expanded(
            child: FutureBuilder(
              future: _activityListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> activities = [];
                if (snapshot.hasData) {
                  activities = snapshot.data as List<Map<String, dynamic>>;
                }

                return ListView.builder(
                  itemCount: activities.length + 1,
                  itemBuilder: (context, index) {
                    if (index == activities.length) {
                      // '활동 추가' 버튼
                      return ListTile(
                        leading: const Icon(Icons.add, color: Colors.blue),
                        title: Text('활동 추가', style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900)),
                        onTap: () {
                          _navigateToAddActivityPage(context);
                        },
                      );
                    }
                    final activity = activities[index];
                    final iconName = activity['activity_icon'];
                    final iconData = getIconImage(iconName);

                    return Slidable(
                      key: Key(activity['activity_id']),
                      closeOnScroll: true,
                      enabled: activity['is_default'] != 1, // 기본 활동이면 슬라이드 비활성화

                      startActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              HapticFeedback.selectionClick();
                            },
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            icon: Icons.push_pin_rounded,
                            label: '고정',
                            flex: 1,
                            autoClose: true,
                          ),
                          SlidableAction(
                            onPressed: (context) {
                              HapticFeedback.selectionClick();
                            },
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.black,
                            icon: Icons.view_list_rounded,
                            label: '순서',
                            flex: 1,
                            autoClose: true,
                          ),
                        ],
                      ),

                      endActionPane: activity['is_default'] != 1
                          ? ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    _navigateToEditActivityPage(
                                      context,
                                      activity['activity_id'],
                                      activity['activity_name'],
                                      activity['activity_icon'],
                                      activity['activity_color'],
                                    );
                                  },
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: '수정',
                                  flex: 1,
                                  autoClose: true,
                                ),
                                SlidableAction(
                                  onPressed: (context) {
                                    _deleteActivity(context, activity['activity_id'], activity['activity_name']);
                                  },
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: '삭제',
                                  flex: 1,
                                ),
                              ],
                            )
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: activity['activity_name'] == widget.selectedActivity ? Colors.red[50] : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0),
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  activity['activity_name'],
                                  style: AppTextStyles.getBody(context).copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: activity['activity_name'] == widget.selectedActivity ? Colors.redAccent.shade200 : null),
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
                              widget.onSelectActivity(
                                activity['activity_id'],
                                activity['activity_name'],
                                activity['activity_icon'],
                                activity['activity_color'],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
