import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerLinkColors {
  static const primaryBlack = Color(0xFF0B0B0F);
  static const secondaryBlack = Color(0xFF15151B);
  static const background = Color(0xFFF7F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const softSurface = Color(0xFFF1EEE8);
  static const green = Color(0xFF8FBF6A);
  static const greenSecondary = Color(0xFF6E9B58);
  static const greenMuted = Color(0xFFA9C49A);
  static const greenLight = Color(0xFFE8F5DA);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF5E5E66);
  static const textTertiary = Color(0xFF8A8A95);
  static const error = Color(0xFFE5484D);
  static const warning = Color(0xFFD89B3C);
  static const success = Color(0xFF4DAA57);
  static const outline = Color(0xFFE8E4DC);
  static const outlineVariant = Color(0xFFEBE7E0);

  // Shadows as const colors
  static const shadow06 = Color(0x0F000000);
  static const shadow08 = Color(0x14000000);
  static const shadow12 = Color(0x1F000000);
  static const shadow20 = Color(0x33000000);
  static const shadow25 = Color(0x40000000);
}

class AppTheme {
  static const double floatingNavHeight = 68.0;
  static const double floatingNavBottomMargin = 20.0;
  static const double floatingNavTotal = floatingNavHeight + floatingNavBottomMargin;
  static const double contentBottomPadding = floatingNavTotal + 16.0;
  static const double contentBottomPaddingFab = contentBottomPadding + 72.0;
  static const double fabOffset = 80.0;

  static TextTheme _textTheme() => TextTheme(
        displayLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w700,
            color: VerLinkColors.textPrimary, height: 1.2),
        displayMedium: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w700,
            color: VerLinkColors.textPrimary, height: 1.25),
        displaySmall: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w700,
            color: VerLinkColors.textPrimary, height: 1.25),
        headlineLarge: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: VerLinkColors.textPrimary, height: 1.3),
        headlineMedium: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600,
            color: VerLinkColors.textPrimary, height: 1.3),
        headlineSmall: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: VerLinkColors.textPrimary, height: 1.35),
        titleLarge: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600,
            color: VerLinkColors.textPrimary, height: 1.35),
        titleMedium: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: VerLinkColors.textPrimary, height: 1.4),
        titleSmall: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: VerLinkColors.textPrimary, height: 1.4),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w400,
            color: VerLinkColors.textPrimary, height: 1.5),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400,
            color: VerLinkColors.textPrimary, height: 1.5),
        bodySmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400,
            color: VerLinkColors.textSecondary, height: 1.4),
        labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: VerLinkColors.textPrimary, height: 1.4),
        labelMedium: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: VerLinkColors.textPrimary, height: 1.4),
        labelSmall: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: VerLinkColors.textTertiary, height: 1.4),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: VerLinkColors.green,
          onPrimary: Colors.white,
          primaryContainer: VerLinkColors.greenLight,
          onPrimaryContainer: VerLinkColors.greenSecondary,
          secondary: VerLinkColors.greenSecondary,
          onSecondary: Colors.white,
          surface: VerLinkColors.surface,
          onSurface: VerLinkColors.textPrimary,
          surfaceContainerHighest: VerLinkColors.softSurface,
          onSurfaceVariant: VerLinkColors.textSecondary,
          outline: VerLinkColors.outline,
          outlineVariant: VerLinkColors.outlineVariant,
          error: VerLinkColors.error,
          onError: Colors.white,
          shadow: Colors.black,
        ),
        scaffoldBackgroundColor: VerLinkColors.background,
        textTheme: _textTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: VerLinkColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            color: VerLinkColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(
            color: VerLinkColors.textPrimary,
            size: 24,
          ),
        ),
        cardTheme: CardThemeData(
          color: VerLinkColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: VerLinkColors.primaryBlack,
          selectedItemColor: VerLinkColors.green,
          unselectedItemColor: Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: VerLinkColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide:
                const BorderSide(color: VerLinkColors.outline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide:
                const BorderSide(color: VerLinkColors.outline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide:
                const BorderSide(color: VerLinkColors.green, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(
            color: VerLinkColors.textTertiary,
            fontSize: 14,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          prefixIconColor: VerLinkColors.textTertiary,
          suffixIconColor: VerLinkColors.textTertiary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: VerLinkColors.primaryBlack,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: VerLinkColors.surface,
          selectedColor: VerLinkColors.primaryBlack,
          secondarySelectedColor: VerLinkColors.primaryBlack,
          checkmarkColor: VerLinkColors.green,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: VerLinkColors.textSecondary,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: VerLinkColors.green,
          ),
          side: const BorderSide(color: VerLinkColors.outline),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          showCheckmark: false,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: VerLinkColors.textPrimary,
          unselectedLabelColor: VerLinkColors.textTertiary,
          indicatorColor: VerLinkColors.green,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: VerLinkColors.outlineVariant,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: VerLinkColors.outlineVariant,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: VerLinkColors.primaryBlack,
          contentTextStyle:
              GoogleFonts.inter(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 8,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: VerLinkColors.primaryBlack,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: VerLinkColors.green,
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: VerLinkColors.textPrimary,
            side: const BorderSide(color: VerLinkColors.outline),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return VerLinkColors.green;
            }
            return null;
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: VerLinkColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VerLinkColors.textPrimary,
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: VerLinkColors.textSecondary,
            height: 1.5,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: VerLinkColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          elevation: 0,
        ),
        listTileTheme: ListTileThemeData(
          titleTextStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: VerLinkColors.textPrimary,
          ),
          subtitleTextStyle: GoogleFonts.inter(
            fontSize: 13,
            color: VerLinkColors.textSecondary,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: VerLinkColors.green,
          surface: Color(0xFF1E1E2E),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF13131F),
        cardColor: const Color(0xFF262638),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF13131F),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E2E),
          selectedItemColor: VerLinkColors.green,
          unselectedItemColor: Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF262638),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide:
                const BorderSide(color: VerLinkColors.green, width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
}
