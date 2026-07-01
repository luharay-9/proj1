import 'package:flutter/material.dart';

BoxDecoration panelDecoration() {
  return BoxDecoration(
    color: AppColors.panel,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.line),
  );
}

class AppColors {
  static const ink = Color(0xff07110c);
  static const deepInk = Color(0xff050d09);
  static const panel = Color(0xff122619);
  static const line = Color(0xff1f3728);
  static const text = Color(0xfff2fff5);
  static const softText = Color(0xffb7cbbb);
  static const muted = Color(0xff718174);
  static const pulse = Color(0xff74e285);
  static const cyan = Color(0xff66d8e5);
  static const gold = Color(0xffffc84f);
  static const red = Color(0xffff6f66);
  static const violet = Color(0xffa77cff);
}
