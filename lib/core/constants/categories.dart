import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SpotCategory {
  final String id;
  final String label;
  final String section;
  final IconData icon;
  final Color color;

  const SpotCategory({
    required this.id,
    required this.label,
    required this.section,
    required this.icon,
    required this.color,
  });
}

class Categories {
  Categories._();

  static const _purple = AppColors.teal;
  static const _gold = Color(0xFFC49A45);
  static const _green = Color(0xFF4C7A5B);
  static const _blue = Color(0xFF3D668A);
  static const _rose = Color(0xFF9A4768);
  static const _red = Color(0xFF9B4B4B);

  static const List<SpotCategory> all = [
    SpotCategory(id: 'hail_cooking', label: 'أسر منتجة', section: 'الطعام والضيافة', icon: Icons.storefront_rounded, color: _gold),
    SpotCategory(id: 'popular_food', label: 'أكلات شعبية', section: 'الطعام والضيافة', icon: Icons.rice_bowl_rounded, color: _gold),
    SpotCategory(id: 'restaurant', label: 'مطاعم', section: 'الطعام والضيافة', icon: Icons.restaurant_rounded, color: _gold),
    SpotCategory(id: 'cafe', label: 'مقاهٍ', section: 'الطعام والضيافة', icon: Icons.local_cafe_rounded, color: _gold),
    SpotCategory(id: 'bakery', label: 'مخابز', section: 'الطعام والضيافة', icon: Icons.bakery_dining_rounded, color: _gold),
    SpotCategory(id: 'crochet', label: 'ورش كروشيه', section: 'الورش والأنشطة', icon: Icons.handyman_rounded, color: _rose),
    SpotCategory(id: 'cake', label: 'ورش تزيين الكيك', section: 'الورش والأنشطة', icon: Icons.cake_rounded, color: _rose),
    SpotCategory(id: 'pottery_workshop', label: 'ورش الفخار', section: 'الورش والأنشطة', icon: Icons.local_fire_department_rounded, color: _rose),
    SpotCategory(id: 'sadu_workshop', label: 'ورش السدو', section: 'الورش والأنشطة', icon: Icons.texture_rounded, color: _rose),
    SpotCategory(id: 'club', label: 'نوادٍ', section: 'الورش والأنشطة', icon: Icons.groups_rounded, color: _rose),
    SpotCategory(id: 'paragliding', label: 'طيران مظلي', section: 'الورش والأنشطة', icon: Icons.paragliding_rounded, color: _rose),
    SpotCategory(id: 'heritage', label: 'معالم تراثية', section: 'الطبيعة والتراث', icon: Icons.account_balance_rounded, color: _green),
    SpotCategory(id: 'story', label: 'قصص أثرية', section: 'الطبيعة والتراث', icon: Icons.auto_stories_rounded, color: _green),
    SpotCategory(id: 'oasis', label: 'واحات', section: 'الطبيعة والتراث', icon: Icons.water_rounded, color: _green),
    SpotCategory(id: 'park', label: 'حدائق', section: 'الطبيعة والتراث', icon: Icons.park_rounded, color: _green),
    SpotCategory(id: 'camp', label: 'أماكن كشتة', section: 'الطبيعة والتراث', icon: Icons.terrain_rounded, color: _green),
    SpotCategory(id: 'hiking', label: 'مسارات هيكنق', section: 'الطبيعة والتراث', icon: Icons.hiking_rounded, color: _green),
    SpotCategory(id: 'hotel', label: 'فنادق', section: 'الإقامة', icon: Icons.hotel_rounded, color: _blue),
    SpotCategory(id: 'chalet', label: 'شاليهات', section: 'الإقامة', icon: Icons.villa_rounded, color: _blue),
    SpotCategory(id: 'caravan', label: 'كرفانات', section: 'الإقامة', icon: Icons.airport_shuttle_rounded, color: _blue),
    SpotCategory(id: 'shopping', label: 'أماكن تسوق', section: 'التسوق والمنتجات المحلية', icon: Icons.shopping_bag_rounded, color: _purple),
    SpotCategory(id: 'farmer', label: 'المزارعون والمنتجات الزراعية', section: 'التسوق والمنتجات المحلية', icon: Icons.agriculture_rounded, color: _purple),
    SpotCategory(id: 'pharmacy', label: 'صيدليات', section: 'الصحة', icon: Icons.local_pharmacy_rounded, color: _red),
    SpotCategory(id: 'hospital', label: 'مستشفيات', section: 'الصحة', icon: Icons.local_hospital_rounded, color: _red),
  ];

  static List<String> get sections => all.map((e) => e.section).toSet().toList();
  static List<SpotCategory> inSection(String section) => all.where((e) => e.section == section).toList();
  static SpotCategory byId(String id) => all.firstWhere((c) => c.id == id, orElse: () => all.first);
  static IconData iconFor(String id) => byId(id).icon;
  static Color colorFor(String id) => byId(id).color;
  static String labelFor(String id) => byId(id).label;
}
