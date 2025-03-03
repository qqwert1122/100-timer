import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/firebase_options.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/screens/timer_running_page.dart';
import 'package:project1/theme/app_theme.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/device_info_service.dart';
import 'package:project1/utils/error_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart'; // Uuid 사용을 위한 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        Provider(create: (context) => DeviceInfoService()),
        Provider(
          create: (context) => ErrorService(
            deviceInfoService: context.read<DeviceInfoService>(),
          ),
        ),
        Provider<DatabaseService>(
          create: (context) => DatabaseService(
            deviceInfoService: context.read<DeviceInfoService>(),
            errorService: context.read<ErrorService>(),
          ),
        ),
        ChangeNotifierProvider<StatsProvider>(
          create: (context) => StatsProvider(
            dbService: context.read<DatabaseService>(),
            errorService: context.read<ErrorService>(),
          ),
        ),
        ChangeNotifierProxyProvider2<DatabaseService, ErrorService,
            TimerProvider>(
          create: (context) => TimerProvider(
            context,
            dbService: context.read<DatabaseService>(),
            statsProvider: context.read<StatsProvider>(),
            errorService: context.read<ErrorService>(),
          ),
          update:
              (context, databaseService, errorService, existingTimerProvider) {
            if (existingTimerProvider == null) {
              return TimerProvider(
                context,
                dbService: databaseService,
                statsProvider: context.read<StatsProvider>(),
                errorService: errorService,
              );
            } else {
              existingTimerProvider.updateDependencies(
                dbService: databaseService,
                errorService: errorService,
                // 필요시 statsProvider 등 다른 의존성도 업데이트
              );
              return existingTimerProvider;
            }
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Map<String, dynamic>> _initializationFuture;
  late DatabaseService _dbService;
  Map<String, dynamic>? _timerData;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeProviders();
  }

  Future<Map<String, dynamic>> _initializeProviders() async {
    // Provider는 이미 MultiProvider로 상위에 설정되어 있으므로 안전하게 사용 가능합니다.
    _dbService = Provider.of<DatabaseService>(context, listen: false);

    // StatsProvider와 TimerProvider의 초기화가 완료될 때까지 대기
    await Future.wait([
      context.read<StatsProvider>().initialized,
      context.read<TimerProvider>().initialized,
    ]);

    return _initializeApp();
  }

  Future<Map<String, dynamic>> _initializeApp() async {
    DateTime now = DateTime.now();
    String weekStart = getWeekStart(now);

    // 활동 데이터 로드
    List<Map<String, dynamic>> activities = await _dbService.getActivities();
    if (activities.isEmpty) {
      activities = await _dbService.getActivities();

      if (activities.isEmpty) {
        print('활동 데이터를 가져올 수 없습니다.');
        // 기본 활동 생성 로직 또는 추가 오류 처리 가능
      }
    }

    // 타이머 데이터 확인
    Map<String, dynamic>? timer = await _dbService.getTimer(weekStart);
    if (timer == null) {
      timer = await _createDefaultTimer();
      await _dbService.createTimer(timer);
    }
    _timerData = timer;
    return timer;
  }

  // 기본 타이머 생성 메서드
  Future<Map<String, dynamic>> _createDefaultTimer() async {
    final now = DateTime.now();
    final timerId = const Uuid().v4();
    int userTotalSeconds = 360000; // 기본값: 100시간

    return {
      'timer_id': timerId,
      'current_session_id': null,
      'week_start': getWeekStart(now),
      'total_seconds': userTotalSeconds,
      'timer_state': 'STOP', // 타이머 상태 키 (STOP이면 타이머 페이지, 그 외면 실행 중 페이지)
      'created_at': now.toUtc().toIso8601String(),
      'deleted_at': null,
      'last_started_at': null,
      'last_ended_at': null,
      'last_updated_at': now.toUtc().toIso8601String(),
      'is_deleted': 0,
      'timezone': DateTime.now().timeZoneName,
    };
  }

  String getWeekStart(DateTime date) {
    int weekday = date.weekday;
    // 월요일(1)을 기준으로 주 시작일 계산
    DateTime weekStart = date.subtract(Duration(days: weekday - 1));
    return weekStart.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          title: '100-Timer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: FutureBuilder<Map<String, dynamic>>(
            future: _initializationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // 초기화 중에는 로딩 인디케이터 표시
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                // 오류 발생 시 오류 메시지 표시
                return Scaffold(
                  body: Center(child: Text('Error: ${snapshot.error}')),
                );
              } else if (snapshot.hasData) {
                final timerData = snapshot.data!;
                // timer_state에 따라 TimerPage 또는 TimerRunningPage로 바로 이동
                if (timerData['timer_state'] != 'STOP') {
                  return TimerRunningPage(timerData: timerData);
                } else {
                  return TimerPage(timerData: timerData);
                }
              }
              // 데이터가 없는 경우 fallback 처리
              return const Scaffold(
                body: Center(child: Text('No data available')),
              );
            },
          ),
        );
      },
    );
  }
}
