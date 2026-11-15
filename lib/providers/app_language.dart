import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage(this._auth) {
    _auth.addListener(_onAccountChanged);
  }

  final AuthProvider _auth;
  final _preferences = SharedPreferencesAsync();

  String? _accountId;
  Locale _locale = const Locale('ar');
  bool _saving = false;
  bool _disposed = false;
  int _revision = 0;

  Locale get locale => _locale;
  bool get saving => _saving;

  String _key(String accountId) => 'preferred_language.$accountId';

  void _onAccountChanged() {
    if (_auth.user?.id != _accountId) load();
  }

  Future<void> load() async {
    final accountId = _auth.user?.id;
    final revision = ++_revision;
    _accountId = accountId;
    _locale = const Locale('ar');
    _saving = false;
    notifyListeners();

    if (accountId == null) return;

    try {
      final code = await _preferences.getString(_key(accountId));
      if (_disposed || revision != _revision) return;
      _locale = Locale(code == 'en' ? 'en' : 'ar');
      notifyListeners();
    } catch (_) {
      // Keep Arabic if the saved preference cannot be read.
    }
  }

  Future<void> setLanguage(String code) async {
    final accountId = _accountId;
    if (accountId == null || _saving || (code != 'ar' && code != 'en')) {
      return;
    }

    final revision = ++_revision;
    _saving = true;
    notifyListeners();

    try {
      await _preferences.setString(_key(accountId), code);
      if (!_disposed && revision == _revision) _locale = Locale(code);
    } finally {
      if (!_disposed && revision == _revision) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAccountChanged);
    super.dispose();
  }
}
