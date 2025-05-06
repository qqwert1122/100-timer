import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
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
    '#E4003A', '#FF0000', '#FF4500', '#FF3EA5', '#FF4C4C', '#FF1493', '#FF69B4',
    '#FFAAAA',
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

  bool get isActivityNameValid =>
      _activityNameController.text.trim().isNotEmpty && !isDuplicate;

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
        await dbService.updateActivity(
          activityId: widget.activityId!,
          newActivityName: activityName,
          newActivityIcon: iconName,
          newActivityColor: colorValue,
          newIsFavorite: 0,
        );
        Navigator.pop(context,
            {'name': activityName, 'icon': iconName, 'color': colorValue});
      } else {
        await dbService.addActivity(
          activityName: activityName,
          activityIcon: iconName,
          activityColor: colorValue,
          isDefault: false,
          parentActivityId: null,
        );
        Fluttertoast.showToast(
          msg: "활동이 성공적으로 추가되었습니다",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.blueAccent.shade200,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        Navigator.pop(context,
            {'name': activityName, 'icon': iconName, 'color': colorValue});
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
              onPressed:
                  _currentStep > 0 ? _prevStep : HapticFeedback.lightImpact,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _currentStep > 0
                    ? Colors.red
                    : AppColors.backgroundSecondary(context),
                foregroundColor: AppColors.background(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '뒤로',
                style: AppTextStyles.getBody(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 'Next' or 'Save' button
          Expanded(
            child: ElevatedButton(
              onPressed: isNextButtonEnabled
                  ? (_currentStep < 2 ? _nextStep : _submit)
                  : HapticFeedback.lightImpact,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isNextButtonEnabled
                    ? Colors.blueAccent
                    : AppColors.backgroundSecondary(context),
                foregroundColor: isNextButtonEnabled
                    ? Colors.white
                    : AppColors.background(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                nextButtonText,
                style: AppTextStyles.getBody(context).copyWith(
                  fontWeight: FontWeight.w900,
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
            style: AppTextStyles.getBody(context),
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
              hintStyle: AppTextStyles.getBody(context)
                  .copyWith(color: Colors.grey.shade400),
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
              bool duplicate =
                  await Provider.of<DatabaseService>(context, listen: false)
                      .isActivityNameDuplicate(value);
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
          {'icon': getIconImage('category'), 'name': 'category'},
          {'icon': getIconImage('business'), 'name': 'business'},
          {'icon': getIconImage('school'), 'name': 'school'},
          {'icon': getIconImage('writing'), 'name': 'writing'},
          {'icon': getIconImage('openbook'), 'name': 'openbook'},
          {'icon': getIconImage('bulb'), 'name': 'bulb'},
          {'icon': getIconImage('fitness'), 'name': 'fitness'},
          {'icon': getIconImage('running'), 'name': 'running'},
          {'icon': getIconImage('house'), 'name': 'house'},
          {'icon': getIconImage('automobile'), 'name': 'automobile'},
        ],
        '업무': [
          {'icon': getIconImage('business'), 'name': 'business'}, // 추천
          {'icon': getIconImage('work_rounded'), 'name': 'work_rounded'},
          {'icon': getIconImage('print'), 'name': 'print'},
          {'icon': getIconImage('laptop'), 'name': 'laptop'},
          {'icon': getIconImage('desktop'), 'name': 'desktop'},
          {'icon': getIconImage('developer'), 'name': 'developer'},
          {'icon': getIconImage('teacher'), 'name': 'teacher'},
          {'icon': getIconImage('student'), 'name': 'student'},
          {'icon': getIconImage('artist'), 'name': 'artist'},
          {'icon': getIconImage('cooker'), 'name': 'cooker'},
          {'icon': getIconImage('telephone'), 'name': 'telephone'},
          {'icon': getIconImage('magnifying'), 'name': 'magnifying'}, // 추천
          {'icon': getIconImage('keyboard'), 'name': 'keyboard'},
          {'icon': getIconImage('bar_chart'), 'name': 'bar_chart'},
          {'icon': getIconImage('line_chart'), 'name': 'line_chart'},
          {'icon': getIconImage('notepad'), 'name': 'notepad'}, // 추천
          {'icon': getIconImage('index'), 'name': 'index'},
          {'icon': getIconImage('school'), 'name': 'school'}, // 추천
          {'icon': getIconImage('graduation_cap'), 'name': 'graduation_cap'},
          {'icon': getIconImage('scientist'), 'name': 'scientist'},
          {'icon': getIconImage('truck'), 'name': 'truck'},
          {'icon': getIconImage('toolbox'), 'name': 'toolbox'},
          {'icon': getIconImage('hammer'), 'name': 'hammer'},
          {'icon': getIconImage('dollar'), 'name': 'dollar'},
          {'icon': getIconImage('bank'), 'name': 'bank'},
          {
            'icon': getIconImage('classical_building'),
            'name': 'classical_building'
          },
        ],
        '자기계발': [
          {'icon': getIconImage('writing'), 'name': 'writing'}, // 추천
          {'icon': getIconImage('pencil'), 'name': 'pencil'},
          {'icon': getIconImage('books'), 'name': 'books'},
          {'icon': getIconImage('openbook'), 'name': 'openbook'}, // 추천
          {'icon': getIconImage('ledger'), 'name': 'ledger'},
          {'icon': getIconImage('speech'), 'name': 'speech'}, // 추천
          {'icon': getIconImage('bulb'), 'name': 'bulb'}, // 추천
          {'icon': getIconImage('ruler'), 'name': 'ruler'},
          {'icon': getIconImage('globe'), 'name': 'globe'},
          {'icon': getIconImage('meridians'), 'name': 'meridians'},
          {'icon': getIconImage('fitness'), 'name': 'fitness'}, // 추천
          {'icon': getIconImage('walking'), 'name': 'walking'},
          {'icon': getIconImage('running'), 'name': 'running'}, // 추천
          {'icon': getIconImage('yoga'), 'name': 'yoga'},
          {'icon': getIconImage('swimming'), 'name': 'swimming'},
          {'icon': getIconImage('biking'), 'name': 'biking'},
          {'icon': getIconImage('snowboarding'), 'name': 'snowboarding'},
          {'icon': getIconImage('golf'), 'name': 'golf'},
          {'icon': getIconImage('soccer'), 'name': 'soccer'},
          {'icon': getIconImage('basketball'), 'name': 'basketball'},
          {'icon': getIconImage('mountain'), 'name': 'mountain'},
          {'icon': getIconImage('badminton'), 'name': 'badminton'},
          {'icon': getIconImage('drum'), 'name': 'drum'},
          {'icon': getIconImage('palette'), 'name': 'palette'},
          {'icon': getIconImage('guitar'), 'name': 'guitar'},
          {'icon': getIconImage('trophy'), 'name': 'trophy'},
        ],
        '일상': [
          {'icon': getIconImage('house'), 'name': 'house'}, //추천
          {'icon': getIconImage('plate'), 'name': 'plate'},
          {'icon': getIconImage('tea'), 'name': 'tea'},
          {'icon': getIconImage('bread'), 'name': 'bread'},
          {'icon': getIconImage('church'), 'name': 'church'},
          {'icon': getIconImage('beer'), 'name': 'beer'},
          {'icon': getIconImage('wine'), 'name': 'wine'},
          {'icon': getIconImage('toothbrush'), 'name': 'toothbrush'},
          {'icon': getIconImage('bubbles'), 'name': 'bubbles'},
          {'icon': getIconImage('bath'), 'name': 'bath'},
          {'icon': getIconImage('zzz'), 'name': 'zzz'},
          {'icon': getIconImage('couch'), 'name': 'couch'},
          {'icon': getIconImage('broom'), 'name': 'broom'},
          {'icon': getIconImage('headphone'), 'name': 'headphone'},
          {'icon': getIconImage('music'), 'name': 'music'},
          {'icon': getIconImage('game'), 'name': 'game'},
          {'icon': getIconImage('television'), 'name': 'television'},
          {'icon': getIconImage('clapper'), 'name': 'clapper'},
          {'icon': getIconImage('popcorn'), 'name': 'popcorn'},
          {'icon': getIconImage('mobile'), 'name': 'mobile'},
          {'icon': getIconImage('automobile'), 'name': 'automobile'}, // 추천
          {'icon': getIconImage('motorcycle'), 'name': 'motorcycle'},
          {'icon': getIconImage('metro'), 'name': 'metro'},
          {'icon': getIconImage('airplane'), 'name': 'airplane'},
          {'icon': getIconImage('running_shoe'), 'name': 'running_shoe'},
          {'icon': getIconImage('baby'), 'name': 'baby'},
          {'icon': getIconImage('baby_bottle'), 'name': 'baby_bottle'},
          {'icon': getIconImage('cat'), 'name': 'cat'},
          {'icon': getIconImage('cat_face'), 'name': 'cat_face'},
          {'icon': getIconImage('dog'), 'name': 'dog'},
          {'icon': getIconImage('dog_face'), 'name': 'dog_face'},
          {'icon': getIconImage('fox'), 'name': 'fox'},
          {'icon': getIconImage('picnic'), 'name': 'picnic'},
          {'icon': getIconImage('tent'), 'name': 'tent'},
          {'icon': getIconImage('luggage'), 'name': 'luggage'},
          {'icon': getIconImage('blossom'), 'name': 'blossom'},
          {'icon': getIconImage('camera'), 'name': 'camera'},
          {'icon': getIconImage('map'), 'name': 'map'},
          {'icon': getIconImage('sweat'), 'name': 'sweat'},
          {'icon': getIconImage('skateboard'), 'name': 'skateboard'},
          {'icon': getIconImage('cards'), 'name': 'cards'},
          {'icon': getIconImage('dice'), 'name': 'dice'},
          {'icon': getIconImage('wrench'), 'name': 'wrench'},
        ],
        '이모지': [
          {'icon': getIconImage('category'), 'name': 'category'},
          {'icon': getIconImage('fire'), 'name': 'fire'},
          {'icon': getIconImage('speaker'), 'name': 'speaker'},
          {'icon': getIconImage('pinned'), 'name': 'pinned'},
          {'icon': getIconImage('rocket'), 'name': 'rocket'},
          {'icon': getIconImage('clapping'), 'name': 'clapping'},
          {'icon': getIconImage('thumbs_up'), 'name': 'thumbs_up'},
          {'icon': getIconImage('thumbs_down'), 'name': 'thumbs_down'},
          {
            'icon': getIconImage('sign_of_the_horns_light'),
            'name': 'sign_of_the_horns_light'
          },
          {'icon': getIconImage('victory'), 'name': 'victory'},
          {'icon': getIconImage('cityscape'), 'name': 'cityscape'},
          {
            'icon': getIconImage('cityscape_at_dusk'),
            'name': 'cityscape_at_dusk'
          },
          {'icon': getIconImage('city_night'), 'name': 'city_night'},
          {'icon': getIconImage('sun'), 'name': 'sun'},
          {'icon': getIconImage('sunrise'), 'name': 'sunrise'},
          {'icon': getIconImage('sunset'), 'name': 'sunset'},
          {'icon': getIconImage('party'), 'name': 'party'},
          {'icon': getIconImage('rainbow'), 'name': 'rainbow'},
          {'icon': getIconImage('tree'), 'name': 'tree'},
          {'icon': getIconImage('crown'), 'name': 'crown'},
          {'icon': getIconImage('sparkles'), 'name': 'sparkles'},
          {'icon': getIconImage('star'), 'name': 'star'},
          {'icon': getIconImage('high_voltage'), 'name': 'high_voltage'},
          {'icon': getIconImage('dizzy'), 'name': 'dizzy'},
          {'icon': getIconImage('bullseye'), 'name': 'bullseye'},
          {'icon': getIconImage('compass'), 'name': 'compass'},
          {'icon': getIconImage('stopwatch'), 'name': 'stopwatch'},
          {'icon': getIconImage('clock'), 'name': 'clock'},
          {'icon': getIconImage('alarm'), 'name': 'alarm'},
          {'icon': getIconImage('construction'), 'name': 'construction'},
          {'icon': getIconImage('calendar'), 'name': 'calendar'},
          {'icon': getIconImage('footprint'), 'name': 'footprint'},
          {'icon': getIconImage('seedling'), 'name': 'seedling'},
          {'icon': getIconImage('scroll'), 'name': 'scroll'},
          {'icon': getIconImage('magic_wand'), 'name': 'magic_wand'},
          {'icon': getIconImage('glasses'), 'name': 'glasses'},
          {'icon': getIconImage('gloves'), 'name': 'gloves'},
          {'icon': getIconImage('locked'), 'name': 'locked'},
          {'icon': getIconImage('money_wing'), 'name': 'money_wing'},
          {'icon': getIconImage('gear'), 'name': 'gear'},
          {'icon': getIconImage('hourglass_done'), 'name': 'hourglass_done'},
          {
            'icon': getIconImage('hourglass_not_done'),
            'name': 'hourglass_not_done'
          },
          {'icon': getIconImage('label'), 'name': 'label'},
          {
            'icon': getIconImage('police_car_light'),
            'name': 'police_car_light'
          },
          {'icon': getIconImage('shopping'), 'name': 'shopping'},
          {'icon': getIconImage('ticket'), 'name': 'ticket'},
          {'icon': getIconImage('unlocked'), 'name': 'unlocked'},
          {'icon': getIconImage('bookmark'), 'name': 'bookmark'},
          {'icon': getIconImage('key'), 'name': 'key'},
          {'icon': getIconImage('ghost'), 'name': 'ghost'},
          {'icon': getIconImage('eye'), 'name': 'eye'},
          {'icon': getIconImage('eyes'), 'name': 'eyes'},
          {'icon': getIconImage('robot'), 'name': 'robot'},
          {'icon': getIconImage('alien'), 'name': 'alien'},
          {'icon': getIconImage('unicorn'), 'name': 'unicorn'},
          {'icon': getIconImage('snowman'), 'name': 'snowman'},
          {'icon': getIconImage('monkey'), 'name': 'monkey'},
          {'icon': getIconImage('1st_medal'), 'name': '1st_medal'},
          {'icon': getIconImage('2nd_medal'), 'name': '2nd_medal'},
          {'icon': getIconImage('3rd_medal'), 'name': '3rd_medal'},
          {'icon': getIconImage('no_mobile'), 'name': 'no_mobile'},
        ],
        '도형': [
          {'icon': getIconImage('growing_heart'), 'name': 'growing_heart'},
          {
            'icon': getIconImage('heart_exclamation'),
            'name': 'heart_exclamation'
          },
          {'icon': getIconImage('two_heart'), 'name': 'two_heart'},
          {'icon': getIconImage('green_heart'), 'name': 'green_heart'},
          {'icon': getIconImage('yellow_heart'), 'name': 'yellow_heart'},
          {'icon': getIconImage('blue_heart'), 'name': 'blue_heart'},
          {'icon': getIconImage('grey_heart'), 'name': 'grey_heart'},
          {'icon': getIconImage('glowing_star'), 'name': 'glowing_star'},
          {'icon': getIconImage('keycap'), 'name': 'keycap'},
          {'icon': getIconImage('point_star'), 'name': 'point_star'},
          {'icon': getIconImage('plus'), 'name': 'plus'},
          {'icon': getIconImage('infinity'), 'name': 'infinity'},
          {'icon': getIconImage('up_button'), 'name': 'up_button'},
          {'icon': getIconImage('shuffle'), 'name': 'shuffle'},
          {'icon': getIconImage('hundred'), 'name': 'hundred'},
          {
            'icon': getIconImage('exclamation_question_mark'),
            'name': 'exclamation_question_mark'
          },
          {'icon': getIconImage('green_circle'), 'name': 'green_circle'},
          {'icon': getIconImage('green_square'), 'name': 'green_square'},
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
                  style: AppTextStyles.getBody(context)
                      .copyWith(fontWeight: FontWeight.bold),
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
                        child: Image.asset(
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
              Text(
                "선택된 색상",
                style: AppTextStyles.getBody(context)
                    .copyWith(fontWeight: FontWeight.w900),
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
                        Color colorWithOpacity =
                            ColorService.hexToColor(baseColor)
                                .withOpacity(opacity);

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
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                  ),
                  title: Text(
                    '베이스컬러를 선택해주세요',
                    style: AppTextStyles.getBody(context),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '활동을 오래할수록 색상이 점점 진해집니다.\n위에서 색상의 변화를 미리보고 마음에 드는 베이스 컬러를 선택해주세요.',
                      style: AppTextStyles.getCaption(context),
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
            style: AppTextStyles.getTitle(context),
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
                    controlsBuilder:
                        (BuildContext context, ControlsDetails details) {
                      return const SizedBox();
                    },
                    steps: [
                      Step(
                        title: _currentStep == 0
                            ? Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '활동 이름을\n입력해주세요',
                                      style: AppTextStyles.getTitle(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    Text(
                                      '15자 이내로 입력해주세요',
                                      style: AppTextStyles.getCaption(context),
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
                            ? Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '아이콘을\n선택해주세요',
                                      style: AppTextStyles.getTitle(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w900,
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
                      Step(
                        title: _currentStep == 2
                            ? Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '색상을\n선택해주세요',
                                      style: AppTextStyles.getTitle(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                        content: _currentStep == 2
                            ? buildColorSelection()
                            : Container(),
                        isActive: _currentStep == 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildNextAndBackButtons(),
            SizedBox(height: context.hp(2)),
          ],
        ),
      ),
    );
  }
}
