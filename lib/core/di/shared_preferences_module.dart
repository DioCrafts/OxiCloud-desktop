import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesModule {
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
} 