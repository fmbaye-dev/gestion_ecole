import 'package:flutter/foundation.dart';

class AppLogger {
  static const _prefix = "[AppLogger]";
  static const bool estEnModeDebogage = kDebugMode;

  static void info(String message) {
    if (estEnModeDebogage) debugPrint("$_prefix => [INFO] => $message");
  }

  static void avertissement(String message) {
    if (estEnModeDebogage) {
      debugPrint("$_prefix => [AVERTISSEMENT] => $message");
    }
  }

  static void erreur(String message) {
    if (estEnModeDebogage) {
      debugPrint("$_prefix => [ERREUR] => $message");
    }
  }
}
