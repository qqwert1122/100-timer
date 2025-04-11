import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/firebase_options.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_theme.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';

Future<void> initializeAppSettings() async {
  // 화면 켜짐 유지
  WakelockPlus.enable();

  // SharedPreferences 초기화 및 기본값 설정
  final prefs = await SharedPreferences.getInstance();

  // 1. totalSeconds 초기화 (처음 실행 시에만)
  if (!prefs.containsKey('totalSeconds')) {
    logger.d('앱 최초 실행: totalSeconds 초기화');
    await prefs.setInt('totalSeconds', 360000); // 100시간 (초 단위)
  }

  // 2. 온보딩 상태 초기화 (처음 실행 시에만)
  if (!prefs.containsKey('hasCompletedOnboarding')) {
    logger.d('앱 최초 실행: 온보딩 상태 초기화');
    await prefs.setBool('hasCompletedOnboarding', false);
  }

  // 3. 화면 켜짐 유지 설정 초기화 (처음 실행 시에만)
  if (!prefs.containsKey('keepScreenOn')) {
    logger.d('앱 최초 실행: 화면 켜짐 유지 설정 초기화');
    await prefs.setBool('keepScreenOn', false);
  }

  if (!prefs.containsKey('alarmFlag')) {
    logger.d('앱 최초 실행 : 알람 설정 초기화');
    await prefs.setBool('alarmFlag', true);
  }

  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppSettings();
  MobileAds.instance.initialize();

  await NotificationService().initialize();

  // 데이터베이스 초기화
  // final dbService = DatabaseService() ;
  // await insertTestData(dbService);

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (context) => DatabaseService(),
        ),
        ChangeNotifierProvider<StatsProvider>(
          create: (context) {
            final dbService = context.read<DatabaseService>();
            final statsProvider = StatsProvider(dbService: dbService);
            // Provider 생성 후 초기화 완료 처리
            statsProvider.initializeWithDB(dbService);
            return statsProvider;
          },
        ),
        ChangeNotifierProxyProvider2<DatabaseService, StatsProvider, TimerProvider>(
          create: (context) {
            final dbService = context.read<DatabaseService>();
            final statsProvider = context.read<StatsProvider>();
            final timerProvider = TimerProvider(
              context,
              dbService: dbService,
              statsProvider: statsProvider,
            );
            // Provider 생성 후 초기화 완료 처리
            timerProvider.initializeWithDB(dbService);
            return timerProvider;
          },
          update: (context, databaseService, statsProvider, timerProvider) {
            timerProvider!.updateDependencies(dbService: databaseService);
            return timerProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
  // 앱 설정 초기화 함수
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Map<String, dynamic>> _initializationFuture;
  late DatabaseService _dbService;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeProviders();
    _initPrefs();
  }

  Future<Map<String, dynamic>> _initializeProviders() async {
    _dbService = Provider.of<DatabaseService>(context, listen: false);

    // Provider들의 초기화 완료 대기
    await Future.wait([
      context.read<StatsProvider>().initialized,
      context.read<TimerProvider>().initialized,
    ]);

    // 기본 활동(기존 목록) 추가: 이미 활동이 있으면 건너뜁니다.
    List<Map<String, dynamic>> activities = await _dbService.getActivities();
    if (activities.isEmpty) {
      await _insertDefaultActivities();
    }

    // 기본 타이머 초기화
    Map<String, dynamic> timerData = await _initializeApp();
    return timerData;
  }

  // SharedPreferences 초기화
  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _insertDefaultActivities() async {
    // 기본 활동 목록 (원하는 만큼 추가 가능)
    final List<Map<String, dynamic>> defaultActivities = [
      {
        'activity_name': '전체',
        'activity_icon': 'category',
        'activity_color': '#B7B7B7',
        'is_default': true,
      },
      {
        'activity_name': '업무',
        'activity_icon': 'business',
        'activity_color': '#E4003A',
        'is_default': false,
      },
      {
        'activity_name': '공부',
        'activity_icon': 'school',
        'activity_color': '#FF4C4C',
        'is_default': false,
      },
      {
        'activity_name': '글쓰기',
        'activity_icon': 'writing',
        'activity_color': '#EB5B00',
        'is_default': false,
      },
      {
        'activity_name': '독서',
        'activity_icon': 'openbook',
        'activity_color': '#F4CE14',
        'is_default': false,
      },
      {
        'activity_name': '아이디어 고민',
        'activity_icon': 'bulb',
        'activity_color': '#A1DD70',
        'is_default': false,
      },
      {
        'activity_name': '피트니스',
        'activity_icon': 'fitness',
        'activity_color': '#00CED1',
        'is_default': false,
      },
      {
        'activity_name': '러닝',
        'activity_icon': 'running',
        'activity_color': '#6A5ACD',
        'is_default': false,
      },
      {
        'activity_name': '휴식',
        'activity_icon': 'house',
        'activity_color': '#E59BE9',
        'is_default': false,
      },
      {
        'activity_name': '운전',
        'activity_icon': 'automobile',
        'activity_color': '#FFAAAA',
        'is_default': false,
      },
    ];

    for (var act in defaultActivities) {
      bool duplicate = await _dbService.isActivityNameDuplicate(act['activity_name']);
      if (!duplicate) {
        await _dbService.addActivity(
          act['activity_name'],
          act['activity_icon'],
          act['activity_color'],
          act['is_default'],
        );
      }
    }
  }

  Future<Map<String, dynamic>> _initializeApp() async {
    try {
      // 현재 local 날짜와 weekStart를 가져옴
      DateTime now = DateTime.now();
      String weekStart = getWeekStart(now);

      logger.d('타이머 초기화: 주 시작일=$weekStart');

      // 타이머 데이터를 가져오거나 새로 생성
      Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);
      if (timer == null) {
        logger.d('이번 주의 타이머 없음, 새 타이머 생성');
        timer = await _createDefaultTimer();
      } else {
        logger.d('기존 타이머 로드: ${timer['timer_id']}, 상태: ${timer['timer_state']}');
      }
      return timer;
    } catch (e, stackTrace) {
      logger.e('타이머 초기화 중 오류 발생: $e');
      logger.e('스택 트레이스: $stackTrace');
      // 오류 발생 시 기본 타이머 반환
      return await _createDefaultTimer();
    }
  }

