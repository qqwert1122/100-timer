import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/utils/database_service.dart';
import 'package:provider/provider.dart';

class AddActivityPage extends StatefulWidget {
  const AddActivityPage({super.key});

  @override
  _AddActivityPageState createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final TextEditingController _activityNameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService(); // 데이터베이스 서비스 인스턴스 생성

  int _currentStep = 0;
  String? _selectedIconName;

  @override
  void initState() {
    super.initState();
    _activityNameController.addListener(_validateForm); // 이름 입력시 상태 확인
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    super.dispose();
  }

  // 폼 유효성 검사
  bool get isActivityNameValid => _activityNameController.text.isNotEmpty;
  bool get isIconSelected => _selectedIconName != null;

  void _validateForm() {
    setState(() {});
  }

  // '다음' 버튼 클릭 시 스텝 증가
  void _nextStep() {
    setState(() {
      if (_currentStep < 1) {
        _currentStep++;
      }
    });
  }

  // 완료 시 처리
  void _submit() async {
    final String activityName = _activityNameController.text.trim();
    final String? iconName = _selectedIconName;

    // 이름과 아이콘이 선택되었을 때만 저장
    if (activityName.isNotEmpty && iconName != null) {
      await _dbService.addActivity(activityName, iconName); // DB에 활동 저장
      final newActivity = {
        'name': _activityNameController.text,
        'icon': _selectedIconName,
      };

      // 저장 후 피드백 메시지
      Fluttertoast.showToast(
        msg: "활동이 성공적으로 추가되었습니다",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.blueAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      Navigator.pop(context, newActivity); // 저장 후 이전 화면으로 돌아가기
    } else {
      // 필수 항목 입력되지 않았을 때 경고 메시지
      Fluttertoast.showToast(
        msg: "활동 이름과 아이콘을 입력해주세요",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  // '뒤로' 버튼 동작 (필요하면 사용 가능)
  void _prevStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    Widget buildActivityName() {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _activityNameController,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          maxLength: 15, // 최대 10글자 제한
          decoration: InputDecoration(
            border: const UnderlineInputBorder(), // 기본 밑줄 디자인
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
              color: isDarkMode ? Colors.white : Colors.black,
            )),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent), // 밑줄 색을 파란색으로
            ),
            hintText: '예시. 타이머 어플 코딩',
            hintStyle:
                TextStyle(color: Colors.grey.shade400), // 힌트 텍스트 색을 연한 그레이색으로
          ),
        ),
      );
    }

    Widget buildIconSelection() {
      final List<Map<String, dynamic>> icons = [
        // 1. 공부와 관련된 아이콘
        {'icon': Icons.school, 'name': 'school'},
        {'icon': Icons.local_library, 'name': 'library'},
        {'icon': Icons.palette, 'name': 'art'},
        {'icon': Icons.computer, 'name': 'computer'},
        {'icon': Icons.edit, 'name': 'edit'},
        {'icon': Icons.keyboard, 'name': 'keyboard'},
        {'icon': Icons.library_books, 'name': 'library_books'},
        {'icon': Icons.language, 'name': 'language'},
        {'icon': Icons.science, 'name': 'science'},

        // 2. 업무와 관련된 아이콘
        {'icon': Icons.work, 'name': 'work'},
        {'icon': Icons.business, 'name': 'business'},
        {'icon': Icons.attach_money, 'name': 'money'},
        {'icon': Icons.email, 'name': 'email'},
        {'icon': Icons.meeting_room, 'name': 'meeting'},
        {'icon': Icons.analytics, 'name': 'analytics'},
        {'icon': Icons.assignment, 'name': 'assignment'},
        {'icon': Icons.person_add, 'name': 'person_add'},
        {'icon': Icons.pie_chart, 'name': 'chart'},
        {'icon': Icons.phone, 'name': 'phone'},
        {'icon': Icons.print, 'name': 'print'},
        {'icon': Icons.timeline, 'name': 'timeline'},
        {'icon': Icons.folder_open, 'name': 'folder_open'},
        {'icon': Icons.fact_check, 'name': 'fact_check'},

        // 3. 운동과 관련된 아이콘
        {'icon': Icons.fitness_center, 'name': 'fitness_center'},
        {'icon': Icons.directions_run, 'name': 'running'},
        {'icon': Icons.pool, 'name': 'swimming'},
        {'icon': Icons.sports_soccer, 'name': 'soccer'},
        {'icon': Icons.sports_basketball, 'name': 'basketball'},
        {'icon': Icons.sports_tennis, 'name': 'tennis'},
        {'icon': Icons.sports_volleyball, 'name': 'volleyball'},
        {'icon': Icons.directions_bike, 'name': 'bike'},
        {'icon': Icons.sports_golf, 'name': 'golf'},
        {'icon': Icons.sports_mma, 'name': 'mma'},
        {'icon': Icons.sports_cricket, 'name': 'cricket'},
        {'icon': Icons.sports_esports, 'name': 'esports'},

        // 4. 그외 자기계발과 관련된 아이콘
        {'icon': Icons.lightbulb, 'name': 'ideas'},
        {'icon': Icons.build, 'name': 'tools'},
        {'icon': Icons.healing, 'name': 'healing'},
        {'icon': Icons.spa, 'name': 'spa'},
        {'icon': Icons.park, 'name': 'park'},
        {'icon': Icons.gavel, 'name': 'gavel'},
        {'icon': Icons.hiking, 'name': 'hiking'},
        {'icon': Icons.group, 'name': 'group_work'},
        {'icon': Icons.pets, 'name': 'pets'},
        {'icon': Icons.cleaning_services, 'name': 'cleaning'},
        {'icon': Icons.security, 'name': 'security'},
        {'icon': Icons.volunteer_activism, 'name': 'volunteer'},
        {'icon': Icons.supervised_user_circle, 'name': 'mentoring'},

        // 5. 그 외 일상 관련된 아이콘
        {'icon': Icons.home, 'name': 'home'},
        {'icon': Icons.restaurant, 'name': 'restaurant'},
        {'icon': Icons.coffee, 'name': 'coffee'},
        {'icon': Icons.local_hospital, 'name': 'hospital'},
        {'icon': Icons.shopping_cart, 'name': 'shopping'},
        {'icon': Icons.movie, 'name': 'movie'},
        {'icon': Icons.music_note, 'name': 'music'},
        {'icon': Icons.flight, 'name': 'flight'},
        {'icon': Icons.hotel, 'name': 'hotel'},
        {'icon': Icons.camera_alt, 'name': 'camera'},
        {'icon': Icons.directions_car, 'name': 'car'},
        {'icon': Icons.directions_boat, 'name': 'boat'},
        {'icon': Icons.train, 'name': 'train'},
        {'icon': Icons.subway, 'name': 'subway'},
        {'icon': Icons.directions_walk, 'name': 'walk'},
        {'icon': Icons.local_cafe, 'name': 'cafe'},
        {'icon': Icons.park, 'name': 'park'},
        {'icon': Icons.tv, 'name': 'tv'},
        {'icon': Icons.videogame_asset, 'name': 'gaming'},
        {'icon': Icons.theater_comedy, 'name': 'theater'},
        {'icon': Icons.radio, 'name': 'radio'},
        {'icon': Icons.headset, 'name': 'headset'},
        {'icon': Icons.mic, 'name': 'mic'},
        {'icon': Icons.music_video, 'name': 'music_video'},
        {'icon': Icons.directions_bus, 'name': 'bus'},
        {'icon': Icons.brush, 'name': 'painting'},
        {'icon': Icons.map, 'name': 'map'},
        {'icon': Icons.add_a_photo, 'name': 'photo'},
        {'icon': Icons.beach_access, 'name': 'beach'},
        {'icon': Icons.bubble_chart, 'name': 'bubble_chart'},
        {'icon': Icons.wine_bar, 'name': 'wine_bar'},
        {'icon': Icons.ac_unit, 'name': 'weather'},
        {'icon': Icons.sports_kabaddi, 'name': 'kabaddi'},
        {'icon': Icons.holiday_village, 'name': 'village'},
        {'icon': Icons.architecture, 'name': 'architecture'},
      ];

      return Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(), // 스크롤 가능하게 설정
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
      );
    }

    Widget buildNextAndBackButtons(DatabaseService dbService) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // '뒤로' 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStep > 0 ? _prevStep : null, // 첫 단계에서는 비활성화
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16), // 버튼 높이 설정
                  backgroundColor: Colors.red, // '뒤로' 버튼 색상 설정 (비활성화 시 회색)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // borderRadius 설정
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
            const SizedBox(width: 16), // 버튼 사이의 간격
            // '다음' 또는 '추가' 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStep == 0
                    ? (isActivityNameValid ? _nextStep : null)
                    : (isIconSelected ? _submit : null),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16), // 버튼 높이 설정
                  backgroundColor: (isActivityNameValid || isIconSelected)
                      ? Colors.blueAccent
                      : Colors.grey, // '뒤로' 버튼 색상 설정 (비활성화 시 회색)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // borderRadius 설정
                  ),
                ),
                child: Text(
                  _currentStep == 0 ? '다음' : '추가',
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
          title: const Text(
            '활동 추가',
            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.pop(context); // 뒤로가기
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
            buildNextAndBackButtons(dbService)
          ],
        ),
      ),
    );
  }
}
