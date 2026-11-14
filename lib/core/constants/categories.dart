import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SpotCategory {
  final String id;
  final String label;
  final String section;
  final IconData icon;
  final Color color;
  final String? parentId;

  const SpotCategory({
    required this.id,
    required this.label,
    required this.section,
    required this.icon,
    required this.color,
    this.parentId,
  });

  bool get isRoot => parentId == null;
}

class Categories {
  Categories._();

  static const _gold = Color(0xFFC49A45);
  static const _green = Color(0xFF4C7A5B);
  static const _blue = Color(0xFF3D668A);
  static const _rose = Color(0xFF9A4768);
  static const _red = Color(0xFF9B4B4B);
  static const _purple = AppColors.teal;
  static const _servicesSection = 'دليل الخدمات';

  static final List<({
    String id,
    String label,
    IconData icon,
    Color color,
    List<(String, String)> children,
  })> _serviceCatalog = [
    (
      id: 'restaurant', label: 'المطاعم', icon: Icons.restaurant_rounded,
      color: _gold,
      children: const [
        ('restaurant_arabic_food', 'أكل عربي'), ('restaurant_burger', 'برجر'),
        ('restaurant_shawarma', 'شاورما'), ('restaurant_grills', 'مشويات'),
        ('restaurant_broast', 'بروست'), ('restaurant_pizza', 'بيتزا'),
        ('restaurant_fast_food', 'وجبات سريعة'), ('restaurant_buffet', 'بوفيهات'),
        ('restaurant_breakfast', 'مطاعم فطور'), ('restaurant_seafood', 'مأكولات بحرية'),
        ('restaurant_fine_dining', 'مطاعم فاخرة'), ('restaurant_other', 'أخرى'),
      ],
    ),
    (
      id: 'cafes_drinks', label: 'المقاهي والمشروبات', icon: Icons.local_cafe_rounded,
      color: _rose,
      children: const [
        ('cafe', 'كافيهات'), ('specialty_coffee', 'قهوة مختصة'),
        ('juice_shop', 'محلات عصائر'), ('roastery_nuts', 'محامص ومكسرات'),
        ('tea_shop', 'محلات شاي'), ('cafe_sweets', 'محلات حلويات'),
        ('cafes_drinks_other', 'أخرى'),
      ],
    ),
    (
      id: 'grocery_markets', label: 'البقالات والأسواق الغذائية', icon: Icons.local_grocery_store_rounded,
      color: _green,
      children: const [
        ('grocery', 'بقالات'), ('supermarket', 'سوبرماركت'),
        ('fruit_vegetables', 'خضار وفواكه'), ('butcher', 'ملاحم'),
        ('dates_honey', 'تمور وعسل'), ('grocery_markets_other', 'أخرى'),
      ],
    ),
    (
      id: 'healthcare', label: 'العيادات والمستشفيات', icon: Icons.local_hospital_rounded,
      color: _red,
      children: const [
        ('hospital', 'مستشفيات'), ('clinic', 'مستوصفات'), ('dental', 'أسنان'),
        ('obgyn', 'نساء وولادة'), ('ophthalmology', 'عيون'),
        ('medical_cosmetic', 'تجميل طبي'), ('medical_lab', 'مختبرات طبية'),
        ('physiotherapy', 'علاج طبيعي'), ('therapeutic_massage', 'مساج علاجي'),
        ('speech_therapy', 'تخاطب'), ('psychiatry', 'طب نفسي'),
        ('healthcare_other', 'عيادات أخرى'),
      ],
    ),
    (
      id: 'cars', label: 'السيارات', icon: Icons.directions_car_rounded, color: _blue,
      children: const [
        ('car_maintenance', 'ورش صيانة'), ('car_accessories', 'زينة وإكسسوارات السيارات'),
        ('car_wash_detailing', 'غسيل وتلميع'), ('car_parts', 'قطع غيار'),
        ('car_rental', 'تأجير سيارات'), ('car_showroom', 'معارض سيارات'),
        ('gas_station', 'محطات وقود'), ('cars_other', 'أخرى'),
      ],
    ),
    (
      id: 'beauty_care', label: 'الجمال والعناية', icon: Icons.spa_rounded, color: _rose,
      children: const [
        ('women_salon', 'صالونات نسائية'), ('barber', 'حلاقون'),
        ('spa_care', 'سبا وعناية'), ('cosmetics', 'مستحضرات تجميل'),
        ('perfume_incense', 'عطور وبخور'), ('beauty_care_other', 'أخرى'),
      ],
    ),
    (id: 'bank', label: 'البنوك', icon: Icons.account_balance_rounded, color: _blue, children: const []),
    (
      id: 'shopping', label: 'التسوق والملابس', icon: Icons.shopping_bag_rounded,
      color: _purple,
      children: const [
        ('shopping_mall', 'مولات'), ('women_clothing', 'ملابس نسائية'),
        ('men_clothing', 'ملابس رجالية'), ('kids_clothing', 'ملابس أطفال'),
        ('shoes_bags', 'أحذية وحقائب'), ('mobile_electronics', 'جوالات وإلكترونيات'),
        ('furniture', 'أثاث ومفروشات'), ('toys_gifts', 'ألعاب وهدايا'),
        ('shopping_perfume_incense', 'عطور وبخور'), ('camping_supplies', 'لوازم تخييم'),
        ('electrical_tools', 'أدوات كهربائية'), ('discount_store', 'محلات أبو خمسة'),
        ('shopping_other', 'أخرى'),
      ],
    ),
    (
      id: 'accommodation', label: 'الإقامة', icon: Icons.hotel_rounded, color: _blue,
      children: const [('hotel', 'فنادق'), ('chalet', 'شاليهات'), ('caravan', 'كرفانات'), ('resort', 'منتجعات')],
    ),
    (
      id: 'public_services', label: 'الخدمات العامة', icon: Icons.home_repair_service_rounded,
      color: _purple,
      children: const [
        ('cleaning_pest_control', 'تنظيف ومكافحة حشرات'),
        ('hourly_workers', 'عاملات بالساعة'), ('student_services', 'خدمات الطلاب'),
        ('equipment_rental', 'تأجير معدات'), ('catering', 'تموين وضيافة «كيترنق»'),
        ('public_services_other', 'أخرى'),
      ],
    ),
    (
      id: 'sports', label: 'الأندية والرياضة', icon: Icons.sports_soccer_rounded, color: _green,
      children: const [('gym', 'صالات رياضية'), ('club', 'أندية'), ('sports_field', 'ملاعب'), ('sports_store', 'متاجر رياضية'), ('sports_other', 'أخرى')],
    ),
    (
      id: 'events_halls', label: 'قاعات الاحتفالات والمناسبات', icon: Icons.celebration_rounded,
      color: _rose,
      children: const [('wedding_hall', 'قاعات زواج'), ('event_planning', 'تجهيز وتنسيق حفلات'), ('events_halls_other', 'أخرى')],
    ),
    (
      id: 'contracting_maintenance', label: 'المقاولات والصيانة', icon: Icons.handyman_rounded,
      color: _gold,
      children: const [
        ('electricity_plumbing', 'كهرباء وسباكة'), ('contracting_building', 'مقاولات وبناء'),
        ('hvac', 'تكييف وتبريد'), ('painting', 'دهانات'), ('decor', 'ديكور'),
        ('maintenance_tools', 'أدوات صيانة'), ('building_materials', 'مواد بناء'),
        ('carpentry', 'نجارة'), ('contracting_other', 'أخرى'),
      ],
    ),
    (
      id: 'laundry_tailoring', label: 'المغاسل والخياطة', icon: Icons.iron_rounded, color: _blue,
      children: const [('laundry_ironing', 'مغاسل ملابس وكيّ'), ('men_tailoring', 'خياطة رجالية'), ('women_tailoring', 'خياطة نسائية'), ('laundry_tailoring_other', 'أخرى')],
    ),
    (
      id: 'bakery_sweets', label: 'المخابز والحلويات', icon: Icons.bakery_dining_rounded, color: _gold,
      children: const [('bakery', 'مخابز ومعجنات'), ('sweets', 'حلويات'), ('cake_shop', 'كيك'), ('ice_cream', 'آيس كريم'), ('bakery_sweets_other', 'أخرى')],
    ),
    (
      id: 'education_training', label: 'التعليم والتدريب', icon: Icons.school_rounded, color: _green,
      children: const [('nursery_kindergarten', 'روضات وحضانات'), ('private_school', 'مدارس أهلية'), ('training_institute', 'معاهد تدريب'), ('private_tutor', 'معلمون خصوصيون'), ('education_other', 'أخرى')],
    ),
    (
      id: 'farms_nurseries', label: 'المزارع والمشاتل', icon: Icons.agriculture_rounded, color: _green,
      children: const [('veterinary', 'خدمات بيطرية'), ('farmer', 'مزارع'), ('feed_livestock', 'أعلاف ومواشٍ'), ('plant_nursery', 'مشاتل ونباتات'), ('farms_other', 'أخرى')],
    ),
    (
      id: 'professional_services', label: 'المكاتب والخدمات المهنية', icon: Icons.business_center_rounded, color: _purple,
      children: const [('real_estate_office', 'مكاتب عقارية'), ('engineering_office', 'مكاتب هندسية'), ('law_office', 'محاماة'), ('accounting_office', 'محاسبة'), ('professional_services_other', 'أخرى')],
    ),
    (
      id: 'photography_printing', label: 'التصوير والطباعة', icon: Icons.photo_camera_rounded, color: _rose,
      children: const [('photo_studio', 'استوديوهات تصوير'), ('freelance_photographer', 'مصورون مستقلون'), ('flowers_gifts', 'ورد وهدايا'), ('printing_press', 'مطابع'), ('photography_printing_other', 'أخرى')],
    ),
    (
      id: 'transport_delivery', label: 'النقل والتوصيل', icon: Icons.local_shipping_rounded, color: _blue,
      children: const [('public_transport', 'نقل جماعي'), ('furniture_moving', 'نقل عفش'), ('shipping_delivery', 'شحن وتوصيل'), ('car_towing', 'سطحات نقل سيارات'), ('transport_delivery_other', 'أخرى')],
    ),
  ];

