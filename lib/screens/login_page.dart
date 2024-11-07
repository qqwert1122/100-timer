import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao_sdk;
import 'package:project1/screens/register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _idFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  Color idLabelColor = Colors.grey;
  Color passwordLabelColor = Colors.grey;

  void _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // After successful login, navigate to the next page or show success message
      print('User logged in: ${userCredential.user?.email}');
    } catch (e) {
      // Handle errors here, e.g., show an alert dialog
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            '로그인에 실패했습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '이메일 또는 비밀번호가 올바르지 않습니다.\n다시 확인해 주세요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '확인',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _idFocusNode.addListener(() {
      setState(() {
        idLabelColor = _idFocusNode.hasFocus ? Colors.redAccent : Colors.grey; // 포커스 여부에 따라 색상 변경
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        passwordLabelColor = _passwordFocusNode.hasFocus ? Colors.redAccent : Colors.grey; // 포커스 여부에 따라 색상 변경
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

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
      String email = user.kakaoAccount?.email ?? '';
      String nickname = user.kakaoAccount?.profile?.nickname ?? '';
      String profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';

      print('카카오 로그인 성공');
      print('이메일: $email');
      print('닉네임: $nickname');
    } catch (e) {
      print('카카오 로그인 실패: $e');
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
                  height: 150,
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
                  height: 50,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 기존 이메일 및 비밀번호 필드
                      Container(
                        width: 300,
                        height: 45,
                        child: TextFormField(
                          focusNode: _idFocusNode,
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: '이메일을 입력하세요', // 라벨 텍스트
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: idLabelColor,
                            ), // 라벨 텍스트 크기 설정
                            filled: true,
                            fillColor: Colors.grey[200], // 배경색 설정
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8), // 테두리 둥글기 설정
                              borderSide: BorderSide(color: Colors.transparent), // 밑줄 제거
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), // 테두리 둥글기 설정
                              borderSide: BorderSide(color: Colors.transparent), // 밑줄 제거
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), // 기본 테두리 둥글기 설정
                              borderSide: BorderSide(color: Colors.transparent), // 밑줄 제거
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력하세요';
                            } else if (!value.contains('@')) {
                              return '올바른 이메일 형식을 입력하세요';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Container(
                        width: 300,
                        height: 45,
                        child: TextFormField(
                          focusNode: _passwordFocusNode,
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: '비밀번호를 입력하세요', // 라벨 텍스트
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: passwordLabelColor,
                            ), // 라벨
                            filled: true,
                            fillColor: Colors.grey[200], // 배경색 설정
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8), // 테두리 둥글기 설정
                              borderSide: BorderSide(color: Colors.transparent), // 밑줄 제거
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), // 테두리 둥글기 설정
                              borderSide: BorderSide(color: Colors.transparent), // 밑줄 제거
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16), // 기본 테두리 둥글기 설정
                              borderSide: BorderSide(color: Colors.transparent), // 밑줄 제거
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력하세요';
                            } else if (value.length < 6) {
                              return '비밀번호는 최소 6자 이상이어야 합니다';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Container(
                        width: 300,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            '   이메일 로그인',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          textStyle: TextStyle(
                            decoration: TextDecoration.underline, // Underline the text
                          ),
                        ),
                        child: Text(
                          '이메일로 회원가입',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '또는',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            '간편하게 시작하기',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
