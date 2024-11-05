import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 패키지 추가
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스 생성

  // 스텝을 관리하기 위한 변수
  int _currentStep = 0;

  // 폼 키와 컨트롤러들
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // 버튼 활성화 여부
  bool _isButtonEnabled = false;

  // 이메일 중복 여부 체크 결과 저장
  String? _emailErrorMessage;

  // 이메일 유효성 검사
  void _validateEmail(String value) async {
    _emailErrorMessage = null; // 에러 메시지 초기화

    // 이메일이 비어 있거나 유효하지 않으면 버튼 비활성화
    if (value.isEmpty) {
      setState(() {
        _isButtonEnabled = false;
      });
      return;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      setState(() {
        _isButtonEnabled = false;
      });
      return;
    } else {
      // 이메일이 유효한 경우에만 중복 체크
      setState(() {
        _isButtonEnabled = false; // 중복 체크 중에는 버튼 비활성화
      });
      await _checkEmailExists(value.trim());
    }
  }

  // 이메일 중복 체크 함수
  Future<void> _checkEmailExists(String email) async {
    print('Checking email existence for: $email'); // 디버그 로그 추가
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('checkEmailExists');
      final response = await callable.call({'email': email});

      print('response: $response');
      final exists = response.data['exists'] as bool;
      print('exists: $exists');
      if (exists) {
        setState(() {
          _emailErrorMessage = '이미 사용 중인 이메일입니다';
          _isButtonEnabled = false;
        });
      } else {
        setState(() {
          _emailErrorMessage = null;
          _isButtonEnabled = true;
        });
      }
    } catch (e) {
      setState(() {
        _emailErrorMessage = '이메일 중복 확인 중 오류가 발생했습니다';
        _isButtonEnabled = false;
      });
      print('Error checking email existence: $e');
    }
  }

  // 비밀번호 유효성 검사
  void _validatePassword(String value) {
    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

  // 비밀번호 확인 유효성 검사
  void _validateConfirmPassword(String value) {
    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

  // 다음 버튼 눌렀을 때
  void _onNextPressed() async {
    if (_formKey.currentState!.validate()) {
      if (_currentStep == 0) {
        // 이메일 중복 체크
        await _checkEmailExists(_emailController.text.trim());
        if (_emailErrorMessage == null) {
          setState(() {
            _currentStep++;
            _isButtonEnabled = false;
          });
        } else {
          setState(() {
            _isButtonEnabled = false;
          });
        }
      } else if (_currentStep == 1) {
        setState(() {
          _currentStep++;
          _isButtonEnabled = false;
        });
      } else if (_currentStep == 2) {
        // 회원가입 로직 실행
        _register();
      }
    }
  }

  // 회원가입 함수
  void _register() async {
    try {
      // Firebase Auth에 사용자 생성
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'uid': userCredential.user!.uid,
        // 필요한 추가 정보가 있다면 여기에 입력
      });

      // 회원가입 성공 시 처리
      print('User registered: ${userCredential.user?.email}');
      // 다음 페이지로 이동 또는 성공 메시지 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('회원가입 완료'),
          content: const Text('회원가입이 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 회원가입 페이지 닫기
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 오류 처리
      print('Error during registration: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('회원가입 오류'),
          content: Text('회원가입 중 오류가 발생했습니다.\n${e.toString()}'),
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

  // 현재 스텝에 따른 위젯 반환
  Widget _buildStepContent() {
    // 공통 스타일
    final underlineInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
    );
    final focusedUnderlineInputBorder = const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
    );

    switch (_currentStep) {
      case 0:
        // 이메일 입력 단계
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이메일을 입력하세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: underlineInputBorder,
                enabledBorder: underlineInputBorder,
                focusedBorder: focusedUnderlineInputBorder,
                hintText: 'example@example.com',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해주세요';
                } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                  return '유효한 이메일을 입력해주세요';
                } else if (_emailErrorMessage != null) {
                  return _emailErrorMessage;
                }
                return null;
              },
              onChanged: _validateEmail,
            ),
            const SizedBox(height: 8),
          ],
        );
      case 1:
        // 비밀번호 입력 단계
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '비밀번호를 입력하세요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: underlineInputBorder,
                enabledBorder: underlineInputBorder,
                focusedBorder: focusedUnderlineInputBorder,
                hintText: '비밀번호',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요';
                } else if (value.length < 6) {
                  return '비밀번호는 최소 6자 이상이어야 합니다';
                } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$').hasMatch(value)) {
                  return '영문과 숫자를 포함하여 6자 이상이어야 합니다';
                }
                return null;
              },
              onChanged: _validatePassword,
            ),
            const SizedBox(height: 8),
            const Text(
              '영문과 숫자를 포함하여 6자 이상 입력해주세요.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        );
      case 2:
        // 비밀번호 확인 단계
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '비밀번호를 다시 입력하세요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: underlineInputBorder,
                enabledBorder: underlineInputBorder,
                focusedBorder: focusedUnderlineInputBorder,
                hintText: '비밀번호 확인',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 다시 입력해주세요';
                } else if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
              onChanged: _validateConfirmPassword,
            ),
            const SizedBox(height: 8),
            const Text(
              '앞서 입력한 비밀번호와 동일하게 입력해주세요.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 키보드가 올라왔을 때 화면이 밀리지 않도록 설정
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 다른 곳 터치 시 키보드 닫기
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey, // 폼 유효성 검사를 위해 사용
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  _buildStepContent(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          right: 16,
          left: 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled ? _onNextPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled ? Colors.redAccent : Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '다음',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
