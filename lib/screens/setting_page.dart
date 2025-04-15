import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/data/credits.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/widgets/footer.dart';
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
  late SharedPreferences prefs;
  late final StatsProvider statsProvider;
  late final DatabaseService dbService;

  bool keepScreenOn = false; // 화면 켜기 상태 변수
  bool alarmFlag = true; // 알람 관련 초기 변수수
  int selectedValue = 100; // 기본값 (시간 단위)
  final List<int> values = List.generate(13, (index) => index * 5 + 40); // 40부터 100까지의 숫자 목록 생성

  // admob 광고
  BannerAd? _bannerAd1;
  bool _isAdLoaded1 = false;

  @override
  void initState() {
    super.initState();
    statsProvider = Provider.of<StatsProvider>(context, listen: false);
    dbService = Provider.of<DatabaseService>(context, listen: false);
    _initPrefs();

    // admob 광고 초기화
    _bannerAd1 = BannerAd(
      adUnitId: 'ca-app-pub-9503898094962699/7778551117',
      size: AdSize.fullBanner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded1 = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('BannerAd failed to load: $error');
        },
      ),
    );
    _bannerAd1!.load();
  }

  // SharedPreferences 초기화
  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _loadTotalSeconds(); // 초기화 후 데이터 로드
    _loadWakelockState(); // 화면 유지 상태도 로드
  }

  Future<void> _loadTotalSeconds() async {
    final totalSeconds = prefs.getInt('totalSeconds') ?? 360000;

    if (mounted) {
      setState(() {
        selectedValue = totalSeconds ~/ 3600;
      });
    }
  }

  // 총 시간 저장
  Future<void> _saveTotalSeconds(int hours) async {
    final totalSeconds = hours * 3600;
    await prefs.setInt('totalSeconds', totalSeconds);
  }

  // Wakelock 상태 불러오기
  Future<void> _loadWakelockState() async {
    final storedKeepScreenOn = prefs.getBool('keepScreenOn') ?? false;
    setState(() {
      keepScreenOn = storedKeepScreenOn;
    });
    WakelockPlus.toggle(enable: keepScreenOn); // Wakelock 적용
  }

  // Wakelock 상태 저장
  Future<void> _saveWakelockState(bool value) async {
    await prefs.setBool('keepScreenOn', value);
  }

  // 알람 설정 불러오기
  Future<void> _loadAlarmFlag() async {
    final storedAlarmFlag = prefs.getBool('alarmFlag') ?? true;
    setState(() {
      alarmFlag = storedAlarmFlag;
    });
  }

  // 알람 설정 저장
  Future<void> _saveAlarmFlag(bool value) async {
    await prefs.setBool('alarmFlag', value);
  }

  Future<void> _launchURL(String linkUrl) async {
    final Uri url = Uri.parse(linkUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('URL 열기 실패: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> timerItems = [
      {
        'title': '도전 시간을 변경해요',
        'icon': 'bullseye',
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
      {
        'title': '타이머를 초기화해요',
        'icon': 'magic_wand',
        'description': '이번 주차의 타이머를 초기화해요',
        'onTap': () {
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                title: const Text("정말 이번 주 타이머를 초기화 하시겠어요?"),
                content: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("이번주 활동 내역이 모두 삭제돼요."),
                    Text(
                      "삭제는 되돌릴 수 없어요.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      "취소",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      // 현재 주(weekOffset 0)의 세션들 가져오기
                      final sessions = await statsProvider.getSessionsForWeek(0);

                      // 모든 세션에 대해 소프트 딜리션 실행 (동시에 처리)
                      await Future.wait(
                        sessions.map((session) => dbService.deleteSession(session['session_id'])),
                      );

                      // 작업 완료 후 다이얼로그 닫기
                      Navigator.of(ctx).pop();

                      // 선택 사항: 삭제 완료 후 사용자에게 알림 메시지 표시
                      Fluttertoast.showToast(
                        msg: "이번 주 타이머가 초기화되었습니다.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    },
                    child: const Text("삭제해요", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                ],
              );
            },
          );
        },
        'trailing': null,
      },
    ];

    final List<Map<String, dynamic>> utilityItems = [
      {
        'title': '동기화해요',
        'icon': 'counter_clockwise',
        'description': '디바이스와 서버의 시간을 동기화하세요',
        'onTap': () async {},
        'trailing': null,
      },
    ];

    final List<Map<String, dynamic>> appSettingsItems = [
      {
        'title': '화면을 켜둔 채 유지해요',
        'icon': 'bulb',
        'description': '어플을 켜놓는 동안 화면을 켜두어요',
        'onTap': () {},
        'trailing': CupertinoSwitch(
          value: keepScreenOn,
          onChanged: (bool value) {
            setState(() {
              keepScreenOn = value;
            });
            WakelockPlus.toggle(enable: keepScreenOn);
            _saveWakelockState(keepScreenOn);
            print(prefs.getBool('keepScreenOn'));
          },
          activeColor: Colors.redAccent,
          trackColor: Colors.redAccent.withOpacity(0.1),
        ),
      },
      {
        'title': '알람을 켜고 꺼요',
        'icon': 'alarm',
        'description': '활동 종료 시 푸시 알람을 받아요',
        'onTap': () {},
        'trailing': CupertinoSwitch(
          value: alarmFlag,
          onChanged: (bool value) {
            setState(() {
              alarmFlag = value;
            });
            _saveAlarmFlag(alarmFlag);
          },
          activeColor: Colors.redAccent,
          trackColor: Colors.redAccent.withOpacity(0.1),
        ),
      },
    ];

    final List<Map<String, dynamic>> informationItems = [
      {
        'title': '문의하기',
        'icon': 'email',
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
        'icon': 'clapping',
        'description': '어플의 탄생에 도움을 준 분들을 확인해요\n',
        'onTap': () {
          _showAttributionDialog();
        },
        'trailing': null,
      },
      {
        'title': '이용약관',
        'icon': 'notepad',
        'description': '서비스 이용약관을 확인하세요\n',
        'onTap': () async {
          const String termsUrl = 'https://dour-sunday-be4.notion.site/100-timer-1c67162f12b2804482cbe6124186a2ac'; // 노션 URL
          if (await canLaunchUrl(Uri.parse(termsUrl))) {
            await launchUrl(
              Uri.parse(termsUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            const snackBar = SnackBar(
              content: Text('이용약관을 열 수 없습니다.'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        'trailing': null,
      },
      {
        'title': '버전',
        'icon': 'info',
        'description': '현재 버전: 0.0.1\n2025-03-30',
        'onTap': () {},
        'trailing': null,
      },
    ];

    Widget buildCategory(String title, List<Map<String, dynamic>> items) {
      return Container(
        margin: const EdgeInsets.only(top: 16.0, bottom: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: context.md,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: context.paddingXS,
              decoration: BoxDecoration(
                color: AppColors.background(context),
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
                          leading: Image.asset(
                            getIconImage(items[i]['icon']),
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
        title: Text(
          '설정',
          style: AppTextStyles.getTitle(context),
        ),
        backgroundColor: AppColors.backgroundSecondary(context),
      ),
      body: Container(
        color: AppColors.backgroundSecondary(context),
        child: ListView(
          padding: context.paddingSM, // 화면의 좌우 여백 설정
          children: [
            _isAdLoaded1
                ? SizedBox(
                    width: _bannerAd1!.size.width.toDouble(),
                    height: _bannerAd1!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd1!),
                  )
                : const SizedBox.shrink(),
            buildCategory('타이머 설정', timerItems),
            buildCategory('앱 설정', appSettingsItems),
            buildCategory('유틸리티', utilityItems),
            buildCategory('정보', informationItems),
            const Footer(),
          ],
        ),
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
                onPressed: () async {
                  setState(() {
                    selectedValue = tempValue; // "확인" 버튼을 눌렀을 때 상태 업데이트
                  });
                  await _saveTotalSeconds(selectedValue);
                  HapticFeedback.lightImpact();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 스크롤 가능하도록 설정
      builder: (BuildContext context) {
        return Container(
          height: context.hp(90),
          width: MediaQuery.of(context).size.width, // 화면 너비에 맞춤
          decoration:
              BoxDecoration(color: AppColors.background(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: context.wp(20),
                  height: context.hp(1),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              SizedBox(height: context.hp(2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '기여',
                    style: AppTextStyles.getTitle(context),
                  ),
                  Image.asset(
                    getIconImage('clapping'),
                    width: context.xxl,
                    height: context.xxl,
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
                ],
              ),
              SizedBox(height: context.hp(2)),
              Expanded(
                child: ListView.builder(
                  itemCount: creditList.length,
                  itemBuilder: (context, index) {
                    final item = creditList[index];

                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['category']} | ${item['title']}', style: AppTextStyles.getTitle(context)),
                          SizedBox(height: context.hp(1)),
                          Text(item['description'], style: AppTextStyles.getBody(context)),
                          GestureDetector(
                            onTap: () => _launchURL(item['link']),
                            child: Text(
                              '더보기 ...',
                              style: AppTextStyles.getBody(context).copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: context.hp(2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
