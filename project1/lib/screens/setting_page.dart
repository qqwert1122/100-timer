import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final List<Map<String, dynamic>> items = [
    {
      'title': '도전 시간을 변경해요',
      'icon': Icons.watch_later_outlined,
      'description': '현재 진행 중인 도전의 시간을 수정하여\n나에게 맞게 목표를 조정할 수 있습니다.',
      'onTap': () {
        // 도전 시간 변경 로직
      },
    },
    {
      'title': '타이머를 초기화해요',
      'icon': Icons.refresh_rounded,
      'description': '현재 설정된 타이머를 초기화해요\n새로운 타이머를 다시 시작할 수 있습니다.',
      'onTap': () {
        // 타이머 초기화 로직
      },
    },
    {
      'title': '시간을 재조정해요',
      'icon': Icons.auto_fix_high_outlined,
      'description': '앱 내 시간 설정을 재조정하여\n정확한 시간 관리를 할 수 있습니다.',
      'onTap': () {
        // 시간 재조정 로직
      },
    },
    {
      'title': '서버와 동기화해요',
      'icon': Icons.sync,
      'description': '디바이스의 시간을 서버에 저장하세요\n기기 간 시간을 맞출 수 있어요.',
      'onTap': () {
        // 서버 동기화 로직
      },
    },
    {
      'title': '화면을 켜둔 채 유지해요',
      'icon': Icons.light_rounded,
      'description': '어플을 켜놓는 동안 화면을 켜두어요\n활동 시간을 보면서 집중할 수 있어요',
      'onTap': () {
        // 시간 재조정 로직
      },
    },
    {
      'title': '문의하기',
      'icon': Icons.send_rounded,
      'description': '궁금한 점을 문의하거나\n필요한 기능을 제안해주세요',
      'onTap': () {
        // 시간 재조정 로직
      },
    },
    {
      'title': '버전',
      'icon': Icons.info_outline,
      'description': '0.0.1',
      'onTap': () {
        // 시간 재조정 로직
      },
    },
    {
      'title': '이용약관',
      'icon': Icons.chat_rounded,
      'description': '서비스 이용약관을 확인하세요',
      'onTap': () {
        // 시간 재조정 로직
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24), // 화면의 좌우 여백 설정
        child: ListView(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18), // 버튼 간 간격 설정
              child: InkWell(
                onTap: item['onTap'], // 각 버튼의 고유한 기능
                borderRadius: BorderRadius.circular(16.0), // 잉크 효과의 둥근 모서리 적용
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[isDarkMode ? 800 : 200], // 회색 배경색
                    borderRadius: BorderRadius.circular(16.0), // 둥근 모서리
                  ),
                  child: ListTile(
                    title: Text(
                      item['title'],
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        item['description'],
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    trailing: Icon(item['icon']), // 각 버튼의 고유한 아이콘,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
