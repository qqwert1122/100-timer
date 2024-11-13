import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 패키지 추가
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/main.dart';
import 'package:project1/screens/splash_page.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class RegisterPage extends StatefulWidget {
  final String uid;
  final String userName;
  final String profileImage;
  final String method;

  const RegisterPage({
    super.key,
    required this.uid,
    required this.userName,
    required this.profileImage,
    required this.method,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스 생성
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String initNickname = "";
  List<String> avatarList = [];
  String selectedAvatar = "";
  int selectedActivityIndex = -1;
  List<int> selectedActivities = [];

  List<Map<String, dynamic>> activities = [
    {'name': '공부', 'icon': getIconData('school_rounded'), 'color': '#E4003A', 'iconName': 'school_rounded'},
    {'name': '독서', 'icon': getIconData('library'), 'color': '#FF4C4C', 'iconName': 'library'},
    {'name': '코딩', 'icon': getIconData('computer'), 'color': '#EB5B00', 'iconName': 'computer'},
    {'name': '글쓰기', 'icon': getIconData('edit'), 'color': '#F4CE14', 'iconName': 'edit'},
    {'name': '업무', 'icon': getIconData('work_rounded'), 'color': '#A1DD70', 'iconName': 'work_rounded'},
    {'name': '창작', 'icon': getIconData('art'), 'color': '#00CED1', 'iconName': 'art'},
    {'name': '문서작업', 'icon': getIconData('library_books'), 'color': '#6A5ACD', 'iconName': 'library_books'},
    {'name': '외국어 공부', 'icon': getIconData('language'), 'color': '#E59BE9', 'iconName': 'language'},
    {'name': '헬스', 'icon': getIconData('fitness_center_rounded'), 'color': '#FFAAAA', 'iconName': 'fitness_center_rounded'},
  ];

  // 스텝을 관리하기 위한 변수
  int _currentStep = 0;

  // 폼 키와 컨트롤러들
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;

  // 버튼 활성화 여부
  bool _isButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.userName);
    _nicknameController.addListener(_onTextChanged);
    avatarList = [
      widget.profileImage,
    ];
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // 텍스트가 비어 있지 않으면 버튼을 활성화
      _isButtonEnabled = _nicknameController.text.isNotEmpty;
    });
  }

  // 다음 버튼 눌렀을 때
  void _onNextPressed() async {
    if (_formKey.currentState!.validate()) {
      if (_currentStep == 0) {
        for (int i = 0; i < 5; i++) {
          avatarList.add(
            'https://api.dicebear.com/9.x/thumbs/svg?seed=${widget.userName}${i}&radius=50',
          );
        }
        setState(() {
          _currentStep++;
          _isButtonEnabled = false;
        });
      } else if (_currentStep == 1) {
        setState(() {
          _currentStep++;
        });
      } else if (_currentStep == 2) {
        // 회원가입 로직 실행
        _register();
      }
    }
  }

  // 회원가입 함수
  void _register() async {
    String now = DateTime.now().toUtc().toIso8601String();

    try {
      // Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(widget.uid).set({
        'uid': widget.uid,
        'userName': _nicknameController.text.trim(),
        'profileImage': selectedAvatar,
        'createdAt': now,
        'lastLogIn': now,
        'verifiedMethod': widget.method,
        'role': 'user',
        'preference': '',
      });

      // Firestore에 사용자의 activities 정보 저장

      if (selectedActivities.isNotEmpty) {
        for (int index in selectedActivities) {
          String activityId = Uuid().v4();
          Map<String, dynamic> activity = activities[index];

          await _firestore.collection('activities').doc(activityId).set({
            'uid': widget.uid,
            'activityId': activityId,
            'activityName': activity['name'],
            'activityIcon': activity['iconName'],
            'activityColor': activity['color'],
            'createdAt': now,
            'isDeleted': false,
          });
        }
      }

      Provider.of<AuthProvider>(context, listen: false).updateUserDataAvailable(true);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('환영합니다'),
          content: const Text('회원가입이 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 회원가입 페이지 닫기
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MyApp(),
        ),
      );
    } catch (e) {
      // 오류 처리
      print('Error during registration: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: Text('회원가입 중 오류가 발생했습니다.\n${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  // 현재 스텝에 따른 위젯 반환
  Widget _buildStepContent() {
    // 공통 스타일
    final underlineInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    switch (_currentStep) {
      case 0:
        // 이메일 입력 단계
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '닉네임을 입력하세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nicknameController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0), // 위아래 패딩 설정
                border: underlineInputBorder,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey), // 활성화 상태의 밑줄 색상
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent), // 포커스된 상태의 밑줄 색상
                ),
                errorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent), // 에러 상태의 밑줄 색상
                ),
                focusedErrorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent), // 포커스된 에러 상태의 밑줄 색상
                ),
                hintText: "닉네임",
                hintStyle: TextStyle(color: Colors.grey[400]),
                errorStyle: TextStyle(
                  color: Colors.redAccent, // 원하는 색상으로 변경
                  fontSize: 14.0, // 원하는 크기로 변경
                ),
              ),
            ),
            // widget.profileImage.isNotEmpty ? Image.network(widget.profileImage) : const SizedBox.shrink(),
          ],
        );
      case 1:
        // 비밀번호 입력 단계
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '아바타를 선택하세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '처음에는 6개 중에서 고를 수 있어요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(
              height: 50,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: avatarList.map((avatar) {
                  bool isSelected = selectedAvatar == avatar;
                  bool isFirst = avatar == avatarList.first;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = avatar;
                        _isButtonEnabled = true;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: isFirst
                              ? Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.grey[300],
                                  ),
                                  child: ClipOval(
                                    // 이미지가 동그라미 모양 안에 클리핑됨
                                    child: Image.network(
                                      avatar,
                                      fit: BoxFit.cover, // 이미지가 컨테이너에 잘 맞도록 설정
                                    ),
                                  ))
                              : Container(
                                  decoration: BoxDecoration(),
                                  child: SvgPicture.network(
                                    avatar,
                                    width: 100,
                                    height: 100,
                                  ),
                                ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0, // 우측 위치 조정
                            top: 0, // 상단 위치 조정
                            child: Lottie.asset(
                              'assets/images/check_3.json', // Lottie 파일 경로
                              width: 30,
                              height: 30,
                              repeat: false,
                              onLoaded: (composition) {
                                print('애니메이션 로드 완료');
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 30,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      case 2:
        // 비밀번호 확인 단계
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '활동을 추천해드려요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '활동은 나중에 자유롭게 추가하거나 수정할 수 있어요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(
              height: 50,
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 한 줄에 5개의 사각형
                crossAxisSpacing: 8.0, // 가로 간격
                mainAxisSpacing: 8.0, // 세로 간격
              ),
              itemCount: activities.length, // 총 10개의 아이템
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedActivities.contains(index)) {
                        selectedActivities.remove(index);
                      } else {
                        selectedActivities.add(index);
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ColorService.hexToColor(activities[index]['color']),
                            ColorService.hexToColor(activities[(index + 1) % activities.length]['color']),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 20,
                            top: 20,
                            child: Text(
                              activities[index]['name'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          selectedActivities.contains(index)
                              ? Positioned(
                                  right: 10, // 우측 위치 조정
                                  top: 10, // 상단 위치 조정
                                  child: Lottie.asset(
                                    'assets/images/check_3.json', // Lottie 파일 경로
                                    width: 30,
                                    height: 30,
                                    repeat: false,
                                    onLoaded: (composition) {
                                      print('애니메이션 로드 완료');
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 30,
                                      );
                                    },
                                  ),
                                )
                              : Positioned(
                                  right: 13,
                                  top: 13,
                                  child: Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle, // 원형으로 설정
                                      border: Border.all(
                                        color: Colors.white, // 회색 테두리 색상
                                        width: 2, // 테두리 두께
                                      ),
                                    ),
                                  ),
                                ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  ColorService.hexToColor(activities[index]['color']).withOpacity(0.2),
                                  ColorService.hexToColor(activities[index]['color']).withOpacity(0.5),
                                ], // 그라데이션 색상
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Icon(
                                activities[index]['icon'],
                                color: Colors.white,
                                size: 76,
                              ),
                            ),
                          ),
                        ],
                      )),
                );
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 키보드가 올라왔을 때 화면이 밀리지 않도록 설정
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 다른 곳 터치 시 키보드 닫기
        },
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey, // 폼 유효성 검사를 위해 사용
                    autovalidateMode: AutovalidateMode.onUserInteraction, // 자동 검증 모드 설정
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),
                        _buildStepContent(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 300,
                  )
                ],
              )),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          right: 16,
          left: 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled ? _onNextPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled ? Colors.blueAccent : Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep == 2 ? '회원가입' : '다음',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
