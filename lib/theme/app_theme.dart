import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kCoral = Color(0xFFFF7043);
const Color kPastelPurple = Color(0xFF8E24AA);

final ThemeData unistayLightTheme = _buildTheme(Brightness.light);
final ThemeData unistayDarkTheme  = _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kPastelPurple,
    brightness: brightness,
  );

  final inter = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,

    textTheme: inter.copyWith(
      titleLarge: GoogleFonts.lato(
        fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      titleMedium: GoogleFonts.lato(
        fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleSmall: GoogleFonts.lato(
        fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
    ),

    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleTextStyle: GoogleFonts.lato(
        fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: inter.bodyMedium?.copyWith(color: scheme.outline),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kCoral,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedColor: scheme.primaryContainer,
      backgroundColor: scheme.surfaceContainerHighest,
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: inter.labelLarge!,
      secondaryLabelStyle: inter.labelLarge!,
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: kCoral,
      inactiveTrackColor: kCoral.withOpacity(0.25),
      thumbColor: kCoral,
      overlayColor: kCoral.withOpacity(0.08),
      trackHeight: 4,
      showValueIndicator: ShowValueIndicator.always,
      valueIndicatorColor: kCoral,
      valueIndicatorTextStyle: inter.labelLarge?.copyWith(color: Colors.white),
    ),

// Cards / Lists
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      showDragHandle: true,
      dragHandleColor: scheme.outline,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withOpacity(0.14),
      labelTextStyle: WidgetStatePropertyAll(
        inter.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),

    dividerColor: scheme.outlineVariant,
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
  );
}
