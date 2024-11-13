import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao_sdk;
import 'package:provider/provider.dart';
import '../utils/auth_provider.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _loginWithKakao() async {
    try {
      // 카카오톡 설치 여부 확인
      bool isInstalled = await kakao_sdk.isKakaoTalkInstalled();

      kakao_sdk.OAuthToken token;
      if (isInstalled) {
        // 카카오톡으로 로그인
        print('LoginPage(): _loginWithKakao() => loginWithKaKaoTalk()');
        token = await kakao_sdk.UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정으로 로그인
        print('LoginPage(): _loginWithKakao() => loginWithKakaoAccount()');
        token = await kakao_sdk.UserApi.instance.loginWithKakaoAccount();
      }

      // 사용자 정보 요청
      kakao_sdk.User user = await kakao_sdk.UserApi.instance.me();

      // 사용자 정보 활용
      String kakaoUserId = user.id.toString(); // 카카오 고유 ID (String 형식으로 변환)
      String nickname = user.kakaoAccount?.profile?.nickname ?? '';
      String profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';

      await Provider.of<AuthProvider>(context, listen: false).signInWithCustomToken(
        kakaoUserId,
        nickname,
        profileImageUrl,
      );
      print('LoginPage(): signInWithCustomToken()');
    } catch (e) {
      print('error: LoginPage() => 카카오 로그인 실패, $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '매주 100시간\n목표를 향해 불태우세요',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Image.asset(
                      width: 100,
                      height: 125,
                      'assets/images/logo_1.png',
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
                SizedBox(
                  height: 200,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '간편하게 시작하기',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: _loginWithKakao,
                      child: Image.asset(
                        'assets/images/kakao_login_medium_wide.png', // 버튼 이미지 경로
                        fit: BoxFit.cover,
                        width: 300,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
