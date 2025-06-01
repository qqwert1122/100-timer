import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';

class AddTodoSheet extends StatefulWidget {
  const AddTodoSheet({
    super.key,
  });

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  final _todoNameController = TextEditingController();
  final _todoDetailController = TextEditingController();
  String _priority = 'medium';
  String? _selectedActivityId;
  String? _selectedActivityName;
  String? _selectedActivityIcon;
  String? _selectedActivityColor;

  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _initDefaultActivity();
    _activitiesFuture = _dbService.getActivities();
  }

  final List<Map<String, dynamic>> priorities = [
    {'value': 'high', 'label': '높음', 'color': Colors.red},
    {'value': 'medium', 'label': '중간', 'color': Colors.orange},
    {'value': 'low', 'label': '낮음', 'color': Colors.green},
  ];

  Future<void> _initDefaultActivity() async {
    final defaultActivity = await _statsProvider.getDefaultActivity();
    if (defaultActivity != null) {
      setState(() {
        _selectedActivityId = defaultActivity['activity_id'];
        _selectedActivityName = defaultActivity['activity_name'];
        _selectedActivityIcon = defaultActivity['activity_icon'];
        _selectedActivityColor = defaultActivity['activity_color'];
      });
    }
  }

  // 날짜 설정 함수

  DateTime? _selectedDeadline;
  bool _isCustomDate = false;

  void _setDeadline(DateTime date) {
    setState(() {
      _selectedDeadline = date;
      _isCustomDate = false;
      logger.d('Selected deadline: $_selectedDeadline'); // 추가된 로그
    });
  }

  void _creatTodo() async {
    if (_todoNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할 일을 입력해주세요')),
      );
      return;
    }

    try {
      final todo = {
        'todo_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'todo_name': _todoNameController.text,
        'todo_detail': _todoDetailController.text.trim(),
        'priority': _priority,
        'activity_id': _selectedActivityId,
        'activity_name': _selectedActivityName,
        'activity_icon': _selectedActivityIcon,
        'activity_color': _selectedActivityColor,
        'due_date': _selectedDeadline?.toIso8601String(),
        'is_completed': 0,
        'is_deleted': 0,
      };

      logger.d('Todo to save: $todo'); // todo 데이터 출력
      await _dbService.createTodo(todo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('할 일이 등록되었습니다')),
        );
        Navigator.pop(context, true); // 목록 새로고침을 위해 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('할 일 등록에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _showDatePicker() async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        DateTime currentDate = _selectedDeadline ?? DateTime.now();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '마감일 선택',
                      style: AppTextStyles.getTitle(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 달력 위젯
                CalendarDatePicker(
                  initialDate: currentDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onDateChanged: (DateTime date) {
                    currentDate = date;
                  },
                ),

                // 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '취소',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, currentDate),
                      child: Text(
                        '확인',
                        style: AppTextStyles.getBody(context).copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDeadline = selectedDate;
        _isCustomDate = true;
      });
    }
    logger.d('Selected deadline: $_selectedDeadline'); // 선택된 날짜 로그 출력
  }

