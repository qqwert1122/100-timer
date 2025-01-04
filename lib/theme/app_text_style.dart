import 'package:flutter/material.dart';
import '../utils/responsive_size.dart';

class AppTextStyles {
  static TextStyle getTimeDisplay(BuildContext context) {
    return TextStyle(
      fontSize: context.wp(10),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle getHeadline(BuildContext context) {
    return TextStyle(
      fontSize: context.xl,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getTitle(BuildContext context) {
    return TextStyle(
      fontSize: context.lg,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getBody(BuildContext context) {
    return TextStyle(
      fontSize: context.md,
    );
  }

  static TextStyle getCaption(BuildContext context) {
    return TextStyle(
      fontSize: context.sm,
      color: Colors.grey,
    );
  }
}
