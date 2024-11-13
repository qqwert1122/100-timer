// auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project1/screens/login_page.dart';
import 'package:project1/screens/register_page.dart';
import 'package:project1/screens/splash_page.dart';
import 'package:project1/utils/auth_provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print('AuthWrapper: isAuthenticated = ${authProvider.isAuthenticated}, isUserDataAvailable = ${authProvider.isUserDataAvailable}');

        if (authProvider.isAuthenticated) {
          if (authProvider.isUserDataAvailable) {
            // 사용자 데이터가 존재하면 메인 화면으로 이동
            return SplashScreen(userId: authProvider.user!.uid);
          } else {
            // 사용자 데이터가 없으면 회원가입 페이지로 이동
            return RegisterPage(
              uid: authProvider.user!.uid,
              userName: authProvider.user!.displayName ?? '',
              profileImage: authProvider.user!.photoURL ?? '',
              method: authProvider.loginMethod ?? '',
            );
          }
        } else {
          // 로그인되지 않은 경우 로그인 화면으로 이동
          return LoginPage();
        }
      },
    );
  }
}
