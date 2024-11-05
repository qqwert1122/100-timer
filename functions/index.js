const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.checkEmailExists = functions.https.onCall(async (data, context) => {
  console.log("Received data:", data); // 디버그 로그 추가
  const email = data.data.email;

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "이메일이 필요합니다.");
  }

  try {
    await admin.auth().getUserByEmail(email);
    // 사용자가 존재하면 true 반환
    return {exists: true};
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      // 사용자가 없으면 false 반환
      return {exists: false};
    } else {
      // 그 외의 에러 처리
      throw new functions.https.HttpsError("unknown", error.message);
    }
  }
});
