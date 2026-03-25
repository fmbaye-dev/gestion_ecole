import 'package:gestion_ecole/config/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  //! La methode init
  static late SharedPreferences prefs;

  static Future<void> init() async {
    //! initialiser les preferences de l'application
    AppLogger.info("Initialiser les preferences de l'application....");
    prefs = await SharedPreferences.getInstance();
    AppLogger.info("Preferences de l'appliction initialiser avec succes");
  }

  //! methode pour obtenir une preference
  static String? getString(String key) {
    final result = prefs.getString(key);
    return result;
  }
}
