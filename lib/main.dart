import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/firebase_options.dart';
import 'package:project1/screens/login_page.dart';
import 'package:project1/screens/splash_page.dart';
import 'package:project1/utils/auth_provider.dart';
import 'package:project1/utils/database_service.dart';
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
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TimerProvider>(
          create: (context) => TimerProvider(
            userId: '',
            databaseService: DatabaseService(),
          ),
          update: (context, authProvider, timerProvider) => TimerProvider(
            userId: authProvider.user?.uid ?? '',
            databaseService: DatabaseService(),
          ),
        ),
        Provider(create: (context) => DatabaseService()), // DatabaseService 제공
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, authProvider, _) {
      return MaterialApp(
        title: '100-Timer',
        // 라이트 모드 테마
        theme: ThemeData(
          fontFamily: 'NanumHuman',
          brightness: Brightness.light,
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: Colors.white,
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.red),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.2,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xff181C14),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.blue),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shadowColor: Colors.black,
            elevation: 0.2,
          ),
        ),
        home: const AuthWrapper(),
      );
    });
  }
}
