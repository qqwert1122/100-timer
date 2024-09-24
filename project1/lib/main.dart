import 'package:flutter/material.dart';
import 'package:project1/screens/splash_page.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TimerProvider(),
        ),
        Provider(create: (context) => DatabaseService()), // DatabaseService 제공
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '타이머 앱',
      // 라이트 모드 테마
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(backgroundColor: Colors.red),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          elevation: 0.2,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xff181C14),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(backgroundColor: Colors.blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.blue,
          shadowColor: Colors.black,
          elevation: 0.2,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