// 기본 타이머 생성 메서드
  Future<Map<String, dynamic>> _createDefaultTimer() async {
    try {
      final now = DateTime.now();
      final weekStart = getWeekStart(now);
      final timerId = const Uuid().v4();
      final userTotalSeconds = prefs.getInt('total_seconds') ?? 360000; // 기본값: 100시간

      logger.i('새 타이머 생성: ID=$timerId, 주 시작일=$weekStart');

      final timer = {
        'timer_id': timerId,
        'current_session_id': null,
        'week_start': weekStart,
        'total_seconds': userTotalSeconds,
        'timer_state': 'STOP', // 'STOP'이면 TimerPage, 그 외면 TimerRunningPage로 이동
        'created_at': now.toUtc().toIso8601String(),
        'deleted_at': null,
        'last_started_at': null,
        'last_ended_at': null,
        'last_updated_at': now.toUtc().toIso8601String(),
        'is_deleted': 0,
        'timezone': DateTime.now().timeZoneName,
      };

      // 타이머 데이터베이스에 저장
      await _dbService.createTimer(timer);
      logger.d('타이머 데이터베이스에 저장 완료');

      return timer;
    } catch (e, stackTrace) {
      logger.e('기본 타이머 생성 중 오류 발생: $e');
      logger.e('스택 트레이스: $stackTrace');

      // 심각한 오류 - 빈 타이머 객체 반환
      final now = DateTime.now();
      return {
        'timer_id': 'error_${const Uuid().v4()}',
        'week_start': getWeekStart(now),
        'total_seconds': 360000,
        'timer_state': 'STOP',
        'created_at': now.toUtc().toIso8601String(),
        'last_updated_at': now.toUtc().toIso8601String(),
        'is_deleted': 0,
      };
    }
  }

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일을 기준으로 주 시작일 계산
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '100-timer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: FutureBuilder<Map<String, dynamic>>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 60, // 원하는 크기로 조절
                  height: 60, // 원하는 크기로 조절
                  child: CircularProgressIndicator(
                    strokeWidth: 6, // 선 두께도 조절 가능
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }

          final timerData = snapshot.data!;

          // timer_state에 따라 랜딩 페이지 결정: STOP이면 TimerPage, 아니면 TimerRunningPage
          if (timerData['timer_state'] != 'STOP') {
            return TimerRunningPage(
              timerData: timerData,
              isNewSession: false,
            );
          } else {
            return TimerPage(timerData: timerData);
          }
        },
      ),
    );
  }
}
