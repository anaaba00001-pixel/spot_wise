import 'package:flutter/material.dart';

/// Dalal’s Violet Dusk palette and shared semantic colors.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color teal = Color(0xFF502D55); // Dalal primary
  static const Color tealDark = Color(0xFF3E2343);
  static const Color tealLight = Color(0xFF935073);
  static const Color tealMist = Color(0xFFF0E5EE);

  static const Color coral = Color(0xFF935073);
  static const Color coralDark = Color(0xFF743A59);
  static const Color coralMist = Color(0xFFF6DBC0);

  static const Color amber = Color(0xFFFFB454); // ratings / highlights

  // ── Neutrals (light) ──────────────────────────────────────────────────────
  static const Color cream = Color(
    0xFFF8F4E9,
  ); // app background (clean near-white)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF2EAF0); // chips / input fills
  static const Color ink = Color(0xFF27192D); // primary text + neutral controls
  static const Color inkSoft = Color(0xFF66566B); // secondary text
  static const Color inkFaint = Color(0xFF78667C); // hints / disabled
  static const Color border = Color(0xFFE7DCE6); // hairline

  // ── Neutrals (dark) ───────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF201424);
  static const Color darkSurface = Color(0xFF2D1C32);
  static const Color darkSurfaceAlt = Color(0xFF402A46);
  static const Color darkInk = Color(0xFFF8F4E9);
  static const Color darkInkSoft = Color(0xFFD1BDD0);
  static const Color darkInkFaint = Color(0xFFB49DB4);
  static const Color darkBorder = Color(0xFF513855);

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
  static const Color glassDark = Color(0xB32D1C32);

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
