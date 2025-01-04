import 'package:flutter/material.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: context.hp(10)), // 여백 추가
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Copyright 2024.', style: AppTextStyles.getCaption(context)),
              SizedBox(
                width: context.wp(10),
                height: context.hp(5),
                child: ClipRRect(
                  child: Image.asset(
                    'assets/images/logo_3.png',
                  ),
                ),
              ),
              Text('Burning All rights reserved.', style: AppTextStyles.getCaption(context)),
            ],
          ),
        ),
      ],
    );
  }
}
