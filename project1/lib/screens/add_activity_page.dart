import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/utils/database_service.dart';
import 'package:provider/provider.dart';

class AddActivityPage extends StatefulWidget {
  final bool isEdit; // 생성 또는 수정 모드 구분
  final String? activityListId; // 수정할 때의 activity_list_id
  final String? activityName; // 수정할 때 기존 활동 이름
  final String? activityIcon; // 수정할 때 기존 활동 아이콘
  final String userId; // 사용자 ID

  const AddActivityPage({
    Key? key,
    required this.userId,
    this.isEdit = false,
    this.activityListId,
    this.activityName,
    this.activityIcon,
  }) : super(key: key);

  @override
  _AddActivityPageState createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _activityNameController = TextEditingController();
  String? _selectedIconName;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _activityNameController.text = widget.activityName ?? '';
      _selectedIconName = widget.activityIcon;
    }
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    super.dispose();
  }

  bool get isActivityNameValid =>
      _activityNameController.text.trim().isNotEmpty;
  bool get isIconSelected => _selectedIconName != null;

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _submit() async {
    final String activityName = _activityNameController.text.trim();
    final String? iconName = _selectedIconName;

    if (activityName.isEmpty || iconName == null) {
      Fluttertoast.showToast(
        msg: "활동 이름과 아이콘을 입력해주세요",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return;
    }

    final dbService = Provider.of<DatabaseService>(context, listen: false);

    try {
      if (widget.isEdit) {
        await dbService.updateActivityList(
            widget.activityListId!, activityName, iconName);
        Navigator.pop(context, {'name': activityName, 'icon': iconName});
      } else {
        await dbService.addActivityList(
            widget.userId, activityName, iconName); // 수정된 부분
        Fluttertoast.showToast(
          msg: "활동이 성공적으로 추가되었습니다",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.blueAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        Navigator.pop(context, {'name': activityName, 'icon': iconName});
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "활동 저장 중 오류가 발생했습니다: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    Widget buildActivityName() {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _activityNameController,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            maxLength: 15,
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                color: isDarkMode ? Colors.white : Colors.black,
              )),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              hintText: '예시. 타이머 어플 코딩',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '활동 이름을 입력해주세요';
              }
              return null;
            },
          ),
        ),
      );
    }

    Widget buildIconSelection() {
      final Map<String, List<Map<String, dynamic>>> iconCategories = {
        '공부': [
          {'icon': Icons.school, 'name': 'school'},
          {'icon': Icons.local_library, 'name': 'library'},
          // ... 추가 아이콘
        ],
        '업무': [
          {'icon': Icons.work, 'name': 'work'},
          {'icon': Icons.business, 'name': 'business'},
          // ... 추가 아이콘
        ],
        // ... 추가 카테고리
      };

      return Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: iconCategories.entries.map((entry) {
            final categoryName = entry.key;
            final icons = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: icons.length,
                  itemBuilder: (context, index) {
                    final iconData = icons[index]['icon'];
                    final iconName = icons[index]['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIconName = iconName;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedIconName == iconName
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          iconData,
                          size: 24,
                          color: isDarkMode ? Colors.blueGrey : null,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      );
    }

    Widget buildNextAndBackButtons() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // '뒤로' 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStep > 0 ? _prevStep : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '뒤로',
                  style: TextStyle(
                      color: _currentStep > 0
                          ? Colors.white
                          : (isDarkMode ? Colors.white12 : Colors.black12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // '다음' 또는 '저장' 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStep == 0
                    ? _nextStep
                    : (isIconSelected ? _submit : null),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: (isActivityNameValid || isIconSelected)
                      ? Colors.blueAccent
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == 0 ? '다음' : '저장',
                  style: TextStyle(
                    color: ((_currentStep == 0 && isActivityNameValid) ||
                            (_currentStep > 0 && isIconSelected))
                        ? Colors.white
                        : (isDarkMode ? Colors.white12 : Colors.black12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          title: Text(
            widget.isEdit ? '활동 수정' : '활동 추가',
            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: Theme(
                data: ThemeData(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.blueAccent,
                  ),
                ),
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: _currentStep < 1
                      ? () => setState(() => _currentStep += 1)
                      : null,
                  onStepCancel: _currentStep > 0
                      ? () => setState(() => _currentStep -= 1)
                      : null,
                  controlsBuilder:
                      (BuildContext context, ControlsDetails details) {
                    return const SizedBox();
                  },
                  steps: [
                    Step(
                      title: _currentStep == 0
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '활동 이름을',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  Text(
                                    '입력해주세요',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      content:
                          _currentStep == 0 ? buildActivityName() : Container(),
                      isActive: _currentStep == 0,
                    ),
                    Step(
                      title: _currentStep == 1
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '아이콘을',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  Text(
                                    '선택해주세요',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      content: _currentStep == 1
                          ? buildIconSelection()
                          : Container(),
                      isActive: _currentStep == 1,
                    ),
                  ],
                ),
              ),
            ),
            buildNextAndBackButtons()
          ],
        ),
      ),
    );
  }
}
