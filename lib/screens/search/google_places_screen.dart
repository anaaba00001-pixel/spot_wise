import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth/firebase_auth_rest_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/max_width.dart';

class GooglePlacesScreen extends StatefulWidget {
  const GooglePlacesScreen({super.key});

  @override
  State<GooglePlacesScreen> createState() => _GooglePlacesScreenState();
}

class _GooglePlacesScreenState extends State<GooglePlacesScreen> {
  final _query = TextEditingController();
  final _client = http.Client();
  List<Map<String, dynamic>> _places = [];
  String? _message;
  bool _busy = false;
  bool _signIn = false;

  Uri? get _endpoint {
    final base = Uri.tryParse(Env.googlePlacesProxyUrl);
    if (base == null ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment)
      return null;
    final local = const ['localhost', '127.0.0.1', '::1'].contains(base.host);
    if (base.scheme != 'https' && !(local && base.scheme == 'http'))
      return null;
    final path = base.path.replaceFirst(RegExp(r'/$'), '');
    return base.replace(path: '$path/api/places/search');
  }

  @override
  void dispose() {
    _client.close();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_busy) return;
    final endpoint = _endpoint;
    final query = _query.text.trim();
    if (endpoint == null || query.length < 2) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _places = [];
      _message = null;
      _signIn = false;
    });
    try {
      final auth = services.auth;
      final token = auth is FirebaseAuthRestService
          ? await auth.currentIdToken()
          : null;
      if (!mounted) return;
      if (token == null) {
        _signIn = auth is FirebaseAuthRestService;
        _message = _signIn
            ? 'سجّلي الدخول بحساب دلال للبحث.'
            : 'البحث يحتاج تسجيل دخول Firebase في إعدادات دلال.';
        return;
      }
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      if (response.statusCode == 401) {
        _signIn = true;
        _message = 'انتهت جلسة البحث. سجّلي الدخول من جديد.';
      } else if (response.statusCode == 429) {
        _message = 'وصل البحث للحد المؤقت. جرّبي بعد قليل.';
      } else if (response.statusCode != 200) {
        _message = 'تعذّر البحث في قوقل ماب. جرّبي مرة ثانية.';
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _places = (body['places'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
        if (_places.isEmpty) _message = 'ما لقينا أماكن مطابقة.';
      }
    } on TimeoutException {
      _message = 'تأخر الرد. جرّبي البحث مرة ثانية.';
    } catch (_) {
      _message = 'تعذّر الاتصال بخدمة البحث.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // The platform may have no external handler.
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = _endpoint != null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('البحث في قوقل ماب')),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!configured)
              const Text('خدمة البحث تحتاج ضبط عنوان الخادم في إعدادات دلال.')
            else ...[
              TextField(
                controller: _query,
                enabled: !_busy,
                maxLength: 150,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'مثال: مقاهي في حائل',
                ),
                onSubmitted: (_) => _search(),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _search,
                icon: const Icon(Icons.search),
                label: const Text('بحث'),
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_message != null) ListTile(title: Text(_message!)),
              if (_signIn)
                TextButton(
                  onPressed: () async {
                    final signedIn = await Navigator.pushNamed(
                      context,
                      AppRoutes.login,
                    );
                    if (mounted && signedIn == true) await _search();
                  },
                  child: const Text('تسجيل الدخول'),
                ),
              if (_places.isNotEmpty)
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Image.asset(
                          dark
                              ? 'assets/google-maps-attribution-dark.png'
                              : 'assets/google-maps-attribution.png',
                          height: 18,
                          semanticLabel: 'Google Maps',
                        ),
                      ),
                      for (final place in _places) _result(place),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _result(Map<String, dynamic> place) {
    final name = place['name'] as String;
    final address = place['address'] as String;
    final maps = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.isEmpty ? name : '$name $address',
      'query_place_id': place['id'] as String,
    });
    return ListTile(
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty) Text(address),
          for (final attribution
              in (place['attributions'] as List)
                  .whereType<Map<String, dynamic>>())
            if (Uri.tryParse(attribution['url'] as String)?.scheme == 'https')
              TextButton(
                onPressed: () => _open(Uri.parse(attribution['url'] as String)),
                child: Text(attribution['name'] as String),
              )
            else
              Text(attribution['name'] as String),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new),
        tooltip: 'فتح في قوقل ماب',
        onPressed: () => _open(maps),
      ),
    );
  }
}
