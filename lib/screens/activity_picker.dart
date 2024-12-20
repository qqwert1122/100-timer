import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/add_activity_page.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:provider/provider.dart';

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
  late final DatabaseService _dbService; // 주입받을 DatabaseService
  late final defaultAcitivty;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false); // DatabaseService 주입
    _refreshActivityList();
    defaultAcitivty = _dbService.getDefaultActivity();
  }

  void _refreshActivityList() {
    setState(() {
      _activityListFuture = _dbService.getActivities();
    });
  }

  Future<void> _navigateToAddActivityPage(BuildContext context) async {
    Map<String, dynamic>? userData = await _dbService.getUser();
    final newActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityPage(userId: userData?['uid']),
      ),
    );

    if (newActivity != null) {
      _refreshActivityList();
    }
  }

  Future<void> _navigateToEditActivityPage(
      BuildContext context, String activityId, String activityName, String activityIcon, String activityColor) async {
    Map<String, dynamic>? userData = await _dbService.getUser();
    final updatedActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityPage(
          userId: userData?['uid'],
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
              title: const Text(
                '정말 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text('$activity 활동을 삭제할 경우 해당 기록이 모두 삭제되며 복구할 수 없습니다.'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        children: [
          // 제목
          const Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '활동 선택하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 활동 리스트
          Expanded(
            child: FutureBuilder(
              future: _activityListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('오류가 발생했습니다.'));
                }

                final activities = snapshot.data as List<Map<String, dynamic>>?;

                if (activities == null || activities.isEmpty) {
                  return const Center(child: Text('활동이 없습니다.'));
                }

                return ListView.builder(
                  itemCount: activities.length + 1,
                  itemBuilder: (context, index) {
                    if (index == activities.length) {
                      // '활동 추가' 버튼
                      return ListTile(
                        leading: const Icon(Icons.add, color: Colors.blue),
                        title: const Text(
                          '활동 추가',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          _navigateToAddActivityPage(context);
                        },
                      );
                    }
                    final activity = activities[index];
                    final iconName = activity['activity_icon'];
                    final iconData = getIconData(iconName);

                    return Slidable(
                      key: Key(activity['activity_id']),
                      closeOnScroll: true,
                      enabled: activity['is_default'] != 1, // 기본 활동이면 슬라이드 비활성화

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
                                  flex: 1,
                                  autoClose: true,
                                ),
                                SlidableAction(
                                  onPressed: (context) {
                                    _deleteActivity(context, activity['activity_id'], activity['activity_name']);
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  flex: 1,
                                ),
                              ],
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: ListTile(
                          leading: Icon(iconData,
                              color: activity['activity_name'] == widget.selectedActivity ? Colors.redAccent.shade200 : null),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                activity['activity_name'],
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: activity['activity_name'] == widget.selectedActivity ? Colors.redAccent.shade200 : null),
                              ),
                              const SizedBox(
                                width: 10,
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
                            widget.onSelectActivity(
                              activity['activity_id'],
                              activity['activity_name'],
                              activity['activity_icon'],
                              activity['activity_color'],
                            );
                          },
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
