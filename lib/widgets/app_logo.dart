import 'package:flutter/material.dart';

/// The Dalal app icon with an optional wordmark.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool stacked;
  final Color? wordmarkColor;

  const AppLogo({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.stacked = false,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/dalal-app-icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        semanticLabel: showWordmark ? null : 'دلال',
        excludeFromSemantics: showWordmark,
      ),
    );

    if (!showWordmark) return mark;

    final wordmark = Text(
      'دلال',
      style: TextStyle(
        fontSize: size * 0.62,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: wordmarkColor ?? Theme.of(context).colorScheme.onSurface,
      ),
    );

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(height: size * 0.3),
          wordmark,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.34),
        wordmark,
      ],
    );
  }
}
