import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_provider.dart';

extension AppStringsContext on BuildContext {
  String tr(String key) {
    final code = watch<LocaleProvider>().languageCode;
    return _values[code]?[key] ?? _values['en']![key] ?? key;
  }
}

const _values = <String, Map<String, String>>{
  'ar': {
    'settings': 'الإعدادات',
    'appearance': 'المظهر',
    'system': 'النظام',
    'light': 'فاتح',
    'dark': 'داكن',
    'language': 'لغة التطبيق',
    'chooseLanguage': 'اختاري لغة',
    'languageSaved': 'تم تغيير لغة التطبيق',
    'languageError': 'تعذّر حفظ اللغة. حاولي مرة أخرى.',
    'setup': 'الإعداد والربط',
    'integrations': 'التكاملات والإعداد',
    'integrationsSubtitle': 'ربط Firebase وGemini والمزيد لاحقًا',
    'resetDemo': 'إعادة بيانات العرض',
    'resetDemoSubtitle': 'استعادة المحتوى التجريبي الأصلي',
    'home': 'الرئيسية',
    'map': 'الخريطة',
    'categories': 'الفئات',
    'favorites': 'المفضلة',
    'addPlace': 'إضافة مكان',
  },
  'en': {
    'settings': 'Settings',
    'appearance': 'Appearance',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'language': 'App language',
    'chooseLanguage': 'Choose a language',
    'languageSaved': 'App language changed',
    'languageError': 'Could not save the language. Please try again.',
    'setup': 'Setup',
    'integrations': 'Integrations & setup',
    'integrationsSubtitle': 'Connect Firebase, Gemini and more later',
    'resetDemo': 'Reset demo data',
    'resetDemoSubtitle': 'Restore the original seeded content',
    'home': 'Home',
    'map': 'Map',
    'categories': 'Categories',
    'favorites': 'Favorites',
    'addPlace': 'Add a place',
  },
};
