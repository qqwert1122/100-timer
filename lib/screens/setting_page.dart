import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/screens/login_page.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/database_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final DatabaseService _dbService = DatabaseService();

  bool keepScreenOn = false; // 화면 켜기 상태 변수

  int selectedValue = 100; // 기본값 (시간 단위)
  final List<int> values = List.generate(13, (index) => index * 5 + 40); // 40부터 100까지의 숫자 목록 생성

  @override
  void initState() {
    super.initState();
    _loadUserTotalSeconds();
  }

  Future<void> _loadUserTotalSeconds() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Map<String, dynamic>? userData = await authProvider.getUserData();
    if (userData != null) {
      setState(() {
        selectedValue = (userData['total_seconds'] ?? 360000) ~/ 3600; // 초를 시간으로 변환
      });
    }
  }

  // Wakelock 상태 불러오기
  Future<void> _loadWakelockState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKeepScreenOn = prefs.getBool('keepScreenOn') ?? false;
    setState(() {
      keepScreenOn = storedKeepScreenOn;
    });
    WakelockPlus.toggle(enable: keepScreenOn); // Wakelock 적용
  }

  // Wakelock 상태 저장
  Future<void> _saveWakelockState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepScreenOn', value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final List<Map<String, dynamic>> generalItems = [
      {
        'title': '도전 시간을 변경해요',
        'icon': Icons.watch_later_outlined,
        'description': '다른 시간을 도전하세요\n바뀐 시간은 다음주부터 적용돼요',
        'onTap': () {},
        'trailing': GestureDetector(
          onTap: () => _showPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedValue시간',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      },
    ];

    final List<Map<String, dynamic>> utilityItems = [
      {
        'title': '타이머를 초기화해요',
        'icon': Icons.refresh_rounded,
        'description': '이번 주차의 타이머를 초기화해요\n되돌릴 수 없으니 신중히 초기화해주세요',
        'onTap': () {},
        'trailing': null,
      },
      {
        'title': '동기화해요',
        'icon': Icons.sync,
        'description': '디바이스와 서버의 시간을 동기화하세요\n',
        'onTap': () async {
          await _dbService.syncDataWithServer(authProvider.user?.uid ?? '');
        },
        'trailing': null,
      },
    ];

    final List<Map<String, dynamic>> accountItems = [
      {
        'title': '로그아웃',
        'icon': Icons.logout_rounded,
        'description': '로그아웃해요\n',
        'onTap': () async {
          await Provider.of<AuthProvider>(context, listen: false).signOut();
        },
        'trailing': null,
      },
    ];

    final List<Map<String, dynamic>> appSettingsItems = [
      {
        'title': '화면을 켜둔 채 유지해요',
        'icon': Icons.light_rounded,
        'description': '어플을 켜놓는 동안 화면을 켜두어요\n',
        'onTap': () {},
        'trailing': CupertinoSwitch(
          value: keepScreenOn,
          onChanged: (bool value) {
            setState(() {
              keepScreenOn = value;
            });
            WakelockPlus.toggle(enable: keepScreenOn);
            _saveWakelockState(keepScreenOn);
          },
          activeColor: Colors.redAccent,
          trackColor: Colors.redAccent.withOpacity(0.1),
        ),
      },
    ];

    final List<Map<String, dynamic>> informationItems = [
      {
        'title': '문의하기',
        'icon': Icons.send_rounded,
        'description': '궁금한 점을 문의하세요\n',
        'onTap': () async {
          const String googleFormUrl =
              'https://docs.google.com/forms/d/e/1FAIpQLSdo9bnrDgqAnpqX21c_cQDlLeDrmrOtLj7y2iwO-3cJkDLOjQ/viewform?usp=sf_link'; // 구글 폼 URL
          if (await canLaunchUrl(Uri.parse(googleFormUrl))) {
            await launchUrl(
              Uri.parse(googleFormUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            const snackBar = SnackBar(
              content: Text('구글 폼을 열 수 없습니다. 링크: https://forms.gle/your-form-id'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        'trailing': null,
      },
      {
        'title': '기여',
        'icon': Icons.attribution_rounded,
        'description': '어플의 탄생에 도움을 준 분들을 확인해요\n',
        'onTap': () {
          _showAttributionDialog();
        },
        'trailing': null,
      },
      {
        'title': '이용약관',
        'icon': Icons.article_outlined,
        'description': '서비스 이용약관을 확인하세요\n',
        'onTap': () {
          print('이용약관 열기');
        },
        'trailing': null,
      },
      {
        'title': '버전',
        'icon': Icons.info_outline,
        'description': '현재 버전: 0.0.1\n2024-11-16',
        'onTap': () {},
        'trailing': null,
      },
    ];
    Widget _buildCategory(String title, List<Map<String, dynamic>> items) {
      return Container(
        margin: const EdgeInsets.only(top: 16.0, bottom: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey, // 제목 색상
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[isDarkMode ? 800 : 200],
                borderRadius: const BorderRadius.all(Radius.circular(16.0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (items[i]['onTap'] != null) {
                            items[i]['onTap']!();
                          }
                        },
                        borderRadius: i == 0
                            ? const BorderRadius.vertical(top: Radius.circular(16.0))
                            : i == items.length - 1
                                ? const BorderRadius.vertical(bottom: Radius.circular(16.0))
                                : BorderRadius.zero,
                        child: ListTile(
                          leading: Icon(items[i]['icon']),
                          title: Text(
                            items[i]['title'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            items[i]['description'],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: items[i]['trailing'],
                        ),
                      ),
                    ),
                    // Divider 추가: 마지막 아이템 제외
                    if (i != items.length - 1)
                      const Divider(
                        color: Colors.black12, // 구분선 색상
                        thickness: 0.5, // 구분선 두께
                        height: 16.0, // 구분선 높이
                        indent: 16.0, // 구분선 좌측 여백
                        endIndent: 16.0, // 구분선 우측 여백
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18), // 화면의 좌우 여백 설정
        children: [
          _buildCategory('일반 설정', generalItems),
          _buildCategory('유틸리티', utilityItems),
          _buildCategory('앱 설정', appSettingsItems),
          _buildCategory('계정', accountItems),
          _buildCategory('정보', informationItems),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    int tempValue = selectedValue;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedValue ~/ 5),
                  itemExtent: 40,
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      tempValue = values[index];
                    });
                  },
                  children: values.map((value) {
                    return Center(
                      child: Text(
                        '$value 시간',
                        style: const TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
              CupertinoButton(
                child: const Text(
                  '확인',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  setState(() {
                    selectedValue = tempValue; // "확인" 버튼을 눌렀을 때 상태 업데이트
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttributionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // 배경색 하얀색으로 변경
          title: const Text('어트리뷰션', style: TextStyle(color: Colors.black)), // 글씨 색상 변경
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('• 아바타 출처: diceBear, flaticon', style: TextStyle(color: Colors.black)),
                Text('• 아이콘 출처: flaticon, https://www.flaticon.com/free-icons/dinosaur', style: TextStyle(color: Colors.black)),
                Text('• 라이브러리: Flutter, Provider', style: TextStyle(color: Colors.black)),
                // 추가적인 어트리뷰션 내용
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 모달 닫기
              },
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
}