  static final List<SpotCategory> all = [
    for (final group in _serviceCatalog) ...[
      SpotCategory(
        id: group.id, label: group.label, section: _servicesSection,
        icon: group.icon, color: group.color,
      ),
      for (final child in group.children)
        SpotCategory(
          id: child.$1, label: child.$2, section: _servicesSection,
          icon: group.icon, color: group.color, parentId: group.id,
        ),
    ],
    const SpotCategory(id: 'hail_cooking', label: 'أسر منتجة', section: 'تجارب حائل', icon: Icons.storefront_rounded, color: _gold),
    const SpotCategory(id: 'popular_food', label: 'أكلات شعبية', section: 'تجارب حائل', icon: Icons.rice_bowl_rounded, color: _gold),
    const SpotCategory(id: 'crochet', label: 'ورش كروشيه', section: 'الورش والأنشطة', icon: Icons.handyman_rounded, color: _rose),
    const SpotCategory(id: 'cake', label: 'ورش تزيين الكيك', section: 'الورش والأنشطة', icon: Icons.cake_rounded, color: _rose),
    const SpotCategory(id: 'pottery_workshop', label: 'ورش الفخار', section: 'الورش والأنشطة', icon: Icons.local_fire_department_rounded, color: _rose),
    const SpotCategory(id: 'sadu_workshop', label: 'ورش السدو', section: 'الورش والأنشطة', icon: Icons.texture_rounded, color: _rose),
    const SpotCategory(id: 'calligraphy_workshop', label: 'ورش الخط العربي', section: 'الورش والأنشطة', icon: Icons.draw_rounded, color: _rose),
    const SpotCategory(id: 'perfume_workshop', label: 'ورش صناعة العطور', section: 'الورش والأنشطة', icon: Icons.spa_rounded, color: _rose),
    const SpotCategory(id: 'mountain_photography_workshop', label: 'ورش تصوير الجبال', section: 'الورش والأنشطة', icon: Icons.photo_camera_rounded, color: _rose),
    const SpotCategory(id: 'paragliding', label: 'طيران مظلي', section: 'الورش والأنشطة', icon: Icons.paragliding_rounded, color: _rose),
    const SpotCategory(id: 'heritage', label: 'معالم تراثية', section: 'الطبيعة والتراث', icon: Icons.account_balance_rounded, color: _green),
    const SpotCategory(id: 'story', label: 'قصص أثرية', section: 'الطبيعة والتراث', icon: Icons.auto_stories_rounded, color: _green),
    const SpotCategory(id: 'oasis', label: 'واحات', section: 'الطبيعة والتراث', icon: Icons.water_rounded, color: _green),
    const SpotCategory(id: 'park', label: 'حدائق', section: 'الطبيعة والتراث', icon: Icons.park_rounded, color: _green),
    const SpotCategory(id: 'camp', label: 'أماكن كشتة', section: 'الطبيعة والتراث', icon: Icons.terrain_rounded, color: _green),
    const SpotCategory(id: 'hiking', label: 'مسارات هايكنق', section: 'الطبيعة والتراث', icon: Icons.hiking_rounded, color: _green),
    const SpotCategory(id: 'pharmacy', label: 'صيدليات', section: 'الصحة', icon: Icons.local_pharmacy_rounded, color: _red),
  ];

  static List<String> get sections => roots.map((e) => e.section).toSet().toList();
  static List<SpotCategory> get roots => all.where((c) => c.isRoot).toList();
  static List<SpotCategory> rootsInSection(String section) =>
      all.where((c) => c.section == section && c.isRoot).toList();
  static List<SpotCategory> childrenOf(String parentId) =>
      all.where((c) => c.parentId == parentId).toList();
  static SpotCategory? parentOf(String id) {
    SpotCategory? category;
    for (final candidate in all) {
      if (candidate.id == id) {
        category = candidate;
        break;
      }
    }
    if (category?.parentId == null) return null;
    return byId(category!.parentId!);
  }

  static SpotCategory byId(String id) => all.firstWhere(
    (c) => c.id == id,
    orElse: () => const SpotCategory(
      id: 'other', label: 'أخرى', section: 'أخرى',
      icon: Icons.place_rounded, color: _purple,
    ),
  );
  static IconData iconFor(String id) => byId(id).icon;
  static Color colorFor(String id) => byId(id).color;
  static String labelFor(String id) => byId(id).label;
}
