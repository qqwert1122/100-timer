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
        SizedBox(height: context.hp(5)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Copyright 2025. ', style: AppTextStyles.getCaption(context)),
            Text('luceforge All rights reserved.', style: AppTextStyles.getCaption(context)),
          ],
        ),
        SizedBox(height: context.hp(2)),
      ],
    );
  }
}
