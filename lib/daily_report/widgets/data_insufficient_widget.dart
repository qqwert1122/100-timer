import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:shimmer/shimmer.dart';

class DataInsufficientWidget extends StatelessWidget {
  const DataInsufficientWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: AppColors.textSecondary(context),
        highlightColor: AppColors.background(context),
        period: Duration(milliseconds: 3000),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty_box.png',
              width: context.wp(30),
              height: context.wp(30),
              errorBuilder: (context, error, stackTrace) => Icon(
                LucideIcons.squareKanbanDashed,
                size: context.xxxl,
                color: AppColors.textSecondary(context),
              ),
            ),
            Text(
              '기록이 충분하지 않아서\n리포트를 생성할 수 없어요',
              style: AppTextStyles.getBody(context).copyWith(
                color: AppColors.textSecondary(context),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
