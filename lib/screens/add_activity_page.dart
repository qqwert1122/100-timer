import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:provider/provider.dart';

class AddActivityPage extends StatefulWidget {
  final bool isEdit; // Indicates whether it's in edit mode
  final String? activityId; // The activity ID when editing
  final String? activityName; // The existing activity name when editing
  final String? activityIcon; // The existing activity icon when editing
  final String? activityColor; // The existing activity color when editing

  const AddActivityPage({
    super.key,
    this.isEdit = false,
    this.activityId,
    this.activityName,
    this.activityIcon,
    this.activityColor,
  });

  @override
  _AddActivityPageState createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _activityNameController = TextEditingController();

  String? _selectedIconName;
  int _currentStep = 0;

  // List of HEX color strings
  final List<String> baseColors = [
    // Red shades
    '#E4003A', '#FF0000', '#FF4500', '#FF3EA5', '#FF4C4C', '#FF1493', '#FF69B4', '#FFAAAA',
    // Orange shades
    '#EB5B00', '#FF8C00', '#FF7F50', '#FFD700',
    // Yellow shades
    '#F4CE14', '#FFFF00', '#FAFFAF',
    // Green shades
    '#A1DD70', '#73EC8B', '#32CD32', '#008000',
    // Blue shades
    '#00CED1', '#1E90FF', '#7695FF', '#0000FF', '#1C1678',
    // Navy shades
    '#6A5ACD', '#050C9C', '#240750',
    // Purple shades
    '#E59BE9', '#8B00FF', '#6A5ACD', '#4B0082',
    // Gray and Black
    '#B7B7B7', '#000000',
  ];

  // List of opacities
  final List<double> opacities = [1.0, 0.8, 0.6, 0.4, 0.2];

  // Selected base color (as HEX string)
  String? selectedBaseColor;

  bool isDuplicate = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _activityNameController.text = widget.activityName ?? '';
      _selectedIconName = widget.activityIcon;
      selectedBaseColor = widget.activityColor;
    }
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    super.dispose();
  }

  bool get isActivityNameValid => _activityNameController.text.trim().isNotEmpty && !isDuplicate;

  bool get isIconSelected => _selectedIconName != null;

  bool get isColorSelected => selectedBaseColor != null;

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() {
          _currentStep++;
        });
      } else {
        Fluttertoast.showToast(
          msg: "활동 이름을 입력해주세요",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        HapticFeedback.lightImpact();
      }
    } else if (_currentStep == 1) {
      if (isIconSelected) {
        setState(() {
          _currentStep++;
        });
      } else {
        Fluttertoast.showToast(
          msg: "아이콘을 선택해주세요",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.redAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _submit() async {
    final String activityName = _activityNameController.text.trim();
    final String? iconName = _selectedIconName;

    if (activityName.isEmpty || iconName == null || selectedBaseColor == null) {
      Fluttertoast.showToast(
        msg: "활동 이름을 입력하고 아이콘, 색상을 선택해주세요",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return;
    }

    final dbService = Provider.of<DatabaseService>(context, listen: false);

    // Duplicate name check
    bool duplicate = await dbService.isActivityNameDuplicate(activityName);

    // Check for duplicates, but allow the same name if editing the same activity
    if (duplicate && (!widget.isEdit || activityName != widget.activityName)) {
      setState(() {
        isDuplicate = true;
      });
      _formKey.currentState?.validate();
      return;
    } else {
      setState(() {
        isDuplicate = false;
      });
    }

    try {
      String colorValue = selectedBaseColor!;

      if (widget.isEdit) {
        await dbService.updateActivity(widget.activityId!, activityName, iconName, colorValue, false);
        Navigator.pop(context, {'name': activityName, 'icon': iconName, 'color': colorValue});
      } else {
        await dbService.addActivity(activityName, iconName, colorValue, false);
        Fluttertoast.showToast(
          msg: "활동이 성공적으로 추가되었습니다",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.blueAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        Navigator.pop(context, {'name': activityName, 'icon': iconName, 'color': colorValue});
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

  Widget buildNextAndBackButtons() {
    bool isNextButtonEnabled = false;
    String nextButtonText = '';

    if (_currentStep == 0) {
      isNextButtonEnabled = isActivityNameValid;
      nextButtonText = '다음';
    } else if (_currentStep == 1) {
      isNextButtonEnabled = isIconSelected;
      nextButtonText = '다음';
    } else if (_currentStep == 2) {
      isNextButtonEnabled = isColorSelected;
      nextButtonText = '저장';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 'Back' button
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep > 0 ? _prevStep : HapticFeedback.lightImpact,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _currentStep > 0 ? Colors.red : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '뒤로',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 'Next' or 'Save' button
          Expanded(
            child: ElevatedButton(
              onPressed: isNextButtonEnabled ? (_currentStep < 2 ? _nextStep : _submit) : HapticFeedback.lightImpact,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isNextButtonEnabled ? Colors.blueAccent : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                nextButtonText,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

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
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              hintText: '예시. 영단어 암기',
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
              bool duplicate = await Provider.of<DatabaseService>(context, listen: false).isActivityNameDuplicate(value);
              setState(() {
                isDuplicate = duplicate;
              });
              _formKey.currentState?.validate(); // 입력 변경 시마다 validate 호출
            },
          ),
        ),
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
          {'icon': getIconData('fitness_center_rounded'), 'name': 'fitness_center_rounded'},
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
          {'icon': getIconData('fitness_center_rounded'), 'name': 'fitness_center_rounded'},
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                          color: _selectedIconName == iconName ? Colors.blue.withOpacity(0.3) : Colors.transparent,
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

    Widget buildColorSelection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "선택된 색상",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(
                width: 10,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 30,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 2.0),
                decoration: BoxDecoration(
                  color: ColorService.hexToColor(selectedBaseColor.toString()),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: baseColors.map((baseColor) {
                bool isSelected = selectedBaseColor == baseColor;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBaseColor = baseColor;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: opacities.map((opacity) {
                        Color colorWithOpacity = ColorService.hexToColor(baseColor).withOpacity(opacity);

                        return Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.symmetric(vertical: 2.0),
                          decoration: BoxDecoration(
                            color: colorWithOpacity,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          InkWell(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.info_outlined,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  title: Text(
                    '베이스컬러를 선택해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '활동을 오래할수록 색상이 점점 진해집니다.\n위에서 색상의 변화를 미리보고 마음에 드는 베이스 컬러를 선택해주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                    controlsBuilder: (BuildContext context, ControlsDetails details) {
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
                        content: _currentStep == 0 ? buildActivityName() : Container(),
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
                        content: _currentStep == 1 ? buildIconSelection() : Container(),
                        isActive: _currentStep == 1,
                      ),
                      Step(
                        title: _currentStep == 2
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '색상을',
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
                        content: _currentStep == 2 ? buildColorSelection() : Container(),
                        isActive: _currentStep == 2,
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
