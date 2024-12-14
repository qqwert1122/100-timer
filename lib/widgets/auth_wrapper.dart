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
        // 인증 상태에 따른 화면 분기 처리
        if (authProvider.isAuthenticated) {
          final user = authProvider.user;

          if (user == null) {
            return _buildErrorScreen('사용자 정보가 없습니다. 다시 로그인 해주세요.');
          }

          if (authProvider.isUserDataAvailable) {
            // 사용자 데이터가 존재하는 경우 스플래시 화면
            return SplashScreen(userId: user.uid);
          } else {
            // 사용자 데이터가 없으면 회원가입 페이지로 이동
            return RegisterPage(
              uid: user.uid,
              userName: user.displayName ?? '',
              profileImage: user.photoURL ?? '',
              method: authProvider.loginMethod ?? '',
            );
          }
        } else {
          // 로그인되지 않은 경우 로그인 화면으로 이동
          return const LoginPage();
        }
      },
    );
  }

  // 에러 화면 구성
  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 에러 발생 시 로그인 화면으로 이동
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('로그인 화면으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
