import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth/firebase_auth_rest_service.dart';
import '../../services/backend/csv_file_picker.dart';
import '../../services/backend/firebase_rest_backend_service.dart';
import '../../services/backend/spot_csv.dart';
import '../../services/service_locator.dart';
import '../../widgets/max_width.dart';

class AdminImportSpotsScreen extends StatefulWidget {
  const AdminImportSpotsScreen({super.key});

  @override
  State<AdminImportSpotsScreen> createState() => _AdminImportSpotsScreenState();
}

class _AdminImportSpotsScreenState extends State<AdminImportSpotsScreen> {
  final _input = TextEditingController();
  SpotCsvPreview? _preview;
  String? _message;
  bool _saving = false;
  bool _done = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _parse() {
    final user = context.read<AuthProvider>().user;
    if (user == null || !user.isAdmin) return;
    try {
      final preview = SpotCsv.parse(_input.text, user);
      setState(() {
        _preview = preview;
        _message = preview.spots.isEmpty
            ? 'ما فيه سجلات صالحة للاستيراد.'
            : null;
        _done = false;
      });
    } on FormatException catch (error) {
      setState(() {
        _preview = null;
        _message = error.message;
        _done = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final contents = await pickCsvFile();
      if (!mounted || contents == null) return;
      _input.text = contents;
      _parse();
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذّرت قراءة الملف.');
    }
  }

  Future<void> _save() async {
    final preview = _preview;
    final user = context.read<AuthProvider>().user;
    if (_saving ||
        _done ||
        preview == null ||
        user == null ||
        !user.isAdmin ||
        preview.spots.any((spot) => spot.submittedBy != user.id))
      return;
    final admin = context.read<AdminProvider>();
    setState(() {
      _saving = true;
      _message = null;
    });
    var saved = 0;
    var skipped = 0;
    var failed = false;
    try {
      final session = services.auth;
      if (services.backend is FirebaseRestBackendService &&
          (session is! FirebaseAuthRestService ||
              await session.currentIdToken() == null)) {
        if (mounted)
          setState(() {
            _saving = false;
            _message =
                'سجّلي الدخول من جديد بحساب أدمن Firebase قبل إرسال الأماكن.';
          });
        return;
      }
      for (final spot in preview.spots) {
        if (services.auth.currentUser?.id != user.id ||
            services.auth.currentUser?.isAdmin != true) {
          failed = true;
          break;
        }
        if (await services.backend.createSpotIfAbsent(spot)) {
          saved++;
        } else {
          skipped++;
        }
      }
    } catch (_) {
      failed = true;
    }
    await admin.load();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _done = !failed;
      _message =
          'تم إرسال $saved للمراجعة، وتخطّي $skipped موجودة سابقًا.'
          '${failed ? ' توقف الحفظ. أعيدي المحاولة لإكمال الباقي.' : ''}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.isAdmin == true;
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('استيراد أماكن من CSV')),
      body: !isAdmin
          ? const Center(child: Text('هذه الصفحة متاحة للأدمن فقط.'))
          : MaxWidthBox(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'احفظي تبويب «جمع الأماكن» بصيغة CSV UTF-8. استخدمي بيانات مسموح بإعادة نشرها.',
                  ),
                  const SizedBox(height: 12),
                  if (canPickCsvFile)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickFile,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('اختيار ملف CSV'),
                    ),
                  TextField(
                    controller: _input,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'أو الصقي نص CSV هنا',
                    ),
                    onChanged: (_) => setState(() {
                      _preview = null;
                      _message = null;
                      _done = false;
                    }),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _saving ? null : _parse,
                    child: const Text('معاينة السجلات'),
                  ),
                  if (preview != null) ...[
                    Text(
                      '${preview.spots.length} صالحة · ${preview.issues.length} تحتاج تعديل',
                    ),
                    for (final issue in preview.issues) Text(issue),
                    for (final spot in preview.spots.take(8))
                      ListTile(
                        dense: true,
                        title: Text(spot.name),
                        subtitle: Text(
                          '${spot.city} · ${spot.lat}, ${spot.lng}',
                        ),
                      ),
                    if (preview.spots.length > 8)
                      Text('و${preview.spots.length - 8} سجلات أخرى.'),
                    FilledButton(
                      onPressed: _saving || _done || preview.spots.isEmpty
                          ? null
                          : _save,
                      child: Text(
                        _saving
                            ? 'جارٍ الحفظ…'
                            : 'إرسال السجلات الصالحة للمراجعة',
                      ),
                    ),
                  ],
                  if (_message != null) Text(_message!),
                  if (_done)
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.adminPending),
                      child: const Text('فتح قائمة المراجعة'),
                    ),
                ],
              ),
            ),
    );
  }
}
