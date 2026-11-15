import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/app_routes.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/utils/country_flags.dart';
import '../../models/spot.dart';
import '../../models/spot_filter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_store.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_menu_button.dart';
import '../../widgets/destination_picker_sheet.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/max_width.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/spot_card.dart';
import '../../widgets/spot_search_sheet.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
import '../map/filter_sheet.dart';
import '../shell/home_shell.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  static const Distance _distance = Distance();

  SpotFilter _filter = const SpotFilter();
  LatLng? _origin;
  String? _placeLabel;

  Future<void> _pickLocation() async {
    final picked = await pickLocation(context);
    if (picked != null && mounted) {
      setState(() {
        _origin = picked.$1;
        _placeLabel = picked.$2;
        // "Near a place" and a destination would fight each other (Near Paris
        // + Germany = no results) — the newer choice wins.
        _filter = _filter.copyWith(country: '', city: '');
      });
    }
  }

  void _clearLocation() => setState(() {
    _origin = null;
    _placeLabel = null;
  });

  double _distM(Spot s) => _distance.as(LengthUnit.Meter, _origin!, s.latLng);

  Future<void> _openFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        initial: _filter,
        onApply: (f) => setState(() => _filter = f),
      ),
    );
  }

  /// Opens the country → city cascade (with free-text search). [cityFirst]
  /// jumps straight to the cities of the already-chosen country.
  Future<void> _pickDestination({bool cityFirst = false}) async {
    final spotsP = context.read<SpotsProvider>();
    final picked = await showDestinationPicker(
      context,
      countries: spotsP.countryCounts,
      citiesFor: spotsP.cityCountsFor,
      spots: spotsP.spots,
      country: _filter.country,
      city: _filter.city,
      startOnCities: cityFirst,
    );
    if (picked == null || !mounted) return;
    if (picked.spot != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.spotDetails,
        arguments: picked.spot,
      );
      return;
    }
    setState(() {
      _filter = _filter.copyWith(country: picked.country, city: picked.city);
      // A destination and "near a place" would fight each other (Near Paris
      // + Germany = no results) — the newer choice wins.
      if (picked.country.isNotEmpty) {
        _origin = null;
        _placeLabel = null;
      }
    });
  }

  Future<void> _toggleSave(Spot spot) async {
    if (await ensureLoggedIn(context) && mounted) {
      context.read<AuthProvider>().toggleSave(spot.id);
    }
  }

  /// Human label for the active destination — the city when one is chosen,
  /// else the country.
  String get _destinationPlace =>
      _filter.city.isNotEmpty ? _filter.city : _filter.country;

  /// Quick name search over the catalog — picking a suggestion opens the spot.
  Future<void> _openSpotSearch() async {
    final spot = await showSpotSearch(
      context,
      spots: context.read<SpotsProvider>().spots,
    );
    if (spot != null && mounted) {
      Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot);
    }
  }

  HomeTab? _homeTab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = context.read<HomeTab>();
    if (identical(tab, _homeTab)) return;
    _homeTab?.removeListener(_applyCategory);
    _homeTab = tab;
    tab.addListener(_applyCategory);
  }

  void _applyCategory() {
    final category = _homeTab?.takeCategory();
    if (category == null) return;
    setState(() => _filter = _filter.copyWith(categoryIds: {category}));
  }

  @override
  void dispose() {
    _homeTab?.removeListener(_applyCategory);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final spotsP = context.watch<SpotsProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        titleSpacing: 0,
        title: const AppLogo(size: 44),
        actions: [
          if (auth.role.canModerate)
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Admin',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search spots',
            onPressed: _openSpotSearch,
          ),
          Center(
            child: Tooltip(
              message: auth.user != null ? 'Profile' : 'Sign in',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    auth.user != null ? AppRoutes.profile : AppRoutes.login,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: UserAvatar(
                      photoUrl: auth.user?.photoUrl,
                      initials: auth.user?.initials ?? '?',
                      radius: 17,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => spotsP.load(force: true),
        child: MaxWidthBox(child: _buildBody(context, spotsP, auth)),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SpotsProvider spotsP,
    AuthProvider auth,
  ) {
    if (spotsP.loading && spotsP.isEmpty) return const SpotFeedSkeleton();
    if (spotsP.error != null && spotsP.isEmpty) {
      return ErrorView(
        message: spotsP.error!,
        onRetry: () => spotsP.load(force: true),
      );
    }

    final hasLocation = _origin != null;
    final filtering = _filter.isActive;
    final activeMode = hasLocation || filtering;

    var results = spotsP.spots.where((s) => _filter.matches(s)).toList();
    if (hasLocation) {
      results.sort((a, b) => _distM(a).compareTo(_distM(b)));
    } else if (filtering) {
      // Curated feel: best-rated matches first when browsing a destination
      // or category.
      results.sort((a, b) => b.rating.compareTo(a.rating));
    }
    final featured = spotsP.featured;

    return ListView(
      // Clear the floating dock (its height is injected into the bottom
      // MediaQuery padding by the shell's extendBody).
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      children: [
        const OfflineBanner(),
        const _GreetingHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _DestinationButton(
                  country: _filter.country,
                  city: _filter.city,
                  onPickCountry: () => _pickDestination(),
                  onPickCity: () =>
                      _pickDestination(cityFirst: _filter.country.isNotEmpty),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CircleButton(
                icon: Icons.near_me_rounded,
                tooltip: 'Search near a place',
                onTap: _pickLocation,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CircleButton(
                icon: Icons.tune_rounded,
                count: _filter.activeCount,
                tooltip: 'Filters',
                onTap: _openFilters,
              ),
            ],
          ),
        ),

        if (!activeMode && featured.isNotEmpty) ...[
          const SectionHeader(
            title: 'Featured',
            subtitle: 'Hand-picked by the SpotWise team',
          ),
          _rail(context, featured, auth),
        ],
        _HomeCategoryRail(
          spots: spotsP.spots,
          selected: _filter.categoryIds,
          onSelect: (ids) =>
              setState(() => _filter = _filter.copyWith(categoryIds: ids)),
          onBrowseAll: () => context.read<HomeTab>().go(2),
        ),
        if (activeMode)
          _ActiveFilterBar(
            count: results.length,
            filter: _filter,
            placeLabel: _placeLabel,
            onFilter: (f) => setState(() => _filter = f),
            onClearFilters: () => setState(() => _filter = const SpotFilter()),
            onClearLocation: _clearLocation,
          ),
        if (activeMode) ...[
          if (_filter.country.isNotEmpty) ...[
            if (results.any((s) => s.featured)) ...[
              SectionHeader(
                title: 'Featured in $_destinationPlace',
                subtitle: 'Hand-picked by the SpotWise team',
              ),
              _rail(context, results.where((s) => s.featured).toList(), auth),
            ],
          ],
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: EmptyView(
                icon: Icons.filter_alt_off_rounded,
                title: 'No matches',
                message:
                    'Try another category, a wider area, or clear your filters.',
              ),
            )
          else
            ...results.map(
              (spot) => _spotCard(
                context,
                spot,
                auth,
                distance: hasLocation ? _distM(spot) : null,
              ),
            ),
        ] else ...[
          SectionHeader(
            title: 'Explore spots',
            subtitle: '${spotsP.spots.length} community-approved places',
          ),
          if (spotsP.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: EmptyView(
                icon: Icons.travel_explore_rounded,
                title: 'No spots yet',
                message: 'Approved community spots will appear here.',
              ),
            )
          else
            ...results.map((spot) => _spotCard(context, spot, auth)),
        ],
      ],
    );
  }

  Widget _spotCard(
    BuildContext context,
    Spot spot,
    AuthProvider auth, {
    double? distance,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: SpotCard(
      spot: spot,
      isSaved: auth.isSaved(spot.id),
      onToggleSave: () => _toggleSave(spot),
      distanceMeters: distance,
      heroTag: 'spot-hero-${spot.id}',
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot),
    ),
  );

  /// Horizontal rail of editorial overlay cards (Featured / Recommended).
  Widget _rail(BuildContext context, List<Spot> spots, AuthProvider auth) {
    return _HorizontalCardRail(
      itemCount: spots.length,
      itemBuilder: (_, i) {
        final spot = spots[i];
        return SpotOverlayCard(
          spot: spot,
          isSaved: auth.isSaved(spot.id),
          onToggleSave: () => _toggleSave(spot),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.spotDetails,
            arguments: spot,
          ),
        );
      },
    );
  }
}

