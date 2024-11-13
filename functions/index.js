const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.createCustomToken = functions.https.onCall(async (data, context) => {
  const kakaoUserId = data.data.kakaoUserId;

  if (!kakaoUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a Kakao user ID.');
  }

  try {
    // Firebase Auth에서 해당 UID의 사용자가 있는지 확인
    let userRecord;
    try {
      userRecord = await admin.auth().getUser(kakaoUserId);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // 사용자가 없으면 새로 생성
        userRecord = await admin.auth().createUser({
          uid: kakaoUserId,
        });
      } else {
        throw error;
      }
    }

    // 커스텀 토큰 생성
    const customToken = await admin.auth().createCustomToken(kakaoUserId);
    return { customToken };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message, error);
  }
});
