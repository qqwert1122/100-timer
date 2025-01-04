import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/widgets/add_todo.dart';
import 'package:provider/provider.dart';

class Todo extends StatefulWidget {
  const Todo({super.key});

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> {
  late final DatabaseService _dbService;
  bool isDetailMode = false;
  final _todoNameController = TextEditingController();
  final _todoDetailController = TextEditingController();
  String _priority = 'medium'; // 기본값
  late Future<List<Map<String, dynamic>>> todosFuture; // Future 선언
  Map<String, Timer> pendingTodos = {}; // 완료 대기 상태 관리

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    todosFuture = _dbService.getTodos(); // 초기 로드
  }

  @override
  void dispose() {
    _todoNameController.dispose();
    _todoDetailController.dispose();
    pendingTodos.values.forEach((timer) => timer.cancel());

    super.dispose();
  }

  final List<Map<String, dynamic>> _todos = [];

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return '높음';
      case 'medium':
        return '중간';
      case 'low':
        return '낮음';
      default:
        return '없음';
    }
  }

  String getDeadlineLabel(String dueDate) {
    // 문자열을 DateTime으로 변환
    final DateTime dueDateTime = DateTime.parse(dueDate);
    final int differenceInDays = dueDateTime.difference(DateTime.now()).inDays;

    // 날짜 차이에 따른 텍스트 반환
    if (differenceInDays >= 0) {
      if (differenceInDays <= 1) return '1일 내';
      if (differenceInDays <= 3) return '3일 내';
      if (differenceInDays <= 7) return '1주일 내';
      if (differenceInDays <= 30) return '1달 내';
    } else {
      final int daysElapsed = differenceInDays.abs();
      if (daysElapsed <= 1) return '1일 경과';
      if (daysElapsed <= 3) return '3일 경과';
      if (daysElapsed <= 7) return '1주일 경과';
      if (daysElapsed <= 30) return '1달 경과';
    }
    return differenceInDays >= 0 ? '30일 이상 남음' : '30일 이상 경과';
  }

  Color getDeadlineColor(String dueDate) {
    final DateTime dueDateTime = DateTime.parse(dueDate);
    final int differenceInDays = dueDateTime.difference(DateTime.now()).inDays;

    if (differenceInDays >= 0) {
      if (differenceInDays <= 1) return Colors.redAccent; // 1일 내
      if (differenceInDays <= 3) return Colors.orange; // 3일 내
      if (differenceInDays <= 7) return Colors.amber; // 7일 내
      return Colors.lime; // 1주일 이상 남음
    } else {
      return Colors.grey; // 경과
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _todos.removeAt(oldIndex);
      _todos.insert(newIndex, item);
    });
  }

  void markAsPending(String todoId) {
    setState(() {
      pendingTodos[todoId] = Timer(const Duration(seconds: 4), () async {
        // 2초 뒤 실제로 완료 처리
        await _dbService.toggleComplete(todoId, true);
        _refreshTodos();
        setState(() {
          pendingTodos.remove(todoId);
        });
      });
    });
  }

  void cancelCompletion(String todoId) {
    if (pendingTodos.containsKey(todoId)) {
      pendingTodos[todoId]?.cancel(); // 타이머 취소
      setState(() {
        pendingTodos.remove(todoId); // 대기 상태에서 제거
      });
    }
  }

  // 목록 새로고침 함수
  Future<void> _refreshTodos() async {
    setState(() {
      todosFuture = _dbService.getTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: context.paddingSM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.hp(3)),
            Text(
              'To Do 모드',
              style: AppTextStyles.getHeadline(context),
            ),
            SizedBox(height: context.hp(1)),
            Text(
              '다른 할일이 있다면 할일을 완료하면서 시간을 기록하세요',
              style: AppTextStyles.getCaption(context),
            ),
            SizedBox(height: context.hp(3)),
            Container(
              padding: context.paddingXS,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                      ),
                      SizedBox(width: context.wp(5)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '선택된 활동',
                            style: AppTextStyles.getCaption(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "To Do List",
                            style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(5)),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '할 일 목록',
                      style: AppTextStyles.getBody(context).copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(isDetailMode ? Icons.label : Icons.label_outline_rounded),
                          color: Colors.grey,
                          onPressed: () {
                            setState(() {
                              isDetailMode = !isDetailMode;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: Colors.blue,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => AddTodoSheet(),
                            ).then((result) {
                              if (result == true) {
                                // Todo 목록 새로고침
                                setState(() {
                                  _refreshTodos();
                                });
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: todosFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      // 에러 로그 출력
                      debugPrint('Error loading todos: ${snapshot.error}');
                      return Center(
                        child: Text(
                          '할 일을 불러오는 중 오류가 발생했습니다.\n${snapshot.error}', // 오류 내용 표시
                          style: AppTextStyles.getBody(context).copyWith(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          '할 일이 없습니다',
                          style: AppTextStyles.getBody(context).copyWith(color: Colors.grey),
                        ),
                      );
                    }
                    final todos = snapshot.data!;
                    return ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todos.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          // 복제한 리스트 사용
                          final mutableTodos = List<Map<String, dynamic>>.from(todos);

                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = mutableTodos.removeAt(oldIndex);
                          mutableTodos.insert(newIndex, item);

                          // DB 업데이트 호출
                          _dbService.reorderTodo(oldIndex, newIndex);

                          // 업데이트된 리스트를 다시 설정
                          todosFuture = Future.value(mutableTodos);
                        });
                      },
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? child) {
                            return Material(
                              elevation: 0,
                              color: Colors.transparent,
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        final isPending = pendingTodos.containsKey(todo['todo_id']); // 완료 대기 상태 확인

                        return Container(
                          key: ValueKey(todo['todo_id']),
                          margin: EdgeInsets.only(bottom: context.hp(2)),
                          child: Slidable(
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                CustomSlidableAction(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  onPressed: (context) async {
                                    await _dbService.deleteTodo(todo['todo_id']);
                                    _refreshTodos();
                                  },
                                  child: Icon(Icons.delete_rounded, size: context.lg),
                                ),
                                CustomSlidableAction(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  onPressed: (context) async {},
                                  child: Icon(Icons.edit_document, size: context.lg),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSecondary(context),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 2,
                                    color: Colors.grey.shade200,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: Stack(
                                      children: [
                                        Checkbox(
                                          value: isPending || todo['is_completed'] == 1,
                                          onChanged: (bool? value) {
                                            if (value == true) {
                                              markAsPending(todo['todo_id']); // 완료 대기 상태로 설정
                                            } else {
                                              cancelCompletion(todo['todo_id']); // 완료 취소
                                            }
                                          },
                                          shape: const CircleBorder(),
                                          activeColor: Colors.blue,
                                        ),
                                        if (isPending)
                                          Positioned.fill(
                                            child: GestureDetector(
                                              onTap: () {
                                                cancelCompletion(todo['todo_id']); // Lottie를 눌러 완료 취소
                                              },
                                              child: Lottie.asset(
                                                'assets/images/check_3.json', // Lottie 파일 경로
                                                repeat: false,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                    size: 24,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          todo['todo_name'] ?? "",
                                          style: TextStyle(
                                            color: isPending ? Colors.grey.shade300 : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          todo['todo_detail'],
                                          style: AppTextStyles.getCaption(context).copyWith(
                                            color: isPending ? Colors.grey.shade300 : Colors.black87,
                                          ),
                                        ),
                                        isDetailMode
                                            ? Row(
                                                children: [
                                                  Container(
                                                    width: context.sm, // 원형의 너비와 높이
                                                    height: context.sm,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle, // 원형으로 설정
                                                      color: _getPriorityColor(todo['priority']), // 우선순위에 따른 색상
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: context.wp(2),
                                                  ),
                                                  Container(
                                                      padding: context.paddingHorizXS,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(16),
                                                        color: ColorService.hexToColor(todo['activity_color']),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            getIconData(todo['activity_icon']),
                                                            size: context.sm,
                                                            color: Colors.white,
                                                          ),
                                                          SizedBox(width: context.wp(1)),
                                                          Text(
                                                            todo['activity_name'],
                                                            style: AppTextStyles.getCaption(context).copyWith(color: Colors.white),
                                                          ),
                                                        ],
                                                      )),
                                                  SizedBox(
                                                    width: context.wp(2),
                                                  ),
                                                  todo['due_date'] != null
                                                      ? Container(
                                                          padding: context.paddingHorizXS,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(16),
                                                            color: getDeadlineColor(todo['due_date']),
                                                          ),
                                                          child: Text(
                                                            getDeadlineLabel(todo['due_date']),
                                                            style: AppTextStyles.getCaption(context).copyWith(color: Colors.white),
                                                          ),
                                                        )
                                                      : Container(),
                                                ],
                                              )
                                            : Container(),
                                      ],
                                    ),
                                    trailing: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.redAccent,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.play_arrow),
                                        iconSize: context.lg,
                                        color: Colors.white,
                                        padding: EdgeInsets.zero,
                                        onPressed: () {},
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: context.hp(3)),
            SizedBox(
              height: context.hp(5),
            ),
          ],
        ),
      ),
    );
  }
}
