import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:project1/config/store_secret.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PurchaseManager {
  static final PurchaseManager _instance = PurchaseManager._internal();
  factory PurchaseManager() => _instance;
  PurchaseManager._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  static const String removeAdsId = 'remove_ads';

  final List<String> _debugMessages = [];
  final StreamController<String> _debugController =
      StreamController<String>.broadcast();

  Stream<String> get debugStream => _debugController.stream;
  List<String> get debugMessages => List.unmodifiable(_debugMessages);

  void _addDebugMessage(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final debugMessage = '[$timestamp] $message';
    _debugMessages.add(debugMessage);
    _debugController.add(debugMessage);
    logger.d(message); // 기존 로깅도 유지
  }

  Future<void> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _addDebugMessage('InAppPurchase 사용 불가능');

      return;
    }
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(_handlePurchaseUpdate);
    _addDebugMessage('PurchaseManager 초기화 완료');
    await restorePurchases();
  }

  Future<void> restorePurchases() async {
    _addDebugMessage('구매 복원 시작');

    await _inAppPurchase.restorePurchases();
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    _addDebugMessage('구매 업데이트 수신: ${purchaseDetailsList.length}개');

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _addDebugMessage(
          '상품 ID: ${purchaseDetails.productID}, 상태: ${purchaseDetails.status}');

      if (purchaseDetails.productID == removeAdsId) {
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _addDebugMessage('광고 제거 구매 성공');
          await _saveAdRemovalStatus(true);
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          _addDebugMessage('구매 오류: ${purchaseDetails.error}');
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _addDebugMessage('구매 완료 처리 중');
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<bool> _verifyReceipt(PurchaseDetails purchaseDetails) async {
    try {
      final receiptData =
          purchaseDetails.verificationData.serverVerificationData;
      _addDebugMessage('영수증 검증 시작');

      // 프로덕션 환경 먼저 시도
      bool isValid = await _verifyWithApple(receiptData, false);

      if (!isValid) {
        // 샌드박스 환경 재시도
        _addDebugMessage('샌드박스 환경으로 재시도');
        isValid = await _verifyWithApple(receiptData, true);
      }

      return isValid;
    } catch (e) {
      _addDebugMessage('영수증 검증 오류: $e');
      return false;
    }
  }

  Future<bool> _verifyWithApple(String receiptData, bool sandbox) async {
    try {
      final String url = sandbox
          ? 'https://sandbox.itunes.apple.com/verifyReceipt'
          : 'https://buy.itunes.apple.com/verifyReceipt';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'receipt-data': receiptData,
          'password': StoreSecrets.sharedSecret,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final status = responseData['status'];

        _addDebugMessage('애플 서버 응답: status=$status');

        if (status == 0) {
          return true;
        } else if (status == 21007 && !sandbox) {
          // 샌드박스 영수증이 프로덕션으로 전송된 경우
          _addDebugMessage('샌드박스 영수증 감지, 재시도 필요');
          return false;
        }
      }

      _addDebugMessage('검증 실패: ${response.statusCode}');
      return false;
    } catch (e) {
      _addDebugMessage('HTTP 오류: $e');
      return false;
    }
  }

  Future<bool> buyRemoveAdsWithUI(BuildContext context) async {
    _addDebugMessage('광고 제거 구매 시작');

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails({removeAdsId});
    _addDebugMessage(
        '상품 조회 결과: ${response.productDetails.length}개, 오류: ${response.error}');

    if (response.productDetails.isNotEmpty) {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      final result =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      _addDebugMessage('구매 요청 결과: $result');

      if (result) {
        _showDialog(context, '구매 성공', '광고 제거가 완료되었습니다.');
      } else {
        _showDialog(context, '구매 실패', '구매 처리 중 오류가 발생했습니다.');
      }
      return result;
    }
    _addDebugMessage('구매 실패: 상품을 찾을 수 없음');
    _showDialog(context, '구매 실패', '상품을 찾을 수 없습니다.');
    return false;
  }

  Future<void> _saveAdRemovalStatus(bool removed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_removed', removed);
    _addDebugMessage('광고 제거 상태 저장: $removed');
  }

  Future<bool> isAdRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ads_removed') ?? false;
  }

  void clearDebugMessages() {
    _debugMessages.clear();
  }

  void dispose() {
    _subscription.cancel();
    _debugController.close();
  }

  Future<void> restorePurchasesWithUI(BuildContext context) async {
    _addDebugMessage('사용자 구매 복원 시작');

    try {
      await _inAppPurchase.restorePurchases();

      // 복원 후 잠시 대기하여 상태 확인
      await Future.delayed(Duration(seconds: 2));

      final bool adRemoved = await isAdRemoved();

      if (adRemoved) {
        _addDebugMessage('구매 복원 성공');
        _showDialog(context, '복원 성공', '구매 내역이 성공적으로 복원되었습니다.');
      } else {
        _addDebugMessage('복원할 구매 내역 없음');
        _showDialog(context, '복원 완료', '복원할 구매 내역이 없습니다.');
      }
    } catch (e) {
      _addDebugMessage('구매 복원 오류: $e');
      _showDialog(context, '복원 실패', '구매 복원 중 오류가 발생했습니다.');
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background(context),
        title: Text(
          title,
          style: AppTextStyles.getTitle(context),
        ),
        content: Text(
          message,
          style: AppTextStyles.getBody(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: AppTextStyles.getBody(context),
            ),
          ),
        ],
      ),
    );
  }
}
