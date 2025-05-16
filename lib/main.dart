import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/screens/activity_log_page.dart';
import 'package:project1/screens/activity_picker.dart';
import 'package:project1/screens/main_page.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_theme.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/test_data_generator.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/focus_mode.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR');

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
      child: ShowCaseWidget(
        onComplete: (_, key) {
          if (key == TimerPage.playButtonKey) {
            PrefsService().setOnboarding('timer', true);
            NotificationService().requestPermissions();
          }

          if (key == ActivityPicker.listKey3) {
            PrefsService().setOnboarding('activityPicker', true);
          }

          if (key == TimerRunningPage.lightOnKey) {
            PrefsService().setOnboarding('timerRunning', true);
          }

          if (key == FocusMode.countKey) {
            PrefsService().setOnboarding('focusMode', true);
          }

          if (key == ActivityLogPage.logKey) {
            PrefsService().setOnboarding('history', true);
          }
        },
        builder: (context) => const MyApp(),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // ① SharedPreferences
    await PrefsService().init();

    WakelockPlus.toggle(enable: PrefsService().keepScreenOn);

    // ③ Google Mobile Ads
    await MobileAds.instance.initialize();

    // ④ 알림
    await NotificationService().initialize();

    // 데이터베이스 초기
    // final dbService = DatabaseService();
    // await insertTestData(dbService);
  });

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
  late TimerProvider _timerProvider;

  @override
  void initState() {
    super.initState();
    _initializationFuture = Future.any([
      _initializeProviders(),
      Future.delayed(const Duration(seconds: 8), () => throw 'init-timeout'),
    ]);
  }

  Future<Map<String, dynamic>> _initializeProviders() async {
    logger.d('@@@ main @@@ _initializeProviders()');
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);
    // Provider들의 초기화 완료 대기
    await Future.wait([
      context.read<StatsProvider>().initialized,
      context.read<TimerProvider>().ready,
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

  Future<void> _insertDefaultActivities() async {
    logger.d('[main] insert Default Activities');

    final List<Map<String, dynamic>> defaultActivities = [
      {
        'activity_name': '전체 활동',
        'activity_icon': 'category',
        'activity_color': '#BCBCBC',
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
        'activity_name': '글쓰기 연습',
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
        'activity_name': '사이드 프로젝트',
        'activity_icon': 'rocket',
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
        'activity_name': '코딩',
        'activity_icon': 'developer',
        'activity_color': '#6A5ACD',
        'is_default': false,
      },
    ];

    for (var act in defaultActivities) {
      bool duplicate = await _dbService.isActivityNameDuplicate(act['activity_name']);
      if (!duplicate) {
        await _dbService.addActivity(
          activityName: act['activity_name'],
          activityIcon: act['activity_icon'],
          activityColor: act['activity_color'],
          isDefault: act['is_default'],
          parentActivityId: null,
        );
      }
    }

    await _timerProvider.setDefaultActivity();
  }

  Future<Map<String, dynamic>> _initializeApp() async {
    logger.d('@@@ main @@@ _initializeApp()');
    try {
      // 현재 local 날짜와 weekStart를 가져옴
      DateTime now = DateTime.now();
      String weekStart = getWeekStart(now);

      // 타이머 데이터를 가져오거나 새로 생성
      Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);
      if (timer == null) {
        timer = await _createDefaultTimer();
      } else {}
      return timer;
    } catch (e, stackTrace) {
      logger.e('@@@ main @@@ e: $e, stackTrace: $stackTrace');
      // 오류 발생 시 기본 타이머 반환
      return await _createDefaultTimer();
    }
  }

// 기본 타이머 생성 메서드
  Future<Map<String, dynamic>> _createDefaultTimer() async {
    logger.d('@@@ main @@@ _createDefaultTimer()');
    final now = DateTime.now();
    final weekStart = getWeekStart(now);
    final timerId = const Uuid().v4();
    final userTotalSeconds = PrefsService().totalSeconds;

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

    await _dbService.createTimer(timer); // 타이머 데이터베이스에 저장

    return timer;
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
          if (snapshot.hasError) {
            logger.e('App init failed: ${snapshot.error}');
            return Scaffold(
              body: Center(
                child: Text('초기화 오류: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting || !_timerProvider.isTimerProviderInit) {
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
          return const MainPage();
        },
      ),
    );
  }
}
