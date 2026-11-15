import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/app_exception.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../backend/backend_service.dart';
import 'auth_service.dart';

/// Firebase Authentication via the Identity Toolkit REST API (raw `http`, no
/// `firebase_auth` SDK → compiles with zero platform config).
///
/// Inert until `FIREBASE_API_KEY` is set in `.env`; [ServiceLocator] then picks
/// it over the local auth service. The user profile record is stored in the
/// backend (Realtime DB) keyed by the Firebase `localId`.
class FirebaseAuthRestService implements AuthService {
  static const _base = 'https://identitytoolkit.googleapis.com/v1/accounts';
  static const _sessionKey = 'session_uid';

  final BackendService backend;
  final http.Client _client;
  FirebaseAuthRestService(this.backend, {http.Client? client})
    : _client = client ?? http.Client();

  AppUser? _current;
  String? _refreshToken;
  String? _idToken;
  DateTime? _tokenExpires;

  void _rememberTokens(
    Map<String, dynamic> data, {
    bool refreshed = false,
  }) {
    final idToken = data[refreshed ? 'id_token' : 'idToken'] as String?;
    final refreshToken =
        data[refreshed ? 'refresh_token' : 'refreshToken'] as String?;
    final seconds =
        int.tryParse('${data[refreshed ? 'expires_in' : 'expiresIn']}') ?? 3600;
    _idToken = idToken;
    _refreshToken = refreshToken;
    _tokenExpires = DateTime.now().add(Duration(seconds: seconds - 60));
  }

  Future<String?> currentIdToken() async {
    if (_current == null) return null;
    if (_tokenExpires?.isAfter(DateTime.now()) == true) return _idToken;
    final refresh = _refreshToken;
    if (refresh == null) return null;
    final response = await _client
        .post(
          Uri.https('securetoken.googleapis.com', '/v1/token', {'key': _key}),
          body: {'grant_type': 'refresh_token', 'refresh_token': refresh},
        )
        .timeout(const Duration(seconds: 10));
    if (_refreshToken != refresh || response.statusCode != 200) {
      return null;
    }
    _rememberTokens(
      jsonDecode(response.body) as Map<String, dynamic>,
      refreshed: true,
    );
    return _idToken;
  }

  @override
  AppUser? get currentUser => _current;

  String get _key {
    final k = AppConfig.firebaseApiKey;
    if (k.isEmpty) {
      throw const NotConfiguredException(
        'Firebase Auth is not configured. Add FIREBASE_API_KEY to .env '
        '(see Settings → Integrations).',
      );
    }
    return k;
  }

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_sessionKey);
    if (uid != null) {
      _current = await backend.getUser(uid);
    }
  }

  Future<Map<String, dynamic>> _call(
    String method,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.post(
      Uri.parse('$_base:$method?key=$_key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthException(_friendly(data));
    }
    return data;
  }

  String _friendly(Map<String, dynamic> error) {
    final code = (error['error']?['message'] ?? '').toString();
    return switch (code) {
      'EMAIL_EXISTS' => 'An account already exists for that email.',
      'INVALID_PASSWORD' ||
      'INVALID_LOGIN_CREDENTIALS' => 'Incorrect email or password.',
      'EMAIL_NOT_FOUND' => 'No account found for that email.',
      'WEAK_PASSWORD : Password should be at least 6 characters' =>
        'Use a stronger password (at least 6 characters).',
      'USER_DISABLED' => 'That account has been disabled.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final data = await _call('signInWithPassword', {
      'email': email.trim(),
      'password': password,
      'returnSecureToken': true,
    });
    final uid = data['localId'].toString();
    final profile = await backend.getUser(uid);
    final user = profile?.copyWith(email: email.trim()) ??
        AppUser(
          id: uid,
          name: email.split('@').first,
          email: email.trim(),
          createdAt: DateTime.now(),
        );
    // Re-save through the backend's privacy-safe serializer. This also removes
    // email fields left in older public profile records after the next sign-in.
    await backend.saveUser(user);
    await _persistSession(uid);
    _current = user;
    _rememberTokens(data);
    return user;
  }

  @override
  Future<AppUser> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.user,
  }) async {
    final data = await _call('signUp', {
      'email': email.trim(),
      'password': password,
      'returnSecureToken': true,
    });
    final uid = data['localId'].toString();
    final user = AppUser(
      id: uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    await backend.saveUser(user);
    await _persistSession(uid);
    _current = user;
    _rememberTokens(data);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _call('sendOobCode', {
      'requestType': 'PASSWORD_RESET',
      'email': email.trim(),
    });
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _current = null;
    _refreshToken = null;
    _idToken = null;
    _tokenExpires = null;
  }

  @override
  void cacheUser(AppUser user) => _current = user;

  Future<void> _persistSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, uid);
  }
}
