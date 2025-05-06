import 'package:flutter/material.dart';

extension ResponsiveSize on BuildContext {
  // 화면 사이즈 가져오기
  MediaQueryData get _mq => MediaQuery.of(this);

  double get width => _mq.size.width;
  double get height => _mq.size.height;

  // 퍼센트 기준 너비/높이
  double wp(double percent) => width * percent / 100;
  double hp(double percent) => height * percent / 100;

  // 폰트 사이즈
  double get xs => width * 0.02; // 아주 작은 텍스트
  double get sm => width * 0.03; // 작은 텍스트
  double get md => width * 0.04; // 중간 텍스트
  double get lg => width * 0.05; // 큰 텍스트
  double get xl => width * 0.06; // 아주 큰 텍스트
  double get xxl => width * 0.10;
  double get xxxl => width * 0.14; // 아주아주 큰 텍스트

  // 여백 사이즈
  double get spacing_xs => width * 0.02; // 아주 작은 여백
  double get spacing_sm => width * 0.04; // 작은 여백
  double get spacing_md => width * 0.06; // 중간 여백
  double get spacing_lg => width * 0.08; // 큰 여백
  double get spacing_xl => width * 0.10; // 큰 여백

  // 반응형 패딩
  EdgeInsets get paddingXS => EdgeInsets.all(spacing_xs);
  EdgeInsets get paddingSM => EdgeInsets.all(spacing_sm);
  EdgeInsets get paddingMD => EdgeInsets.all(spacing_md);
  EdgeInsets get paddingLG => EdgeInsets.all(spacing_lg);
  EdgeInsets get paddingXL => EdgeInsets.all(spacing_xl);

  EdgeInsets get paddingHorizXS => EdgeInsets.symmetric(horizontal: spacing_xs);
  EdgeInsets get paddingHorizSM => EdgeInsets.symmetric(horizontal: spacing_sm);
  EdgeInsets get paddingHorizMD => EdgeInsets.symmetric(horizontal: spacing_md);
  EdgeInsets get paddingHorizLG => EdgeInsets.symmetric(horizontal: spacing_lg);
  EdgeInsets get paddingHorizXL => EdgeInsets.symmetric(horizontal: spacing_xl);
}
