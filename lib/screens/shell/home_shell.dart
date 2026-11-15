import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../providers/spots_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_menu_button.dart';
import '../home/home_feed_screen.dart';
import '../map/map_screen.dart';
import '../trips/trips_list_screen.dart';

/// Lets any tab jump to another tab (e.g. "Explore the map" from home).
class HomeTab extends ChangeNotifier {
  int index;
  String? _pendingCategory;
  HomeTab(this.index);
  void go(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }

  void browseCategory(String category) {
    _pendingCategory = category;
    go(0);
  }

  String? takeCategory() {
    final category = _pendingCategory;
    _pendingCategory = null;
    return category;
  }
}

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final HomeTab _tab = HomeTab(widget.initialIndex);

  static const _screens = [
    HomeFeedScreen(),
    MapScreen(),
    DalalCategoriesScreen(),
    TripsListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().load();
      context.read<TripsProvider>().load();
    });
  }

  Future<void> _addSpot() async {
    if (await ensureLoggedIn(context) && mounted) {
      if (mounted) Navigator.pushNamed(context, AppRoutes.addSpot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tab,
      child: Consumer<HomeTab>(
        builder: (context, tab, _) => Scaffold(
          key: shellScaffoldKey,
          drawer: const AppDrawer(),
          extendBody: true,
          body: IndexedStack(index: tab.index, children: _screens),
          bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
              ? null
              : _FloatingDock(tab: tab, onAddSpot: _addSpot),
        ),
      ),
    );
  }
}

/// The floating navigation dock and its central add-place action.
class _FloatingDock extends StatelessWidget {
  final HomeTab tab;
  final VoidCallback onAddSpot;

  const _FloatingDock({required this.tab, required this.onAddSpot});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.dockMaxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppColors.softShadow,
            ),
            child: Material(
              color: AppColors.tealDark,
              borderRadius: AppRadius.brCard,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: AppSpacing.dockHeight,
                child: Row(
                  children: [
                    _NavItem(
                      tab: tab,
                      index: 0,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: context.tr('home'),
                    ),
                    _NavItem(
                      tab: tab,
                      index: 1,
                      icon: Icons.map_outlined,
                      selectedIcon: Icons.map_rounded,
                      label: context.tr('map'),
                    ),
                    _DockAddButton(onTap: onAddSpot),
                    _NavItem(
                      tab: tab,
                      index: 2,
                      icon: Icons.category_outlined,
                      selectedIcon: Icons.category_rounded,
                      label: context.tr('categories'),
                    ),
                    _NavItem(
                      tab: tab,
                      index: 3,
                      icon: Icons.luggage_outlined,
                      selectedIcon: Icons.luggage_rounded,
                      label: context.tr('favorites'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Center "Add a spot" action.
class _DockAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DockAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Center(
        child: Tooltip(
          message: context.tr('addPlace'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: AppColors.coralMist,
              borderRadius: AppRadius.brMd,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 26,
                    color: AppColors.tealDark,
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

class _NavItem extends StatelessWidget {
  final HomeTab tab;
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.tab,
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final selected = tab.index == index;
    final color = selected ? AppColors.cream : AppColors.coralMist;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: AppRadius.brMd,
            child: InkWell(
              onTap: () => tab.go(index),
              borderRadius: AppRadius.brMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      color: color,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
