import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/add_activity_page.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';

class ActivityPicker extends StatefulWidget {
  final Function(String, String, String) onSelectActivity;
  final String selectedActivity; // 현재 선택된 액티비티

  ActivityPicker({
    super.key,
    required this.onSelectActivity,
    required this.selectedActivity,
  });

  @override
  _ActivityPickerState createState() => _ActivityPickerState();
}

class _ActivityPickerState extends State<ActivityPicker> {
  final DatabaseService dbService = DatabaseService(); // 데이터베이스 서비스 인스턴스
  String userId = 'v3_4'; // 사용자 ID 예시 (실제 앱에서는 유저 ID를 동적으로 받을 수 있음)

  void _navigateToAddActivityPage(BuildContext context) async {
    // AddActivityPage에서 새로운 액티비티를 추가하고, 그 데이터를 반환받음
    final newActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddActivityPage(),
      ),
    );

    // 만약 새 활동이 추가되었다면 (null이 아니면) 화면을 업데이트
    if (newActivity != null) {
      // 추가된 액티비티를 즉시 반영하는 로직
      setState(() {
        // 리스트에 추가된 활동을 추가
        dbService.getActivityList(userId); // ActivityList를 다시 불러오기
      });
    }
  }

  void _navigateToEditActivityPage(BuildContext context, String activityListId,
      String activityName, String activityIcon) async {
    final updatedActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityPage(
          isEdit: true, // 수정 모드로 설정
          activityListId: activityListId, // 수정할 활동의 ID
          activityName: activityName, // 기존 활동 이름
          activityIcon: activityIcon, // 기존 활동 아이콘
        ),
      ),
    );

    // 만약 수정된 액티비티가 있으면 UI 업데이트
    if (updatedActivity != null) {
      setState(() {
        dbService.getActivityList(userId); // 리스트 다시 불러오기
      });
    }
  }

  void _deleteActivity(
      BuildContext context, String activityListId, String activityName) async {
    final shouldDelete =
        await _showDeleteConfirmationDialog(context, activityName);
    if (shouldDelete) {
      // 삭제 확인되었을 때만 삭제 실행
      await dbService.deleteActivity(activityListId); // DB에서 삭제
      setState(() {
        dbService.getActivityList(userId); // 삭제 후 UI 업데이트
        if (widget.selectedActivity == activityName) {
          widget.onSelectActivity(
              '전체', 'category_rounded', '${userId}1'); // '전체'와 그에 해당하는 아이콘을 선택
        }
      });
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

  // 삭제 확인 다이얼로그
  Future<bool> _showDeleteConfirmationDialog(
      BuildContext context, String activity) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 외부 클릭으로 다이얼로그 닫히지 않음
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
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false); // 취소 시 false 반환
                  },
                ),
                TextButton(
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true); // 삭제 시 true 반환
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 다이얼로그가 null을 반환하면 기본적으로 false 처리
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 8,
            ),
            child: Align(
              alignment: Alignment.centerLeft, // 제목을 왼쪽에 정렬
              child: Text(
                '활동 선택하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10), // 제목과 리스트 간 간격
          Expanded(
            child: FutureBuilder(
              future: dbService.getActivityList(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('오류가 발생했습니다.'));
                }

                final activities = snapshot.data as List<Map<String, dynamic>>;

                return ListView.builder(
                  itemCount: activities.length + 1,
                  itemBuilder: (context, index) {
                    if (index == activities.length) {
                      // 마지막 항목은 '활동 추가' 버튼
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
                          // 활동 추가 페이지로 이동
                          _navigateToAddActivityPage(context);
                        },
                      );
                    }
                    final activity = activities[index];
                    final iconName = activity['activity_icon'];
                    final iconData = getIconData(iconName); // 아이콘 매핑

                    if (activity['activity_name'] == '전체') {
                      return ListTile(
                        leading: Icon(
                          iconData,
                          color: activity['activity_name'] ==
                                  widget.selectedActivity
                              ? Colors.redAccent.shade200
                              : null,
                        ),
                        title: Text(
                          activity['activity_name'],
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activity['activity_name'] ==
                                      widget.selectedActivity
                                  ? Colors.redAccent.shade200
                                  : null),
                        ),
                        onTap: () {
                          widget.onSelectActivity(
                            activity['activity_name'],
                            activity['activity_icon'],
                            activity['activity_list_id'],
                          ); // 선택된 액티비티 전달
                        },
                      );
                    }

                    return Slidable(
                      key: Key(activity['activity_list_id']),
                      closeOnScroll: true,
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              _navigateToEditActivityPage(
                                context,
                                activity['activity_list_id'],
                                activity['activity_name'],
                                activity['activity_icon'],
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
                              _deleteActivity(
                                  context,
                                  activity['activity_list_id'],
                                  activity['activity_name']);
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            flex: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0), // 항목 간 간격을 좁게 설정
                        child: ListTile(
                          leading: Icon(iconData,
                              color: activity['activity_name'] ==
                                      widget.selectedActivity
                                  ? Colors.redAccent.shade200
                                  : null), // 아이콘을 왼쪽에 표시
                          title: Text(
                            activity['activity_name'],
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: activity['activity_name'] ==
                                        widget.selectedActivity
                                    ? Colors.redAccent.shade200
                                    : null),
                          ),
                          onTap: () {
                            widget.onSelectActivity(
                              activity['activity_name'],
                              activity['activity_icon'],
                              activity['activity_list_id'],
                            ); // 선택된 액티비티 전달
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
    ;
  }
}
