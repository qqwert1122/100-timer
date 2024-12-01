import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isUserDataAvailable = false; // Firestore에 사용자 문서가 있는지 여부
  String? _loginMethod; // 로그인 방법 저장
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isUserDataAvailable => _isUserDataAvailable;
  String? get loginMethod => _loginMethod;

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;

    if (_user != null) {
      // Firestore에서 사용자 문서 확인
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      _isUserDataAvailable = userDoc.exists;
    } else {
      _isUserDataAvailable = false;
      _loginMethod = null;
    }

    notifyListeners();
  }

  Future<void> signInWithCustomToken(String kakaoUserId, String nickname, String profileImageUrl) async {
    try {
      // Cloud Function 호출 준비
      final HttpsCallable callable = _functions.httpsCallable('createCustomToken');

      // Cloud Function 호출하여 커스텀 토큰 받아오기
      final response = await callable.call(<String, dynamic>{
        'kakaoUserId': kakaoUserId,
      });

      final String customToken = response.data['customToken'];

      // 커스텀 토큰으로 Firebase Auth 로그인
      UserCredential userCredential = await _auth.signInWithCustomToken(customToken);

      // 사용자 정보 업데이트
      await userCredential.user?.updateDisplayName(nickname);
      await userCredential.user?.updatePhotoURL(profileImageUrl);

      _loginMethod = 'kakao';

      // Firestore에서 사용자 등록 여부 확인
      final userId = userCredential.user?.uid;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        _isUserDataAvailable = userDoc.exists;
      } else {
        _isUserDataAvailable = false;
      }

      notifyListeners();
    } catch (e) {
      print('Firebase Auth 로그인 실패: $e');
    }
  }

  void updateUserDataAvailable(bool isAvailable) {
    _isUserDataAvailable = isAvailable;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Firebase Auth 로그아웃 실패: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    Map<String, dynamic>? data;
    String now = DateTime.now().toUtc().toIso8601String();

    if (_user != null) {
      String userId = _user!.uid;

      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          data = userDoc.data() as Map<String, dynamic>?;
        } else {
          print("사용자 데이터 없음");
        }
      } catch (e) {
        final error = {
          'uid': userId,
          'created_at': now,
          'error_message': e.toString(),
          'error_action': '사용자 데이터 가져오기 중',
        };
        print('error: 사용자 데이터 가져오기 중 오류 발생, $e');
        await _firestore.collection('errors').doc(userId).set(error);
      }
    } else {
      print('로그인된 사용자가 없습니다.');
    }

    return data;
  }

  void changeLoginMethod(String newMethod) {
    _loginMethod = newMethod;
  }
}
