import 'package:flutter_test/flutter_test.dart';
import 'package:spot_wise/models/app_user.dart';
import 'package:spot_wise/models/enums.dart';
import 'package:spot_wise/services/backend/spot_csv.dart';

void main() {
  final admin = AppUser(
    id: 'admin',
    name: 'Admin',
    email: 'admin@example.test',
    role: UserRole.admin,
    createdAt: DateTime(2026),
  );
  const header =
      'اسم المكان أو الفرع,الوصف للزائر,المدينة,الدولة,الفئة الرئيسية,'
      'الفئة الفرعية,خط العرض,خط الطول,مسافة المسار (كم),مدة المسار (دقيقة)';
  const cafe =
      'مقهى تجريبي,"قهوة مختصة, وأماكن للجلوس",حائل,السعودية,'
      'المقاهي والمشروبات,قهوة مختصة,27.52,41.69,,';

  test(
    'reads the workbook title and headings, including quoted CSV and trail fields',
    () {
      final preview = SpotCsv.parse(
        '\uFEFFدلال | جمع بيانات الأماكن\r\n$header\r\n$cafe\r\n'
        'مسار تجريبي,مسار مشي تجريبي,حائل,السعودية,hiking,,27.53,41.69,2.5,45',
        admin,
      );
      expect(preview.issues, isEmpty);
      expect(preview.spots.first.description, 'قهوة مختصة, وأماكن للجلوس');
      expect(preview.spots.first.categoryId, 'specialty_coffee');
      expect(preview.spots.first.status, SpotStatus.pending);
      expect(preview.spots.last.trailDistanceKm, 2.5);
      expect(preview.spots.last.trailDurationMinutes, 45);
    },
  );

  test('flags duplicate and invalid rows, and uses the same id on retry', () {
    final preview = SpotCsv.parse(
      '$header\n$cafe\n$cafe\n${cafe.replaceFirst('27.52', 'NaN')}',
      admin,
    );
    expect(preview.spots, hasLength(1));
    expect(preview.issues, hasLength(2));
    expect(
      preview.spots.single.id,
      SpotCsv.parse('$header\n$cafe', admin).spots.single.id,
    );
  });
}
