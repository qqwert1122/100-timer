import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class BreakCompletionWidget extends StatefulWidget {
  const BreakCompletionWidget({super.key});

  @override
  State<BreakCompletionWidget> createState() => _BreakCompletionWidgetState();
}

class _BreakCompletionWidgetState extends State<BreakCompletionWidget> {
  bool _isBreakCompletionEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(color: AppColors.background(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '휴식 완료 알림',
                style: AppTextStyles.getTitle(context),
              ),
              Text(
                '정해진 휴식이 끝나면 알려줘요',
                style: AppTextStyles.getBody(context).copyWith(color: AppColors.textSecondary(context)),
              ),
            ],
          ),
          SizedBox(height: context.hp(2)),
          Container(
            padding: context.paddingSM,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary(context).withValues(alpha: 0.08), // 그림자 색상
                  blurRadius: 10, // 그림자 흐림 정도
                  offset: const Offset(-2, 8), // 그림자 위치 (가로, 세로)
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/logos/logo_2.png',
                  width: context.xxl,
                  height: context.xxl,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지를 로드하는 데 실패한 경우의 대체 표시
                    return Container(
                      width: context.xl,
                      height: context.xl,
                      color: Colors.grey.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.broken_image,
                        size: context.xl,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
                SizedBox(width: context.wp(2)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '타이머 100',
                        style: AppTextStyles.getBody(context).copyWith(
                          wordSpacing: -0.3,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        '10분간의 휴식이 끝났어요!',
                        style: AppTextStyles.getBody(context).copyWith(
                          wordSpacing: -0.3,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _isBreakCompletionEnabled,
                  onChanged: (bool value) async {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isBreakCompletionEnabled = !_isBreakCompletionEnabled;
                    });
                  },
                  activeTrackColor: Colors.redAccent,
                  inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
          SizedBox(height: context.hp(2)),
        ],
      ),
    );
  }
}
