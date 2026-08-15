import 'package:flutter/material.dart';

// =============================================
// SISMO Theme — Colores y temas claro/oscuro
// =============================================

class SismoColors {
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const blue = Color(0xFF0EA5E9);
  static const teal = Color(0xFF00C9A7);
  static const grayAccent = Color(0xFF64748B);
}

final sismoLightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: const Color(0xFFF1F5F9),
  colorScheme: const ColorScheme.light(
    primary: SismoColors.teal,
    secondary: SismoColors.blue,
    surface: Color(0xFFFFFFFF),
    error: SismoColors.red,
  ),
  cardColor: const Color(0xFFFFFFFF),
  dividerColor: const Color(0xFFE2E8F0),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF0F172A),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    selectedItemColor: SismoColors.teal,
    unselectedItemColor: Color(0xFF94A3B8),
  ),
  extensions: const [SismoThemeExtension.light()],
);

final sismoDarkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: const Color(0xFF111827),
  colorScheme: const ColorScheme.dark(
    primary: SismoColors.teal,
    secondary: SismoColors.blue,
    surface: Color(0xFF1A2736),
    error: SismoColors.red,
  ),
  cardColor: const Color(0xFF1A2736),
  dividerColor: const Color(0xFF1E2D3D),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F1923),
    foregroundColor: Color(0xFFE2E8F0),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0F1923),
    selectedItemColor: SismoColors.teal,
    unselectedItemColor: Color(0xFF64748B),
  ),
  extensions: const [SismoThemeExtension.dark()],
);

// Extension para colores custom accesibles via Theme.of(context)
class SismoThemeExtension extends ThemeExtension<SismoThemeExtension> {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgCard;
  final Color bgInset;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;

  const SismoThemeExtension({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgCard,
    required this.bgInset,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
  });

  const SismoThemeExtension.light()
      : bgPrimary = const Color(0xFFF1F5F9),
        bgSecondary = const Color(0xFFFFFFFF),
        bgCard = const Color(0xFFFFFFFF),
        bgInset = const Color(0xFFF1F5F9),
        borderColor = const Color(0xFFE2E8F0),
        textPrimary = const Color(0xFF0F172A),
        textSecondary = const Color(0xFF475569),
        textMuted = const Color(0xFF94A3B8),
        textFaint = const Color(0xFFCBD5E1);

  const SismoThemeExtension.dark()
      : bgPrimary = const Color(0xFF111827),
        bgSecondary = const Color(0xFF0F1923),
        bgCard = const Color(0xFF1A2736),
        bgInset = const Color(0xFF111827),
        borderColor = const Color(0xFF1E2D3D),
        textPrimary = const Color(0xFFE2E8F0),
        textSecondary = const Color(0xFF94A3B8),
        textMuted = const Color(0xFF64748B),
        textFaint = const Color(0xFF475569);

  @override
  SismoThemeExtension copyWith({
    Color? bgPrimary, Color? bgSecondary, Color? bgCard, Color? bgInset,
    Color? borderColor, Color? textPrimary, Color? textSecondary,
    Color? textMuted, Color? textFaint,
  }) {
    return SismoThemeExtension(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgCard: bgCard ?? this.bgCard,
      bgInset: bgInset ?? this.bgInset,
      borderColor: borderColor ?? this.borderColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
    );
  }

  @override
  SismoThemeExtension lerp(covariant ThemeExtension<SismoThemeExtension>? other, double t) {
    if (other is! SismoThemeExtension) return this;
    return SismoThemeExtension(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgInset: Color.lerp(bgInset, other.bgInset, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
    );
  }
}

// Helper para acceder fácil
extension SismoThemeContext on BuildContext {
  SismoThemeExtension get sismo => Theme.of(this).extension<SismoThemeExtension>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
