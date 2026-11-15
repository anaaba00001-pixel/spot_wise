import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_language';

  static const languages = <String, String>{
    'ar': 'العربية',
    'ur': 'اردو',
    'en': 'English',
    'pa': 'ਪੰਜਾਬੀ',
    'hi': 'हिन्दी',
    'id': 'Bahasa Indonesia',
    'tr': 'Türkçe',
    'bn': 'বাংলা',
    'cy': 'Cymraeg',
    'uz': "O‘zbekcha",
    'fr': 'Français',
    'ru': 'Русский',
    'ha': 'Hausa',
    'yo': 'Yorùbá',
    'ig': 'Igbo',
    'de': 'Deutsch',
    'zu': 'isiZulu',
    'xh': 'isiXhosa',
    'af': 'Afrikaans',
    'sfs': 'South African Sign Language',
    'am': 'አማርኛ',
    'om': 'Afaan Oromoo',
    'ti': 'ትግርኛ',
    'so': 'Soomaali',
    'aa': 'Qafar af',
    'sw': 'Kiswahili',
    'pt': 'Português',
    'es': 'Español',
  };

  Locale _locale = const Locale('ar', 'SA');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isRtl => const {'ar', 'ur'}.contains(languageCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && languages.containsKey(code)) {
      _locale = _localeFor(code);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!languages.containsKey(code) || code == languageCode) return;
    _locale = _localeFor(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  static Locale _localeFor(String code) => switch (code) {
        'ar' => const Locale('ar', 'SA'),
        'ur' => const Locale('ur', 'PK'),
        'pa' => const Locale('pa', 'IN'),
        _ => Locale(code),
      };
}
