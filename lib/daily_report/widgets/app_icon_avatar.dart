import 'package:flutter/material.dart';
import 'package:project1/utils/icon_utils.dart';

class AppIconAvatar extends StatelessWidget {
  const AppIconAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logos/logo_2.png',
      width: 50,
      height: 50,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox();
      },
    );
  }
}
