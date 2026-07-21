import 'package:flutter/foundation.dart';

class ShellScope {
  ShellScope._();

  static const double bottomNavHeight = 84;

  static final ValueNotifier<bool> isShellRoute = ValueNotifier<bool>(false);
  static final ValueNotifier<String> location = ValueNotifier<String>('/home');
}
