import 'package:flutter/material.dart';

/// Lagoon brand palette — the single source of truth for color in SpotWise.
///
/// Teal = trust / maps / water. Coral = warmth / discovery / calls-to-action.
/// Amber = ratings & highlights. Designed for a calm light mode and a deep,
/// legible dark mode.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color teal = Color(0xFF4B236E); // Dalal primary
  static const Color tealDark = Color(0xFF35154F);
  static const Color tealLight = Color(0xFF765092);
  static const Color tealMist = Color(0xFFEDE2F3);

  static const Color coral = Color(0xFFC49A45); // warm Hail accent
  static const Color coralDark = Color(0xFFA47D32);
  static const Color coralMist = Color(0xFFF5EBD7);

  static const Color amber = Color(0xFFFFB454); // ratings / highlights

  // ── Neutrals (light) ──────────────────────────────────────────────────────
  static const Color cream = Color(
    0xFFF7F3FA,
  ); // app background (clean near-white)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F1EF); // chips / input fills
  static const Color ink = Color(0xFF15171A); // primary text + neutral controls
  static const Color inkSoft = Color(0xFF5C6066); // secondary text
  static const Color inkFaint = Color(0xFF9AA0A6); // hints / disabled
  static const Color border = Color(0xFFEAEAE7); // hairline

  // ── Neutrals (dark) ───────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF190D23);
  static const Color darkSurface = Color(0xFF281438);
  static const Color darkSurfaceAlt = Color(0xFF38204A);
  static const Color darkInk = Color(0xFFEAF1F2);
  static const Color darkInkSoft = Color(0xFFAFC2C5);
  static const Color darkInkFaint = Color(0xFF6E8A90);
  static const Color darkBorder = Color(0xFF24454D);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2B9D6E);
  static const Color warning = Color(0xFFE8A317);
  static const Color danger = Color(0xFFE0533D);
  static const Color info = Color(0xFF2D8CCB);
  static const Color star = amber;

  // ── Surfaces & effects ────────────────────────────────────────────────────
  /// Translucent white for circular buttons sitting on top of photos.
  static const Color glass = Color(0xE6FFFFFF);

  /// Translucent dark surface — dark-mode twin of [glass] for frosted
  /// surfaces (floating dock, glass buttons) over photos or content.
  static const Color glassDark = Color(0xB3152A30);

  /// Soft, diffuse card shadow (replaces hard borders for an airy, premium feel).
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient lagoonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, tealLight],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, amber],
  );

  /// Soft scrim used over photos so white text stays legible.
  static const LinearGradient photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x99000000)],
    stops: [0.45, 1.0],
  );

  /// Stronger bottom-up scrim for editorial overlay cards (text on the image).
  static const LinearGradient cardScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x40000000), Color(0xCC000000)],
    stops: [0.35, 0.68, 1.0],
  );
}
