// auth_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';

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
      final userDoc = await _firestore.collection('users').doc(kakaoUserId).get();

      _isUserDataAvailable = userDoc.exists;
      notifyListeners();
    } catch (e) {
      print('Firebase Auth 로그인 실패: $e');
    }
  }

  // Future<void> signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) {
  //       // 사용자가 로그인 취소
  //       return;
  //     }

  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // FirebaseAuth에 로그인
  //     UserCredential userCredential = await _auth.signInWithCredential(credential);

  //     // 사용자 정보 업데이트
  //     await userCredential.user?.updateDisplayName(userCredential.user?.displayName);
  //     await userCredential.user?.updatePhotoURL(userCredential.user?.photoURL);

  //     _loginMethod = 'google';

  //     // Firestore에서 사용자 등록 여부 확인
  //     final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

  //     _isUserDataAvailable = userDoc.exists;
  //     notifyListeners();
  //   } catch (e) {
  //     print('Google 로그인 실패: $e');
  //   }
  // }

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
}
