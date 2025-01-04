import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 패키지 추가
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/main.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
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
  late final DatabaseService _dbService; // 주입받을 DatabaseService

  String initNickname = "";
  List<String> avatarList = [];
  String selectedAvatar = "";
  String userHandle = ""; // 사용자의 @handle 저장
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
  bool _isButtonEnabled = false; // 초기값을 false로 설정

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _nicknameController = TextEditingController(text: widget.userName);
    _nicknameController.addListener(_onTextChanged);
    _generateHandle(_nicknameController.text);
    _isButtonEnabled = _nicknameController.text.trim().isNotEmpty;
  }

  void _generateHandle(String name) {
    if (name.isEmpty) return;

    // 랜덤 숫자 4자리 생성
    String randomNum = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    userHandle = "@${name.toLowerCase().replaceAll(' ', '')}$randomNum";
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newText = _nicknameController.text.trim();
    setState(() {
      _isButtonEnabled = newText.isNotEmpty;
      _generateHandle(newText);
      if (avatarList.isNotEmpty) {
        selectedAvatar = avatarList[0];
      }
    });
  }

  // 다음 버튼 눌렀을 때
  void _onNextPressed() async {
    if (_formKey.currentState!.validate()) {
      if (_currentStep == 0) {
        if (avatarList.isEmpty) {
          for (int i = 0; i < 15; i++) {
            avatarList.add(
              'https://api.dicebear.com/9.x/thumbs/svg?seed=${_nicknameController.text}${i}&radius=50',
            );
          }
        }
        if (avatarList.isNotEmpty) {
          selectedAvatar = avatarList[0];
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
    String now = DateTime.now().toUtc().toIso8601String(); // toUtc로 변경

    try {
      final newUser = {
        'uid': widget.uid,
        'user_name': _nicknameController.text.trim(),
        'profile_image': selectedAvatar,
        'created_at': now,
        'last_logged_in': now,
        'verified_method': Provider.of<AuthProvider>(context, listen: false).loginMethod,
        'role': 'user',
        'total_seconds': 360000,
        'preference': null,
      };

      await _dbService.createUser(widget.uid, newUser);
      await _firestore.collection('users').doc(widget.uid).set(newUser);

      _dbService.downloadNewContentsFromFirestore(DateTime(1970).toUtc().toIso8601String());

      // Firestore에 사용자의 activities 정보 저장
      _dbService.addActivity('전체', 'category_rounded', '#B7B7B7', true);

      if (selectedActivities.isNotEmpty) {
        for (int index in selectedActivities) {
          Map<String, dynamic> activity = activities[index];

          _dbService.addActivity(activity['name'], activity['iconName'], activity['color'], false);
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
        // 닉네임 입력 단계
        return Padding(
          padding: context.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '닉네임을 입력하세요',
                style: AppTextStyles.getHeadline(context),
              ),
              SizedBox(height: context.hp(3)),
              TextFormField(
                controller: _nicknameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  contentPadding: context.paddingXS, // 위아래 패딩 설정
                  border: underlineInputBorder,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 활성화 상태의 밑줄 색상
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent), // 포커스된 상태의 밑줄 색상
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.redAccent), // 에러 상태의 밑줄 색상
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.redAccent), // 포커스된 에러 상태의 밑줄 색상
                  ),
                  hintText: "닉네임",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorStyle: AppTextStyles.getBody(context).copyWith(color: Colors.redAccent),
                  helperText: userHandle, // @handle 표시
                  helperStyle: AppTextStyles.getCaption(context),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      case 1:
        // 아바타 선택 단계
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: context.paddingLG,
              child: Text(
                '아바타를 선택하세요',
                style: AppTextStyles.getHeadline(context),
              ),
            ),
            SizedBox(height: context.hp(3)),
            // 선택된 아바타 큰 크기로 표시
            if (selectedAvatar.isNotEmpty)
              Center(
                child: Container(
                  margin: context.paddingMD,
                  width: context.wp(50),
                  height: context.hp(20),
                  child: SvgPicture.network(
                    selectedAvatar,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            SizedBox(
              height: context.hp(3),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: avatarList.map((avatar) {
                  bool isSelected = selectedAvatar == avatar;

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
                          margin: context.paddingXS,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.md),
                          ),
                          child: Container(
                            width: context.wp(20),
                            height: context.hp(10),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.grey[300],
                            ),
                            child: ClipOval(
                              child: SvgPicture.network(
                                avatar,
                                fit: BoxFit.cover,
                                placeholderBuilder: (BuildContext context) => Container(
                                  padding: context.paddingXL,
                                  child: const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0, // 우측 위치 조정
                            top: 0, // 상단 위치 조정
                            child: Lottie.asset(
                              'assets/images/check_3.json', // Lottie 파일 경로
                              width: context.wp(10),
                              height: context.hp(5),
                              repeat: false,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
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
        // 활동 선택 단계
        return Padding(
          padding: context.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '활동을 추천해드려요',
                style: AppTextStyles.getHeadline(context),
              ),
              SizedBox(height: context.hp(3)),
              Text('나중에 자유롭게 추가하거나 수정할 수 있어요',
                  style: AppTextStyles.getBody(context).copyWith(
                    color: Colors.grey,
                  )),
              SizedBox(height: context.hp(8)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 한 줄에 2개의 사각형
                  crossAxisSpacing: 8.0, // 가로 간격
                  mainAxisSpacing: 8.0, // 세로 간격
                ),
                itemCount: activities.length, // 총 9개의 아이템
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
                            left: context.md,
                            top: context.md,
                            child: Text(
                              activities[index]['name'],
                              style: AppTextStyles.getHeadline(context).copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          selectedActivities.contains(index)
                              ? Positioned(
                                  right: context.sm, // 우측 위치 조정
                                  top: context.sm, // 상단 위치 조정
                                  child: Lottie.asset(
                                    'assets/images/check_3.json', // Lottie 파일 경로
                                    width: context.wp(10),
                                    height: context.hp(4),
                                    repeat: false,
                                    onLoaded: (composition) {
                                      print('애니메이션 로드 완료');
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 30,
                                      );
                                    },
                                  ),
                                )
                              : Positioned(
                                  right: context.md,
                                  top: context.md,
                                  child: Container(
                                    width: context.wp(10),
                                    height: context.hp(3),
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
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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
        title: Text(
          '회원가입',
          style: AppTextStyles.getHeadline(context),
        ),
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    // 아바타 선택 페이지로 돌아갈 때 버튼 활성화 상태 복원
                    if (_currentStep == 1) {
                      _isButtonEnabled = true;
                    }
                  });
                },
              )
            : null, // 첫 페이지에서는 뒤로가기 버튼 숨김
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 다른 곳 터치 시 키보드 닫기
        },
        child: SingleChildScrollView(
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
              SizedBox(height: 300),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: context.paddingSM,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled ? _onNextPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled ? Colors.blueAccent : Colors.grey.shade400,
              padding: context.paddingSM,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.md),
              ),
            ),
            child: Text(_currentStep == 2 ? '회원가입' : '다음',
                style: AppTextStyles.getBody(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                )),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
