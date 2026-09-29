import 'dart:math';
import 'package:flutter/material.dart';

class Responsive {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  static late double _screenWidth;
  static late double _screenHeight;
  static late double _scaleWidth;
  static late double _scaleHeight;
  static late double _scaleText;
  static late double _statusBarHeight;
  static late double _bottomPadding;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;
    _statusBarHeight = mq.padding.top;
    _bottomPadding = mq.padding.bottom;
    _scaleWidth = _screenWidth / _designWidth;
    _scaleHeight = _screenHeight / _designHeight;
    _scaleText = min(_scaleWidth, 1.3);
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static double get statusBarHeight => _statusBarHeight;
  static double get bottomPadding => _bottomPadding;

  static double w(double size) => size * _scaleWidth;
  static double h(double size) => size * _scaleHeight;
  static double sp(double size) => size * _scaleText;
  static double r(double size) => size * min(_scaleWidth, _scaleHeight);

  static bool get isSmallScreen => _screenWidth < 360;
  static bool get isMediumScreen => _screenWidth >= 360 && _screenWidth < 400;
  static bool get isLargeScreen => _screenWidth >= 400;
  static bool get isShortScreen => _screenHeight < 700;
  static bool get isTallScreen => _screenHeight >= 800;

  static EdgeInsets padding({
    double left = 0, double top = 0,
    double right = 0, double bottom = 0,
  }) => EdgeInsets.fromLTRB(w(left), h(top), w(right), h(bottom));

  static EdgeInsets symmetricPadding({
    double horizontal = 0, double vertical = 0,
  }) => EdgeInsets.symmetric(horizontal: w(horizontal), vertical: h(vertical));
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 360;
  bool get isShortScreen => screenHeight < 700;
  double get headerFraction => isShortScreen ? 0.30 : 0.45;
}