class _HorizontalCardRail extends StatelessWidget {
  const _HorizontalCardRail({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 194,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) =>
            SizedBox(width: 238, child: itemBuilder(context, index)),
      ),
    );
  }
}

class _HomeCategoryRail extends StatelessWidget {
  const _HomeCategoryRail({
    required this.spots,
    required this.selected,
    required this.onSelect,
    required this.onBrowseAll,
  });

  final List<Spot> spots;
  final Set<String> selected;
  final ValueChanged<Set<String>> onSelect;
  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CategoryStore>();
    final entries = [
      (label: 'المطاعم', icon: Icons.restaurant_rounded, ids: const {'restaurant'}),
      (label: 'المقاهي', icon: Icons.local_cafe_rounded, ids: const {'cafes_drinks'}),
      (
        label: 'الطبيعة والتراث',
        icon: Icons.terrain_rounded,
        ids: Categories.rootsInSection('الطبيعة والتراث').map((c) => c.id).toSet(),
      ),
      (label: 'الإقامة', icon: Icons.hotel_rounded, ids: const {'accommodation'}),
      (
        label: 'الورش والأنشطة',
        icon: Icons.palette_outlined,
        ids: Categories.rootsInSection('الورش والأنشطة').map((c) => c.id).toSet(),
      ),
      (label: 'التسوق', icon: Icons.shopping_bag_rounded, ids: const {'shopping'}),
    ]
        .map((entry) => (
              label: entry.label,
              icon: entry.icon,
              ids: entry.ids.where(store.isEnabled).toSet(),
            ))
        .where((entry) => entry.ids.isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'فئات دليل حائل',
          actionLabel: 'عرض الكل',
          onAction: onBrowseAll,
        ),
        _HorizontalCardRail(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final filter = SpotFilter(categoryIds: entry.ids);
            String? photo;
            for (final spot in spots) {
              final cover = spot.coverPhoto;
              if (cover != null &&
                  cover.isNotEmpty &&
                  store.isEnabled(spot.categoryId) &&
                  filter.matches(spot)) {
                photo = cover;
                if (spot.featured) break;
              }
            }
            final isSelected =
                selected.length == entry.ids.length && selected.containsAll(entry.ids);
            return Semantics(
              button: true,
              selected: isSelected,
              child: Card(
                child: InkWell(
                  onTap: () => onSelect(isSelected ? const {} : entry.ids),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photo != null) NetworkPhoto(photo, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: photo == null
                              ? AppColors.lagoonGradient
                              : AppColors.cardScrim,
                        ),
                      ),
                      PositionedDirectional(
                        top: AppSpacing.md,
                        start: AppSpacing.md,
                        child: CircleAvatar(
                          backgroundColor: AppColors.tealDark,
                          foregroundColor: AppColors.coralMist,
                          child: Icon(isSelected ? Icons.check_rounded : entry.icon),
                        ),
                      ),
                      PositionedDirectional(
                        start: AppSpacing.lg,
                        end: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.chevron_left_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Editorial greeting block: time-of-day greeting + date, a headline that
/// rotates daily, and a live stat line — replaces the old static app-bar
/// "Hello, there" title.
class _GreetingHeader extends StatefulWidget {
  const _GreetingHeader();

  @override
  State<_GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<_GreetingHeader> {
  late final Future<String?> _weather = _loadWeather();
  static final _date = intl.DateFormat('EEEE، d MMMM', 'ar');
  static final _number = intl.NumberFormat.decimalPattern('ar');

  Future<String?> _loadWeather() async {
    try {
      final response = await http
          .get(
            Uri.https('api.open-meteo.com', '/v1/forecast', {
              'latitude': '27.52',
              'longitude': '41.69',
              'current': 'temperature_2m,weather_code',
              'daily': 'temperature_2m_max,temperature_2m_min',
              'timezone': 'Asia/Riyadh',
              'forecast_days': '1',
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;
      final temperature = (current['temperature_2m'] as num).round();
      final code = current['weather_code'] as int;
      final high = ((daily['temperature_2m_max'] as List).first as num).round();
      final low = ((daily['temperature_2m_min'] as List).first as num).round();
      final condition = switch (code) {
        0 => 'صحو',
        1 || 2 => 'غائم جزئيًا',
        3 => 'غائم',
        45 || 48 => 'ضباب',
        51 || 53 || 55 || 56 || 57 => 'رذاذ',
        61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => 'أمطار',
        71 || 73 || 75 || 77 || 85 || 86 => 'ثلوج',
        95 || 96 || 99 => 'عواصف رعدية',
        _ => 'الحالة غير متاحة',
      };
      return '$condition · ${_number.format(temperature)}°م  |  العظمى ${_number.format(high)}°م · الصغرى ${_number.format(low)}°م';
    } catch (_) {
      return null;
    }
  }

  Future<void> _showWeatherSource(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.cloud_outlined),
      title: const Text('معلومات الطقس'),
      content: const Text(
        'بيانات الطقس مقدمة من Open‑Meteo وفق ترخيص CC BY 4.0.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => launchUrl(
            Uri.parse('https://open-meteo.com/'),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: const Text('Open‑Meteo'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Saudi Arabia uses UTC+3 year-round.
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final hijri = HijriCalendar.fromDate(now);
    final hijriDate =
        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';
    final greeting = now.hour >= 5 && now.hour < 12
        ? 'صباح الخير'
        : 'مساء الخير';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          gradient: AppColors.lagoonGradient,
          borderRadius: AppRadius.brXl,
          boxShadow: AppColors.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    '$greeting · ${_date.format(now)}\n$hijriDate',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.coralMist,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اكتشف حائل',
                    style: text.displaySmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'اختر ما يناسبك من دليل المدينة',
                    style: text.bodyMedium?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'طقس حائل اليوم',
                        style: text.titleSmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: () => _showWeatherSource(context),
                        tooltip: 'معلومات مصدر الطقس',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.info_outline_rounded,
                          size: 17,
                          color: AppColors.coralMist,
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder<String?>(
                    future: _weather,
                    builder: (context, snapshot) {
                      final forecast = snapshot.data;
                      return Text(
                        forecast ??
                            (snapshot.connectionState == ConnectionState.done
                                ? 'تعذّر جلب الطقس الآن'
                                : 'جارٍ تحميل الطقس…'),
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.cream,
                        ),
                      );
                    },
                  ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Image.asset(
                      'assets/jubbah-thamudic-inscription.png',
                      fit: BoxFit.contain,
                      opacity: const AlwaysStoppedAnimation<double>(.72),
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ink-filled call-to-action shown while browsing a destination: hands the
/// place to the AI planner and switches to the Plan tab.

/// `Near <place>` location, which lives outside [SpotFilter]).
class _ActiveFilterBar extends StatelessWidget {
  final int count;
  final SpotFilter filter;
  final String? placeLabel;
  final ValueChanged<SpotFilter> onFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onClearLocation;

  const _ActiveFilterBar({
    required this.count,
    required this.filter,
    required this.placeLabel,
    required this.onFilter,
    required this.onClearFilters,
    required this.onClearLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$count ${count == 1 ? 'result' : 'results'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (filter.isActive)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (placeLabel != null)
                _FilterPill(
                  icon: Icons.near_me_rounded,
                  label: 'Near $placeLabel',
                  onRemove: onClearLocation,
                ),
              if (filter.country.isNotEmpty)
                _FilterPill(
                  emoji: countryFlag(filter.country),
                  label: filter.country,
                  // Removing the country also drops its city.
                  onRemove: () =>
                      onFilter(filter.copyWith(country: '', city: '')),
                ),
              if (filter.city.isNotEmpty)
                _FilterPill(
                  icon: Icons.location_city_rounded,
                  label: filter.city,
                  onRemove: () => onFilter(filter.copyWith(city: '')),
                ),
              if (filter.minRating > 0)
                _FilterPill(
                  label: '★ ${filter.minRating.toStringAsFixed(0)}+',
                  onRemove: () => onFilter(filter.copyWith(minRating: 0)),
                ),
              for (final p in filter.priceRanges)
                _FilterPill(
                  label: p.label,
                  onRemove: () => onFilter(
                    filter.copyWith(
                      priceRanges: {...filter.priceRanges}..remove(p),
                    ),
                  ),
                ),
              if (filter.freeOnly)
                _FilterPill(
                  label: 'Free entry',
                  onRemove: () => onFilter(filter.copyWith(freeOnly: false)),
                ),
              if (filter.familyOnly)
                _FilterPill(
                  label: 'Family',
                  onRemove: () => onFilter(filter.copyWith(familyOnly: false)),
                ),
              if (filter.hiddenGemOnly)
                _FilterPill(
                  label: 'Hidden gems',
                  onRemove: () =>
                      onFilter(filter.copyWith(hiddenGemOnly: false)),
                ),
              if (filter.maxDistanceKm != null)
                _FilterPill(
                  label: '≤ ${filter.maxDistanceKm!.round()} km',
                  onRemove: () =>
                      onFilter(filter.copyWith(clearDistance: true)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A removable stadium pill for one active filter. The whole pill is the
/// (≥44px) tap target that removes it.
class _FilterPill extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final VoidCallback onRemove;

  const _FilterPill({
    this.icon,
    this.emoji,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRemove,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.xs),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.close_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Split destination pill — the home page's "search". The left half picks the
/// country, the right half drills into a city of that country.
class _DestinationButton extends StatelessWidget {
  final String country;
  final String city;
  final VoidCallback onPickCountry;
  final VoidCallback onPickCity;

  const _DestinationButton({
    required this.country,
    required this.city,
    required this.onPickCountry,
    required this.onPickCity,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(AppRadius.pill));

    final hasCountry = country.isNotEmpty;
    final cityLabel = !hasCountry
        ? 'City'
        : city.isEmpty
        ? 'All cities'
        : city;

    Widget half({
      String? leading,
      required String label,
      required bool selected,
      required bool enabled,
      required VoidCallback onTap,
      required String semantics,
      int flex = 1,
    }) {
      final labelStyle = selected
          ? text.titleSmall
          : text.bodyMedium?.copyWith(
              color: enabled ? null : scheme.onSurfaceVariant,
            );
      return Expanded(
        flex: flex,
        child: Semantics(
          button: true,
          label: semantics,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + AppSpacing.xxs,
                vertical: 15,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    Text(leading, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: labelStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            half(
              leading: hasCountry ? countryFlag(country) : '🌍',
              label: hasCountry ? country : 'Country',
              selected: hasCountry,
              enabled: true,
              onTap: onPickCountry,
              semantics: 'Choose country',
              flex: 6,
            ),
            Container(
              width: 1,
              height: 26,
              color: scheme.outline.withValues(alpha: 0.6),
            ),
            half(
              label: cityLabel,
              selected: city.isNotEmpty,
              enabled: hasCountry,
              onTap: onPickCity,
              semantics: 'Choose city',
              flex: 5,
            ),
          ],
        ),
      ),
    );
  }
}

/// An ink-circle action button beside the destination pill (optionally badged
/// with an active count) — used for the nearby and filter actions.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String? tooltip;
  final VoidCallback onTap;
  const _CircleButton({
    required this.icon,
    this.count = 0,
    this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: scheme.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: Icon(icon, color: scheme.onPrimary, size: 22),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class LegacyDalalCategoriesScreen extends StatelessWidget {
  const LegacyDalalCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: const Text('فئات دليل حائل'),
      ),
      body: MaxWidthBox(
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
          ),
          children: [
            _LegacyDalalCategorySections(
              selected: const {},
              onToggle: context.read<HomeTab>().browseCategory,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyDalalCategorySections extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _LegacyDalalCategorySections({
    required this.selected,
    required this.onToggle,
  });

  Future<void> _selectCategory(
    BuildContext context,
    SpotCategory category,
    CategoryStore store,
  ) async {
    final children = Categories.childrenOf(
      category.id,
    ).where((child) => store.isEnabled(child.id)).toList();
    if (children.isEmpty) {
      onToggle(category.id);
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              category.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: Icon(category.icon, color: category.color),
            title: Text('كل ${category.label}'),
            subtitle: const Text('عرض جميع الفئات الفرعية'),
            onTap: () => Navigator.pop(context, category.id),
          ),
          const Divider(),
          for (final child in children)
            ListTile(
              leading: Icon(child.icon, color: child.color),
              title: Text(child.label),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => Navigator.pop(context, child.id),
            ),
        ],
      ),
    );
    if (choice != null) onToggle(choice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<CategoryStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        for (final section in Categories.sections) ...[
          Padding(
            padding: AppSpacing.screenPadding,
            child: Text(
              section,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screenPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in Categories.rootsInSection(section)
                    .where((category) => store.isEnabled(category.id))
                    .toList()
                    .asMap()
                    .entries)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: _CategoryTile(
                      category: entry.value,
                      index: entry.key,
                      selected: selected.contains(entry.value.id),
                      hasChildren: Categories.childrenOf(
                        entry.value.id,
                      ).any((child) => store.isEnabled(child.id)),
                      onTap: () => _selectCategory(
                        context,
                        entry.value,
                        store,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final SpotCategory category;
  final int index;
  final bool selected;
  final bool hasChildren;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.index,
    required this.selected,
    this.hasChildren = false,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = widget.category;
    final selected = widget.selected;
    final fill = selected
        ? scheme.primary
        : theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHighest
        : Color.alphaBlend(
            category.color.withValues(alpha: 0.09),
            Colors.white,
          );

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.18, .08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic)),
        child: AnimatedScale(
          scale: _pressed ? .96 : 1,
          duration: const Duration(milliseconds: 130),
          child: Semantics(
            button: true,
            selected: selected,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 112,
              height: 116,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [AppColors.tealDark, AppColors.coral],
                      )
                    : null,
                color: selected ? null : fill,
                borderRadius: AppRadius.brXl,
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: .22)
                      : category.color.withValues(alpha: .18),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: .24),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : AppColors.softShadow,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppRadius.brXl,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                  onHighlightChanged: (value) => setState(() => _pressed = value),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: .18)
                                    : category.color.withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                category.icon,
                                color: selected ? Colors.white : category.color,
                                size: 25,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              category.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: selected ? Colors.white : scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        top: 7,
                        end: 7,
                        child: AnimatedScale(
                          scale: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutBack,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: AppColors.tealDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.hasChildren)
                        PositionedDirectional(
                          top: 9,
                          start: 9,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: selected
                                ? Colors.white
                                : AppColors.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DalalCategoriesScreen extends StatelessWidget {
  const DalalCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: const Text('فئات دليل حائل'),
      ),
      body: MaxWidthBox(
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
          ),
          children: [
            _DalalCategorySections(
              onBrowse: context.read<HomeTab>().browseCategory,
            ),
          ],
        ),
      ),
    );
  }
}

class _DalalCategorySections extends StatefulWidget {
  const _DalalCategorySections({required this.onBrowse});

  final ValueChanged<String> onBrowse;

  @override
  State<_DalalCategorySections> createState() =>
      _DalalCategorySectionsState();
}

class _DalalCategorySectionsState extends State<_DalalCategorySections> {
  static const _nature = 'الطبيعة والتراث';
  static const _services = 'دليل الخدمات';
  static const _experiences = 'تجارب حائل';
  static const _workshops = 'الورش والأنشطة';

  String? _selectedSection;

  Future<void> _selectCategory(
    BuildContext context,
    SpotCategory category,
    CategoryStore store,
  ) async {
    final children = Categories.childrenOf(
      category.id,
    ).where((child) => store.isEnabled(child.id)).toList();

    if (children.isEmpty) {
      widget.onBrowse(category.id);
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              category.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: Icon(category.icon, color: category.color),
            title: Text('كل ${category.label}'),
            subtitle: const Text('عرض جميع الفئات الفرعية'),
            onTap: () => Navigator.pop(context, category.id),
          ),
          const Divider(),
          for (final child in children)
            ListTile(
              leading: Icon(child.icon, color: child.color),
              title: Text(child.label),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => Navigator.pop(context, child.id),
            ),
        ],
      ),
    );

    if (mounted && choice != null) widget.onBrowse(choice);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CategoryStore>();
    final theme = Theme.of(context);
    final sections = <String, List<SpotCategory>>{};

    for (final section in Categories.sections) {
      final entries = Categories.rootsInSection(
        section,
      ).where((category) => store.isEnabled(category.id)).toList();
      if (entries.isNotEmpty) sections[section] = entries;
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    final selectedSection = sections.containsKey(_selectedSection)
        ? _selectedSection!
        : sections.containsKey(_nature)
        ? _nature
        : sections.keys.first;

    Widget tile(
      String section,
      IconData icon,
      Color lightFill,
      Color darkFill,
      Color lightInk,
      Color darkInk,
    ) {
      final isDark = theme.brightness == Brightness.dark;
      return _CategorySectionTile(
        label: section,
        icon: icon,
        fill: isDark ? darkFill : lightFill,
        ink: isDark ? darkInk : lightInk,
        selected: section == selectedSection,
        featured: section == _nature,
        onTap: () => setState(() => _selectedSection = section),
      );
    }

    final nature = sections.containsKey(_nature)
        ? tile(
            _nature,
            Icons.terrain_rounded,
            const Color(0xFF254B40),
            const Color(0xFF203C34),
            const Color(0xFFFFF8E8),
            const Color(0xFFFFF8E8),
          )
        : null;

    final quickLinks = [
      if (sections.containsKey(_services))
        tile(
          _services,
          Icons.storefront_outlined,
          const Color(0xFFEBDBE7),
          const Color(0xFF472C43),
          const Color(0xFF64345B),
          const Color(0xFFF3C3E8),
        ),
      if (sections.containsKey(_experiences))
        tile(
          _experiences,
          Icons.restaurant_rounded,
          const Color(0xFFF1DFC1),
          const Color(0xFF503B27),
          const Color(0xFF70441A),
          const Color(0xFFFFD6A0),
        ),
    ];

    final workshops = sections.containsKey(_workshops)
        ? tile(
            _workshops,
            Icons.palette_outlined,
            const Color(0xFFF0D9D3),
            const Color(0xFF4D302C),
            const Color(0xFF80382D),
            const Color(0xFFFFC3B9),
          )
        : null;

    const mainSections = {_nature, _services, _experiences, _workshops};
    final otherSections = sections.keys.where(
      (section) => !mainSections.contains(section),
    );

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideTiles = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (quickLinks.isNotEmpty)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < quickLinks.length; i++) ...[
                            if (i > 0)
                              const SizedBox(width: AppSpacing.sm),
                            Expanded(child: quickLinks[i]),
                          ],
                        ],
                      ),
                    ),
                  if (workshops != null) ...[
                    if (quickLinks.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    workshops,
                  ],
                ],
              );

              if (nature == null) return sideTiles;
              if (quickLinks.isEmpty && workshops == null) return nature;

              if (constraints.maxWidth < 500) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    nature,
                    const SizedBox(height: AppSpacing.sm),
                    sideTiles,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: nature),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(flex: 3, child: sideTiles),
                  ],
                ),
              );
            },
          ),
          if (otherSections.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final section in otherSections)
                  ChoiceChip(
                    avatar: Icon(sections[section]!.first.icon, size: 18),
                    label: Text(section),
                    selected: section == selectedSection,
                    onSelected: (_) =>
                        setState(() => _selectedSection = section),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      selectedSection,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final category in sections[selectedSection]!)
                        ActionChip(
                          avatar: Icon(category.icon, size: 18),
                          label: Text(category.label),
                          onPressed: () =>
                              _selectCategory(context, category, store),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySectionTile extends StatelessWidget {
  const _CategorySectionTile({
    required this.label,
    required this.icon,
    required this.fill,
    required this.ink,
    required this.selected,
    required this.featured,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color ink;
  final bool selected;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: selected ? BorderSide(color: ink, width: 2) : BorderSide.none,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (featured)
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _HailMountainsPainter()),
                ),
              ),
            InkWell(
              onTap: onTap,
              customBorder: shape,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: featured ? 132 : 88),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: ink, size: 23),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HailMountainsPainter extends CustomPainter {
  const _HailMountainsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = const Color(0xFFDEC58C);

    canvas.drawCircle(Offset(w * .23, h * .30), 13, paint);

    final distantPeaks = Path()
      ..moveTo(0, h * .65)
      ..lineTo(w * .15, h * .51)
      ..lineTo(w * .28, h * .57)
      ..lineTo(w * .45, h * .33)
      ..lineTo(w * .55, h * .41)
      ..lineTo(w * .65, h * .36)
      ..lineTo(w * .82, h * .58)
      ..lineTo(w * .92, h * .48)
      ..lineTo(w, h * .59)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(distantPeaks, paint..color = const Color(0xFF6B8B72));

    final nearPeaks = Path()
      ..moveTo(0, h * .80)
      ..lineTo(w * .18, h * .72)
      ..lineTo(w * .32, h * .78)
      ..lineTo(w * .54, h * .56)
      ..lineTo(w * .67, h * .66)
      ..lineTo(w * .78, h * .61)
      ..lineTo(w, h * .80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(nearPeaks, paint..color = const Color(0xFF3E6656));
  }

  @override
  bool shouldRepaint(covariant _HailMountainsPainter oldDelegate) => false;
}
