import 'package:flutter/animation.dart';

abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 180);
  static const slow = Duration(milliseconds: 400);
  static const curve = Curves.easeOutCubic;
}
