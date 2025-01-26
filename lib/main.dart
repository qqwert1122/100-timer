import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/firebase_options.dart';
import 'package:project1/theme/app_theme.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/device_info_service.dart';
import 'package:project1/utils/error_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:project1/widgets/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  KakaoSdk.init(nativeAppKey: 'e61da8880887bcab5a697b74091d0b84'); // 네이티브 앱 키 입력
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        Provider(create: (context) => DeviceInfoService()),
        Provider(
            create: (context) => ErrorService(
                  authProvider: context.read<AuthProvider>(),
                  deviceInfoService: context.read<DeviceInfoService>(),
                )),
        Provider<DatabaseService>(
          create: (context) => DatabaseService(
            authProvider: context.read<AuthProvider>(),
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
        ChangeNotifierProxyProvider2<DatabaseService, ErrorService, TimerProvider>(
          // 최초 생성
          create: (context) => TimerProvider(
            context,
            dbService: context.read<DatabaseService>(),
            statsProvider: context.read<StatsProvider>(),
            errorService: context.read<ErrorService>(),
            authProvider: context.read<AuthProvider>(),
          ),
          // 의존성이 업데이트될 때마다 기존 인스턴스를 재활용
          update: (context, databaseService, errorService, existingTimerProvider) {
            if (existingTimerProvider == null) {
              // 기존 인스턴스가 없으면 새로 생성
              return TimerProvider(
                context,
                dbService: databaseService,
                statsProvider: context.read<StatsProvider>(),
                errorService: errorService,
                authProvider: context.read<AuthProvider>(),
              );
            } else {
              // 기존 인스턴스가 있으면 필요한 의존성만 업데이트
              existingTimerProvider.updateDependencies(
                dbService: databaseService,
                errorService: errorService,
                // 필요한 경우 statsProvider 등도 함께 업데이트
              );
              return existingTimerProvider;
            }
          },
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, authProvider, _) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        title: '100-Timer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      );
    });
  }
}