// 선택된 날짜에 따른 라벨 반환
  String _getDeadlineLabel(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff <= 1) return '1일 내';
    if (diff <= 3) return '3일 내';
    if (diff <= 7) return '7일 내';
    if (diff <= 30) return '한달 내';
    return '달력';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(80),
      padding: context.paddingSM,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: context.paddingXS,
                width: context.wp(20),
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.buttonSecondary(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: context.hp(2)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('할 일 추가하기', style: AppTextStyles.getTitle(context)),
            ),
            SizedBox(height: context.hp(2)),
            TextField(
              controller: _todoNameController,
              decoration: InputDecoration(
                labelText: '할 일',
                hintText: '할 일을 입력하세요',
                filled: true,
                fillColor: Colors.grey[100],
                floatingLabelAlignment: FloatingLabelAlignment.start,
                alignLabelWithHint: false,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: context.hp(2)),
            TextField(
              controller: _todoDetailController,
              maxLines: 5, // 최대 5줄까지 표시
              minLines: 3, // 최소 3줄 유지
              decoration: InputDecoration(
                labelText: '상세내용',
                hintText: '상세한 내용을 입력하세요 (선택사항)',
                filled: true,
                fillColor: Colors.grey[100],
                floatingLabelAlignment: FloatingLabelAlignment.start,
                alignLabelWithHint: false,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: context.hp(8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '활동',
                    style: AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                SizedBox(
                  height: context.hp(6),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _activitiesFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.grey));
                      }

                      final activities = snapshot.data!;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          final isSelected = activity['activity_id'] == _selectedActivityId;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedActivityId = activity['activity_id'];
                                _selectedActivityName = activity['activity_name'];
                                _selectedActivityIcon = activity['activity_icon'];
                                _selectedActivityColor = activity['activity_color'];
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: context.paddingXS,
                              margin: context.paddingXS,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorService.hexToColor(activity['activity_color'])
                                    : AppColors.backgroundSecondary(context),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Colors.grey.shade300,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: context.wp(1)),
                                  Image.asset(
                                    getIconImage(activity['activity_icon']),
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
                                  SizedBox(width: context.wp(2)),
                                  Text(
                                    activity['activity_name'],
                                    style: AppTextStyles.getCaption(context).copyWith(
                                      color: isSelected ? Colors.white : Colors.grey,
                                      fontWeight: isSelected ? FontWeight.bold : null,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(width: context.wp(1)),
                                ],
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
            SizedBox(
              height: context.hp(2),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Text(
                          '마감 날짜',
                          style: AppTextStyles.getBody(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: context.wp(4)),
                        if (_selectedDeadline != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              DateFormat('yyyy/MM/dd').format(_selectedDeadline!),
                              style: AppTextStyles.getCaption(context).copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )),
                SizedBox(height: context.hp(1)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDeadlineButton(
                        '1일 내',
                        () => _setDeadline(DateTime.now().add(const Duration(days: 1))),
                      ),
                      const SizedBox(width: 8),
                      _buildDeadlineButton(
                        '3일 내',
                        () => _setDeadline(DateTime.now().add(const Duration(days: 3))),
                      ),
                      const SizedBox(width: 8),
                      _buildDeadlineButton(
                        '7일 내',
                        () => _setDeadline(DateTime.now().add(const Duration(days: 7))),
                      ),
                      const SizedBox(width: 8),
                      _buildDeadlineButton(
                        '한달 내',
                        () => _setDeadline(DateTime.now().add(const Duration(days: 30))),
                      ),
                      const SizedBox(width: 8),
                      _buildDeadlineButton(
                        '달력',
                        _showDatePicker,
                        icon: Icons.calendar_month,
                        isCalendarButton: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.hp(3)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '우선순위',
                    style: AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: context.hp(1)),
                Row(
                  children: priorities
                      .map((priority) => GestureDetector(
                            onTap: () => setState(() => _priority = priority['value']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: context.paddingXS,
                              padding: context.paddingXS,
                              decoration: BoxDecoration(
                                color: _priority == priority['value'] ? priority['color'] : AppColors.backgroundSecondary(context),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Colors.grey.shade300,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '  ${priority['label']}  ',
                                style: AppTextStyles.getCaption(context).copyWith(
                                  color: _priority == priority['value'] ? Colors.white : Colors.grey,
                                  fontWeight: _priority == priority['value'] ? FontWeight.bold : null,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                )
              ],
            ),
            const Spacer(),
            SizedBox(height: context.hp(5)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _creatTodo();
                },
                child: Text(
                  '저장하기',
                  style: AppTextStyles.getBody(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineButton(String label, VoidCallback onTap, {IconData? icon, bool isCalendarButton = false}) {
    final isSelected = !isCalendarButton && _selectedDeadline != null && label == _getDeadlineLabel(_selectedDeadline!);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: context.paddingXS,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : AppColors.backgroundSecondary(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Colors.grey.shade300,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: context.md,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            if (icon != null) SizedBox(width: context.wp(1)),
            Text(
              label,
              style: AppTextStyles.getCaption(context).copyWith(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
