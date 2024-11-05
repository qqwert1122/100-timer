import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project1/firebase_options.dart';
import 'package:project1/screens/splash_page.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  String userId = 'v3_4';
  final DatabaseService databaseService = DatabaseService();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TimerProvider(userId: userId, databaseService: databaseService),
        ),
        Provider(create: (context) => DatabaseService()), // DatabaseService 제공
      ],
      child: MyApp(
        userId: userId,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String userId;

  const MyApp({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
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
      home: SplashScreen(
        userId: userId,
      ),
    );
  }
}
