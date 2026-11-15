import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/constants/categories.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/spot.dart';

typedef SpotCsvPreview = ({List<Spot> spots, List<String> issues});

/// Reads the Arabic headings from the Dalal collection workbook.
class SpotCsv {
  static const _required = [
    'اسم المكان أو الفرع',
    'الوصف للزائر',
    'المدينة',
    'الدولة',
    'الفئة الرئيسية',
    'خط العرض',
    'خط الطول',
  ];

  static SpotCsvPreview parse(String input, AppUser author) {
    if (input.length > 1000000) throw const FormatException('الملف كبير جدًا.');
    final rows = _readRows(input);
    final headerIndex = rows.indexWhere((row) => row.contains(_required.first));
    if (headerIndex < 0) {
      throw const FormatException(
        'أضيفي صف عناوين الأعمدة من تبويب جمع الأماكن.',
      );
    }
    final header = rows[headerIndex];
    final columns = {for (var i = 0; i < header.length; i++) header[i]: i};
    final missing = _required.where((name) => !columns.containsKey(name));
    if (missing.isNotEmpty) {
      throw FormatException('الأعمدة الناقصة: ${missing.join('، ')}');
    }
    final spots = <Spot>[];
    final issues = <String>[];
    final ids = <String>{};
    final today = DateTime.now();
    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((value) => value.isEmpty)) continue;
      String field(String key) {
        final index = columns[key];
        return index != null && index < row.length ? row[index] : '';
      }

      try {
        final name = field(_required[0]);
        final description = field(_required[1]);
        final city = Formatters.placeName(field('المدينة'));
        final country = Formatters.placeName(field('الدولة'));
        if (name.isEmpty ||
            description.length < 10 ||
            city.isEmpty ||
            country.isEmpty) {
          throw const FormatException(
            'يلزم الاسم والمدينة والدولة ووصف من 10 أحرف على الأقل.',
          );
        }
        final lat = double.tryParse(field('خط العرض'));
        final lng = double.tryParse(field('خط الطول'));
        if (lat == null ||
            lng == null ||
            !lat.isFinite ||
            !lng.isFinite ||
            lat.abs() > 90 ||
            lng.abs() > 180) {
          throw const FormatException(
            'أدخلي خط عرض وخط طول صالحين بالأرقام العشرية.',
          );
        }
        final root = _category(Categories.roots, field('الفئة الرئيسية'));
        final child = field('الفئة الفرعية');
        final category = child.isEmpty
            ? root
            : _category(Categories.childrenOf(root.id), child);
        final distanceText = field('مسافة المسار (كم)');
        final durationText = field('مدة المسار (دقيقة)');
        final distance = distanceText.isEmpty
            ? 0.0
            : double.tryParse(distanceText);
        final duration = durationText.isEmpty ? 0 : int.tryParse(durationText);
        if (distance == null ||
            !distance.isFinite ||
            distance < 0 ||
            duration == null ||
            duration < 0) {
          throw const FormatException('مسافة المسار أو مدته غير صالحة.');
        }
        final id =
            'csv-${const Uuid().v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8', jsonEncode([name.toLowerCase(), city.toLowerCase(), country.toLowerCase(), lat.toStringAsFixed(6), lng.toStringAsFixed(6)]))}';
        if (!ids.add(id)) throw const FormatException('مكرر داخل الملف.');
        final price = switch (field('فئة السعر')) {
          'مجاني' => PriceRange.free,
          'اقتصادي' => PriceRange.budget,
          'مرتفع' => PriceRange.premium,
          _ => PriceRange.moderate,
        };
        final free = field('دخول مجاني؟') == 'نعم' || price == PriceRange.free;
        spots.add(
          Spot(
            id: id,
            name: name,
            description: description,
            city: city,
            country: country,
            categoryId: category.id,
            lat: lat,
            lng: lng,
            priceRange: free ? PriceRange.free : price,
            isFree: free,
            familyFriendly: field('مناسب للعائلات؟') == 'نعم',
            hiddenGem: field('جوهرة مخفية؟') == 'نعم',
            address: field('العنوان'),
            locationNote: field('وصف الوصول'),
            openingHours: field('ساعات العمل أو الزيارة'),
            phone: field('رقم التواصل'),
            whatsappUrl: field('رابط واتساب الرسمي'),
            bestTimeToVisit: field('أفضل وقت للزيارة'),
            bookingInfo: field('طريقة الحجز أو الطلب'),
            eventDate: field('موعد الورشة أو النشاط'),
            products: field('المنتجات'),
            seasons: field('المواسم'),
            priceInfo: field('السعر الفعلي أو رسوم الدخول'),
            trailDistanceKm: distance,
            trailDurationMinutes: duration,
            tags: field('وسوم')
                .split(RegExp('[,،]'))
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(),
            submittedBy: author.id,
            submittedByName: author.name,
            createdAt: today,
          ),
        );
      } on FormatException catch (error) {
        issues.add('السجل ${i + 1}: ${error.message}');
      }
    }
    return (spots: spots, issues: issues);
  }

  static SpotCategory _category(Iterable<SpotCategory> options, String value) {
    for (final option in options) {
      if (option.id == value || option.label == value) return option;
    }
    throw FormatException(
      value.isEmpty ? 'اختاري الفئة الرئيسية.' : 'فئة غير معروفة: $value',
    );
  }

  static List<List<String>> _readRows(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var value = StringBuffer();
    var quoted = false;
    var closedQuote = false;
    final clean = input.replaceFirst('\uFEFF', '');
    final delimiter =
        clean.contains('\t') &&
            clean
                .split(RegExp(r'[\r\n]'))
                .any((line) => line.startsWith('${_required.first}\t'))
        ? '\t'
        : ',';
    for (var i = 0; i < clean.length; i++) {
      final char = clean[i];
      if (quoted) {
        if (char != '"') {
          value.write(char);
        } else if (i + 1 < clean.length && clean[i + 1] == '"') {
          value.write('"');
          i++;
        } else {
          quoted = false;
          closedQuote = true;
        }
      } else if (char == delimiter || char == '\r' || char == '\n') {
        row.add(value.toString().trim());
        value = StringBuffer();
        closedQuote = false;
        if (char != delimiter) {
          if (char == '\r' && i + 1 < clean.length && clean[i + 1] == '\n') i++;
          rows.add(row);
          row = [];
        }
      } else if (char == '"' && value.isEmpty && !closedQuote) {
        quoted = true;
      } else if (closedQuote || char == '"') {
        throw const FormatException('تنسيق علامات الاقتباس في الملف غير صالح.');
      } else {
        value.write(char);
      }
    }
    if (quoted)
      throw const FormatException('يوجد حقل بعلامة اقتباس غير مغلقة.');
    row.add(value.toString().trim());
    rows.add(row);
    return rows;
  }
}
