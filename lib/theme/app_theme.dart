import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kioku design system. Brand colours (the violet→magenta signature, gold,
/// cyan, status colours) are constant across light and dark. Only the
/// surfaces and text colours resolve against [AppColors.brightness], which the
/// app keeps in sync with the active [ThemeMode].
class AppColors {
  AppColors._();

  /// Set by the app shell each build from the resolved theme brightness.
  static Brightness brightness = Brightness.dark;
  static bool get _d => brightness == Brightness.dark;

  // ---- Dark surfaces / text ----
  static const Color _bgD = Color(0xFF0B0710);
  static const Color _bgAltD = Color(0xFF110B1B);
  static const Color _surfaceD = Color(0xFF171021);
  static const Color _surfaceHighD = Color(0xFF221631);
  static const Color _strokeD = Color(0x1AFFFFFF);
  static const Color _textHighD = Color(0xFFF6F3FB);
  static const Color _textMidD = Color(0xFFB6ABCB);
  static const Color _textLowD = Color(0xFF7E7394);

  // ---- Light surfaces / text ----
  static const Color _bgL = Color(0xFFF6F3FC);
  static const Color _bgAltL = Color(0xFFEDE8F7);
  static const Color _surfaceL = Color(0xFFFFFFFF);
  static const Color _surfaceHighL = Color(0xFFEDE7F6);
  static const Color _strokeL = Color(0x14000000);
  static const Color _textHighL = Color(0xFF1B1426);
  static const Color _textMidL = Color(0xFF5C5470);
  static const Color _textLowL = Color(0xFF9B90B0);

  static Color get bg => _d ? _bgD : _bgL;
  static Color get bgAlt => _d ? _bgAltD : _bgAltL;
  static Color get surface => _d ? _surfaceD : _surfaceL;
  static Color get surfaceHigh => _d ? _surfaceHighD : _surfaceHighL;
  static Color get stroke => _d ? _strokeD : _strokeL;
  static Color get textHigh => _d ? _textHighD : _textHighL;
  static Color get textMid => _d ? _textMidD : _textMidL;
  static Color get textLow => _d ? _textLowD : _textLowL;

  // ---- Brand (constant in both modes) ----
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryBright = Color(0xFFA855F7);
  static const Color accent = Color(0xFFFF4D8D);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color gold = Color(0xFFFFC24B);
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient brandSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFFFF4D8D), Color(0xFFFF8A5C)],
  );

  static const LinearGradient cyanViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, primary],
  );

  /// Dark bottom fade so text over a poster stays legible in either mode.
  static const LinearGradient posterScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x22000000),
      Color(0xCC0B0710),
      Color(0xF20B0710),
    ],
    stops: [0.0, 0.45, 0.8, 1.0],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    final scaffold = isDark ? AppColors._bgD : AppColors._bgL;
    final surface = isDark ? AppColors._surfaceD : AppColors._surfaceL;
    final surfaceHigh = isDark ? AppColors._surfaceHighD : AppColors._surfaceHighL;
    final textHigh = isDark ? AppColors._textHighD : AppColors._textHighL;
    final textMid = isDark ? AppColors._textMidD : AppColors._textMidL;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: textHigh, displayColor: textHigh);

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        tertiary: AppColors.cyan,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: textHigh,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textHigh,
        ),
        iconTheme: IconThemeData(color: textHigh),
      ),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceHigh,
        side: BorderSide.none,
        labelStyle: TextStyle(color: textMid, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  /// Display font used for big titles / logo-adjacent text.
  static TextStyle display(double size,
      {FontWeight weight = FontWeight.w700, Color? color}) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textHigh,
      height: 1.05,
    );
  }
}
