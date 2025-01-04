import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao_sdk;
import 'package:project1/theme/app_text_style.dart';
import 'package:provider/provider.dart';
import '../utils/auth_provider.dart';
import 'package:project1/utils/responsive_size.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
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
        token = await kakao_sdk.UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정으로 로그인
        token = await kakao_sdk.UserApi.instance.loginWithKakaoAccount();
      }

      // 사용자 정보 요청
      kakao_sdk.User user = await kakao_sdk.UserApi.instance.me();

      // 사용자 정보 활용
      String kakaoUserId = user.id.toString(); // 카카오 고유 ID (String 형식으로 변환)
      String? nickname = user.kakaoAccount?.profile?.nickname;
      String? profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;

      // 프로필 정보 동의 여부 확인 및 추가 동의 요청
      if (nickname == null || profileImageUrl == null) {
        List<String> requiredScopes = [];
        if (user.kakaoAccount?.profileNeedsAgreement == true) {
          requiredScopes.add('profile');
        }
        if (requiredScopes.isNotEmpty) {
          // 추가 동의 요청
          bool granted = await _requestAdditionalPermissions(requiredScopes);
          if (granted) {
            // 동의 후 사용자 정보 재요청
            user = await kakao_sdk.UserApi.instance.me();
            nickname = user.kakaoAccount?.profile?.nickname;
            profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
          } else {
            // 동의하지 않으면 예외 처리
            throw Exception('필수 정보 제공에 동의하지 않았습니다.');
          }
        }
      }

      // nickname과 profileImageUrl이 null인 경우 기본값 설정
      nickname ??= '사용자';
      profileImageUrl ??= '';

      Provider.of<AuthProvider>(context, listen: false).changeLoginMethod('kakao');

      await Provider.of<AuthProvider>(context, listen: false).signInWithCustomToken(
        kakaoUserId,
        nickname,
        profileImageUrl,
      );
    } catch (e) {
      print('error: LoginPage() => 카카오 로그인 실패, $e');
      // 에러 처리
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그인 실패'),
          content: const Text('카카오 로그인 중 오류가 발생했습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _requestAdditionalPermissions(List<String> scopes) async {
    try {
      kakao_sdk.OAuthToken token = await kakao_sdk.UserApi.instance.loginWithNewScopes(scopes);
      print('필수 동의항목 획득 성공 ${token.scopes}');
      return true;
    } catch (e) {
      print('error: 추가 동의 요청 실패 $e');
      return false;
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
            padding: context.paddingXL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.hp(25)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '100-timer',
                      style: TextStyle(
                        fontSize: context.wp(10),
                        fontFamily: 'chab',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ',',
                      style: TextStyle(
                        fontSize: context.wp(10),
                        fontFamily: 'chab',
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.hp(5)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '매주',
                      style: AppTextStyles.getHeadline(context).copyWith(color: Colors.grey),
                    ),
                    SizedBox(width: context.wp(2)),
                    Text(
                      '100',
                      style:
                          AppTextStyles.getHeadline(context).copyWith(fontFamily: 'chab', fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                    Text(
                      '시간,',
                      style: AppTextStyles.getHeadline(context).copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  '목표를 향해 불태우세요',
                  style: AppTextStyles.getHeadline(context).copyWith(color: Colors.grey),
                ),
                SizedBox(height: context.hp(20)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '간편하게 시작하기',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loginWithKakao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Image.asset(
                        'assets/images/kakao_login_medium_wide.png', // 버튼 이미지 경로
                        fit: BoxFit.cover,
                        width: 300,
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
