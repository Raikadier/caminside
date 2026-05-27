import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Paleta de colores (espejo del sistema de diseño de la diapositiva) ─────
const Color kBg       = Color(0xFF03030F);
const Color kBgCard   = Color(0xFF0D0D1F);
const Color kBgCard2  = Color(0xFF0A0A1A);
const Color kBorder   = Color(0xFF1E293B);

const Color kCyan     = Color(0xFF00F0FF);
const Color kPurple   = Color(0xFFA855F7);
const Color kOrange   = Color(0xFFF97316);
const Color kGreen    = Color(0xFF22C55E);
const Color kRed      = Color(0xFFEF4444);
const Color kYellow   = Color(0xFFEAB308);
const Color kBlue     = Color(0xFF3B82F6);

const Color kText     = Color(0xFFF1F5F9);
const Color kTextDim  = Color(0xFF94A3B8);
const Color kTextMut  = Color(0xFF475569);

// ── Tema oscuro ────────────────────────────────────────────────────────────
ThemeData buildTheme() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kBgCard2,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBg,
    colorScheme: const ColorScheme.dark(
      primary: kCyan,
      secondary: kPurple,
      surface: kBgCard,
      error: kRed,
      onPrimary: kBg,
      onSecondary: kBg,
      onSurface: kText,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
      iconTheme: IconThemeData(color: kTextDim),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kBgCard2,
      selectedItemColor: kCyan,
      unselectedItemColor: kTextMut,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: TextStyle(fontSize: 9),
    ),

    cardTheme: CardThemeData(
      color: kBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kCyan,
        foregroundColor: kBg,
        elevation: 0,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kCyan,
        side: const BorderSide(color: kCyan, width: 1),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kCyan, width: 1.5),
      ),
      hintStyle: const TextStyle(color: kTextMut, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: kCyan,
      inactiveTrackColor: kBorder,
      thumbColor: kCyan,
      overlayColor: kCyan.withValues(alpha: 0.15),
      valueIndicatorColor: kCyan,
      valueIndicatorTextStyle: const TextStyle(color: kBg, fontWeight: FontWeight.w700),
    ),

    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ── Helpers de estilo reutilizables ────────────────────────────────────────
const monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  color: kTextDim,
  height: 1.5,
);

BoxDecoration cardDecoration({Color borderColor = kBorder, double radius = 12}) =>
    BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
    );

BoxDecoration glowDecoration(Color color, {double radius = 12}) => BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 1),
      ],
    );
