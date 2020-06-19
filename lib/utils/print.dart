import 'package:io/ansi.dart';

class Print {
  /// Prints sucess message
  static void success(String message) {
    print(green.wrap(message));
  }

  static void warning(String message) {
    print(yellow.wrap(message));
  }

  static void info(String message) {
    print(cyan.wrap(message));
  }

  static void error(String message) {
    print(red.wrap(message));
  }
}
