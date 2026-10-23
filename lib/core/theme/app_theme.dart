import 'package:flutter/material.dart';

/// Paleta de Renti tomada de los diseños.
class RentiColors {
  static const blue = Color(0xFF2563EB);
  static const orange = Color(0xFFFF6B35);
  static const green = Color(0xFF22C55E);
  static const yellow = Color(0xFFFFC857);
  static const background = Color(0xFFFFF8F0);
  static const ink = Color(0xFF1A2035);
  static const grey = Color(0xFF6B7280);
  static const border = Color(0xFFE8EAF0);
  static const chipGrey = Color(0xFFE8EAF0);
  static const bubbleGrey = Color(0xFFF0F2F6);
  static const surface = Colors.white;
  static const mapBackground = Color(0xFFE6EBFA);
}

class RentiTheme {
  static const double pad = 24;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF12151F) : RentiColors.background;
    final ink = dark ? Colors.white : RentiColors.ink;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: RentiColors.blue,
        brightness: b,
        primary: RentiColors.blue,
        secondary: RentiColors.orange,
        surface: dark ? const Color(0xFF1C2030) : Colors.white,
      ),
      textTheme: ThemeData(brightness: b).textTheme.apply(
            bodyColor: ink,
            displayColor: ink,
          ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}

/// Atajos para colores que cambian con el modo claro / oscuro.
extension RentiContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => isDark ? Colors.white : RentiColors.ink;
  Color get card => isDark ? const Color(0xFF1C2030) : Colors.white;
  Color get line => isDark ? const Color(0xFF2B3042) : RentiColors.border;
  Color get muted => isDark ? const Color(0xFF9AA1B2) : RentiColors.grey;
}

List<BoxShadow> softShadow([double opacity = 0.08]) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

List<BoxShadow> orangeShadow() => [
      BoxShadow(
        color: RentiColors.orange.withValues(alpha: 0.35),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];
