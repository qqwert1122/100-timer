import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
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
  String? _nameErrorMessage;

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
      _activityNameController.text.trim().isNotEmpty &&
      _nameErrorMessage == null;

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

    // 중복 이름 확인
    bool isDuplicate =
        await dbService.isActivityNameDuplicate(widget.userId, activityName);

    if (isDuplicate && !widget.isEdit) {
      setState(() {
        _nameErrorMessage = '중복된 이름이 있습니다'; // 에러 메시지 설정
      });
      return;
    } else {
      setState(() {
        _nameErrorMessage = null; // 에러 메시지 초기화
      });
    }

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
    bool isDuplicate = false;

    Widget buildActivityName() {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
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
                    } else if (isDuplicate) {
                      return '중복된 이름이 있습니다';
                    }
                    return null;
                  },
                  onChanged: (value) async {
                    // 입력된 이름 변경 시 중복 확인
                    isDuplicate = await Provider.of<DatabaseService>(context,
                            listen: false)
                        .isActivityNameDuplicate(widget.userId, value);
                    _formKey.currentState?.validate(); // 입력 변경 시마다 validate 호출
                  },
                ),
              ],
            )),
      );
    }

    Widget buildIconSelection() {
      final Map<String, List<Map<String, dynamic>>> iconCategories = {
        '추천': [
          {'icon': getIconData('category_rounded'), 'name': 'category_rounded'},
          {'icon': getIconData('school_rounded'), 'name': 'school_rounded'},
          {'icon': getIconData('library'), 'name': 'library'},
          {'icon': getIconData('computer'), 'name': 'computer'},
          {'icon': getIconData('edit'), 'name': 'edit'},
          {'icon': getIconData('work_rounded'), 'name': 'work_rounded'},
          {'icon': getIconData('art'), 'name': 'art'},
          {'icon': getIconData('library_books'), 'name': 'library_books'},
          {'icon': getIconData('language'), 'name': 'language'},
          {
            'icon': getIconData('fitness_center_rounded'),
            'name': 'fitness_center_rounded'
          },
        ],
        '자기계발': [
          {'icon': getIconData('school_rounded'), 'name': 'school_rounded'},
          {'icon': getIconData('library'), 'name': 'library'},
          {'icon': getIconData('computer'), 'name': 'computer'},
          {'icon': getIconData('edit'), 'name': 'edit'},
          {'icon': getIconData('ideas'), 'name': 'ideas'},
          {'icon': getIconData('tools'), 'name': 'tools'},
          {'icon': getIconData('healing'), 'name': 'healing'},
          {'icon': getIconData('spa'), 'name': 'spa'},
          {'icon': getIconData('gavel'), 'name': 'gavel'},
          {'icon': getIconData('group_work'), 'name': 'group_work'},
          {'icon': getIconData('security'), 'name': 'security'},
          {'icon': getIconData('volunteer'), 'name': 'volunteer'},
          {'icon': getIconData('mentoring'), 'name': 'mentoring'},
          {'icon': getIconData('library_books'), 'name': 'library_books'},
          {'icon': getIconData('language'), 'name': 'language'},
        ],
        '업무': [
          {'icon': getIconData('work_rounded'), 'name': 'work_rounded'},
          {'icon': getIconData('business'), 'name': 'business'},
          {'icon': getIconData('phone'), 'name': 'phone'},
          {'icon': getIconData('email'), 'name': 'email'},
          {'icon': getIconData('timeline'), 'name': 'timeline'},
          {'icon': getIconData('chart'), 'name': 'chart'},
          {'icon': getIconData('keyboard'), 'name': 'keyboard'},
          {'icon': getIconData('money'), 'name': 'money'},
          {'icon': getIconData('meeting'), 'name': 'meeting'},
          {'icon': getIconData('analytics'), 'name': 'analytics'},
          {'icon': getIconData('assignment'), 'name': 'assignment'},
          {'icon': getIconData('person_add'), 'name': 'person_add'},
          {'icon': getIconData('print'), 'name': 'print'},
          {'icon': getIconData('folder_open'), 'name': 'folder_open'},
          {'icon': getIconData('fact_check'), 'name': 'fact_check'},
          {'icon': getIconData('science'), 'name': 'science'},
          {'icon': getIconData('architecture'), 'name': 'architecture'},
          {'icon': getIconData('art'), 'name': 'art'},
        ],
        '운동': [
          {
            'icon': getIconData('fitness_center_rounded'),
            'name': 'fitness_center_rounded'
          },
          {'icon': getIconData('running'), 'name': 'running'},
          {'icon': getIconData('bike'), 'name': 'bike'},
          {'icon': getIconData('soccer'), 'name': 'soccer'},
          {'icon': getIconData('park'), 'name': 'park'},
          {'icon': getIconData('golf'), 'name': 'golf'},
          {'icon': getIconData('swimming'), 'name': 'swimming'},
          {'icon': getIconData('tennis'), 'name': 'tennis'},
          {'icon': getIconData('basketball'), 'name': 'basketball'},
          {'icon': getIconData('volleyball'), 'name': 'volleyball'},
          {'icon': getIconData('mma'), 'name': 'mma'},
          {'icon': getIconData('cricket'), 'name': 'cricket'},
          {'icon': getIconData('esports'), 'name': 'esports'},
          {'icon': getIconData('hiking'), 'name': 'hiking'},
        ],
        '일상': [
          {'icon': getIconData('home'), 'name': 'home'},
          {'icon': getIconData('restaurant'), 'name': 'restaurant'},
          {'icon': getIconData('pets'), 'name': 'pets'},
          {'icon': getIconData('cleaning'), 'name': 'cleaning'},
          {'icon': getIconData('coffee'), 'name': 'coffee'},
          {'icon': getIconData('hospital'), 'name': 'hospital'},
          {'icon': getIconData('shopping'), 'name': 'shopping'},
          {'icon': getIconData('movie'), 'name': 'movie'},
          {'icon': getIconData('music'), 'name': 'music'},
          {'icon': getIconData('flight'), 'name': 'flight'},
          {'icon': getIconData('hotel'), 'name': 'hotel'},
          {'icon': getIconData('camera'), 'name': 'camera'},
          {'icon': getIconData('car'), 'name': 'car'},
          {'icon': getIconData('boat'), 'name': 'boat'},
          {'icon': getIconData('train'), 'name': 'train'},
          {'icon': getIconData('subway'), 'name': 'subway'},
          {'icon': getIconData('walk'), 'name': 'walk'},
          {'icon': getIconData('cafe'), 'name': 'cafe'},
          {'icon': getIconData('tv'), 'name': 'tv'},
          {'icon': getIconData('gaming'), 'name': 'gaming'},
          {'icon': getIconData('theater'), 'name': 'theater'},
          {'icon': getIconData('radio'), 'name': 'radio'},
          {'icon': getIconData('headset'), 'name': 'headset'},
          {'icon': getIconData('mic'), 'name': 'mic'},
          {'icon': getIconData('music_video'), 'name': 'music_video'},
          {'icon': getIconData('bus'), 'name': 'bus'},
          {'icon': getIconData('painting'), 'name': 'painting'},
          {'icon': getIconData('map'), 'name': 'map'},
          {'icon': getIconData('photo'), 'name': 'photo'},
          {'icon': getIconData('beach'), 'name': 'beach'},
          {'icon': getIconData('bubble_chart'), 'name': 'bubble_chart'},
          {'icon': getIconData('wine_bar'), 'name': 'wine_bar'},
          {'icon': getIconData('weather'), 'name': 'weather'},
          {'icon': getIconData('kabaddi'), 'name': 'kabaddi'},
          {'icon': getIconData('village'), 'name': 'village'},
        ],
      };

      return Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
          children: iconCategories.entries.map((entry) {
            final categoryName = entry.key;
            final icons = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
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
                onPressed: _currentStep == 0 && isDuplicate == false
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
                child: SingleChildScrollView(
                  child: Stepper(
                    physics: const ClampingScrollPhysics(),
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
                        content: _currentStep == 0
                            ? buildActivityName()
                            : Container(),
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
            ),
            buildNextAndBackButtons()
          ],
        ),
      ),
    );
  }
}
