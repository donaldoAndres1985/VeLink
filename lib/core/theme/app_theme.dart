import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerLinkColors {
  static const primaryBlack = Color(0xFF0B0B0F);
  static const secondaryBlack = Color(0xFF15151B);
  static const background = Color(0xFFF7F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const softSurface = Color(0xFFF1EEE8);

  // Verde — sistema de color primario
  static const primary = Color(0xFF8FBF6A);
  static const primaryDark = Color(0xFF6E9B58);
  static const secondary = Color(0xFF6E9B58);
  static const secondaryMuted = Color(0xFFA9C49A);
  static const primaryContainerLight = Color(0xFFE8F5DA);
  static const accentOnDark = Color(0xFF8FBF6A);

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
        extensions: const [VeLinkSemanticColors.light],
        colorScheme: const ColorScheme.light(
          primary: VerLinkColors.primary,
          onPrimary: Colors.white,
          primaryContainer: VerLinkColors.primaryContainerLight,
          onPrimaryContainer: VerLinkColors.primaryDark,
          secondary: VerLinkColors.secondary,
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
          selectedItemColor: VerLinkColors.accentOnDark,
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
                const BorderSide(color: VerLinkColors.primary, width: 1.5),
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
          checkmarkColor: VerLinkColors.accentOnDark,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: VerLinkColors.textSecondary,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: VerLinkColors.accentOnDark,
          ),
          side: const BorderSide(color: VerLinkColors.outline),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          showCheckmark: false,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: VerLinkColors.textPrimary,
          unselectedLabelColor: VerLinkColors.textTertiary,
          indicatorColor: VerLinkColors.primary,
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
            foregroundColor: VerLinkColors.primary,
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
              return VerLinkColors.primary;
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

  static TextTheme _darkTextTheme() => TextTheme(
        displayLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w700,
            color: DarkColors.textPrimary, height: 1.2),
        displayMedium: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w700,
            color: DarkColors.textPrimary, height: 1.25),
        displaySmall: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w700,
            color: DarkColors.textPrimary, height: 1.25),
        headlineLarge: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: DarkColors.textPrimary, height: 1.3),
        headlineMedium: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary, height: 1.3),
        headlineSmall: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary, height: 1.35),
        titleLarge: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary, height: 1.35),
        titleMedium: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary, height: 1.4),
        titleSmall: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary, height: 1.4),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w400,
            color: DarkColors.textPrimary, height: 1.5),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400,
            color: DarkColors.textPrimary, height: 1.5),
        bodySmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400,
            color: DarkColors.textSecondary, height: 1.4),
        labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: DarkColors.textPrimary, height: 1.4),
        labelMedium: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: DarkColors.textPrimary, height: 1.4),
        labelSmall: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: DarkColors.textTertiary, height: 1.4),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: const [VeLinkSemanticColors.dark],
        colorScheme: const ColorScheme.dark(
          primary: VerLinkColors.accentOnDark,
          onPrimary: DarkColors.onPrimary,
          primaryContainer: DarkColors.primaryContainerDark,
          onPrimaryContainer: VerLinkColors.secondaryMuted,
          secondary: VerLinkColors.secondaryMuted,
          onSecondary: DarkColors.onPrimary,
          surface: DarkColors.surface,
          onSurface: DarkColors.textPrimary,
          surfaceContainerHighest: DarkColors.surfaceElevated,
          onSurfaceVariant: DarkColors.textSecondary,
          outline: DarkColors.outline,
          outlineVariant: DarkColors.outlineVariant,
          error: DarkColors.error,
          onError: Colors.white,
          shadow: Colors.black,
        ),
        scaffoldBackgroundColor: DarkColors.background,
        textTheme: _darkTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: DarkColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            color: DarkColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(
            color: DarkColors.textPrimary,
            size: 24,
          ),
        ),
        cardTheme: CardThemeData(
          color: DarkColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: DarkColors.navBar,
          selectedItemColor: VerLinkColors.accentOnDark,
          unselectedItemColor: DarkColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DarkColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: DarkColors.outline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: DarkColors.outline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(
                color: VerLinkColors.accentOnDark, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(
            color: DarkColors.textTertiary,
            fontSize: 14,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          prefixIconColor: DarkColors.textTertiary,
          suffixIconColor: DarkColors.textTertiary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: VerLinkColors.accentOnDark,
          foregroundColor: DarkColors.onPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: DarkColors.surfaceElevated,
          selectedColor: VerLinkColors.accentOnDark,
          secondarySelectedColor: VerLinkColors.accentOnDark,
          checkmarkColor: DarkColors.onPrimary,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: DarkColors.textSecondary,
          ),
          secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: DarkColors.onPrimary,
          ),
          side: const BorderSide(color: DarkColors.outline),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          showCheckmark: false,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: DarkColors.textPrimary,
          unselectedLabelColor: DarkColors.textTertiary,
          indicatorColor: VerLinkColors.accentOnDark,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: DarkColors.outlineVariant,
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
          color: DarkColors.outlineVariant,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: DarkColors.surfaceElevated,
          contentTextStyle:
              GoogleFonts.inter(color: DarkColors.textPrimary, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 8,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: VerLinkColors.accentOnDark,
            foregroundColor: DarkColors.onPrimary,
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
            foregroundColor: VerLinkColors.accentOnDark,
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: DarkColors.textPrimary,
            side: const BorderSide(color: DarkColors.outline),
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
            return DarkColors.textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return VerLinkColors.accentOnDark;
            }
            return DarkColors.outline;
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: DarkColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DarkColors.textPrimary,
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: DarkColors.textSecondary,
            height: 1.5,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: DarkColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          elevation: 0,
        ),
        listTileTheme: ListTileThemeData(
          titleTextStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: DarkColors.textPrimary,
          ),
          subtitleTextStyle: GoogleFonts.inter(
            fontSize: 13,
            color: DarkColors.textSecondary,
          ),
        ),
      );
}

class DarkColors {
  static const background       = Color(0xFF0D0D15);
  static const surface          = Color(0xFF14141F);
  static const surfaceElevated  = Color(0xFF1C1C2C);
  static const surfaceVariant   = Color(0xFF222235);
  static const navBar           = Color(0xFF0F0F1B);

  static const textPrimary      = Color(0xFFECECF5);
  static const textSecondary    = Color(0xFF9292AE);
  static const textTertiary     = Color(0xFF515168);

  static const outline          = Color(0xFF2B2B3E);
  static const outlineVariant   = Color(0xFF1E1E2E);

  static const error            = Color(0xFFFF6B6B);
  static const warning          = Color(0xFFEFAA44);
  static const success          = Color(0xFF4DAA57);

  static const onPrimary            = Colors.white;
  static const primaryContainerDark = Color(0xFF1E2D1A);
}

@immutable
class VeLinkSemanticColors extends ThemeExtension<VeLinkSemanticColors> {
  final Color surface;
  final Color surfaceContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color outline;
  final Color outlineVariant;
  final Color shadow06;
  final Color shadow08;
  final Color shadow12;
  final Color shadow25;
  final Color chipSelectedBg;
  final Color primaryTint;
  final Color warning;
  final Color navBarBg;

  const VeLinkSemanticColors({
    required this.surface,
    required this.surfaceContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.outline,
    required this.outlineVariant,
    required this.shadow06,
    required this.shadow08,
    required this.shadow12,
    required this.shadow25,
    required this.chipSelectedBg,
    required this.primaryTint,
    required this.warning,
    required this.navBarBg,
  });

  static VeLinkSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<VeLinkSemanticColors>() ??
      VeLinkSemanticColors.light;

  static const light = VeLinkSemanticColors(
    surface:          Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF1EEE8),
    textPrimary:      Color(0xFF111111),
    textSecondary:    Color(0xFF5E5E66),
    textTertiary:     Color(0xFF8A8A95),
    outline:          Color(0xFFE8E4DC),
    outlineVariant:   Color(0xFFEBE7E0),
    shadow06:         Color(0x0F000000),
    shadow08:         Color(0x14000000),
    shadow12:         Color(0x1F000000),
    shadow25:         Color(0x40000000),
    chipSelectedBg:   Color(0xFF0B0B0F),
    primaryTint:      Color(0xFFE8F5DA),
    warning:          Color(0xFFD89B3C),
    navBarBg:         Color(0xFF0B0B0F),
  );

  static const dark = VeLinkSemanticColors(
    surface:          Color(0xFF14141F),
    surfaceContainer: Color(0xFF1C1C2C),
    textPrimary:      Color(0xFFECECF5),
    textSecondary:    Color(0xFF9292AE),
    textTertiary:     Color(0xFF515168),
    outline:          Color(0xFF2B2B3E),
    outlineVariant:   Color(0xFF1E1E2E),
    shadow06:         Color(0x00000000),
    shadow08:         Color(0x00000000),
    shadow12:         Color(0x1A000000),
    shadow25:         Color(0x00000000),
    chipSelectedBg:   Color(0xFF222235),
    primaryTint:      Color(0xFF172612),
    warning:          Color(0xFFEFAA44),
    navBarBg:         Color(0xFF0F0F1B),
  );

  @override
  VeLinkSemanticColors copyWith({
    Color? surface,
    Color? surfaceContainer,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? outline,
    Color? outlineVariant,
    Color? shadow06,
    Color? shadow08,
    Color? shadow12,
    Color? shadow25,
    Color? chipSelectedBg,
    Color? primaryTint,
    Color? warning,
    Color? navBarBg,
  }) =>
      VeLinkSemanticColors(
        surface:          surface          ?? this.surface,
        surfaceContainer: surfaceContainer ?? this.surfaceContainer,
        textPrimary:      textPrimary      ?? this.textPrimary,
        textSecondary:    textSecondary    ?? this.textSecondary,
        textTertiary:     textTertiary     ?? this.textTertiary,
        outline:          outline          ?? this.outline,
        outlineVariant:   outlineVariant   ?? this.outlineVariant,
        shadow06:         shadow06         ?? this.shadow06,
        shadow08:         shadow08         ?? this.shadow08,
        shadow12:         shadow12         ?? this.shadow12,
        shadow25:         shadow25         ?? this.shadow25,
        chipSelectedBg:   chipSelectedBg   ?? this.chipSelectedBg,
        primaryTint:      primaryTint      ?? this.primaryTint,
        warning:          warning          ?? this.warning,
        navBarBg:         navBarBg         ?? this.navBarBg,
      );

  @override
  VeLinkSemanticColors lerp(VeLinkSemanticColors? other, double t) {
    if (other is! VeLinkSemanticColors) return this;
    return VeLinkSemanticColors(
      surface:          Color.lerp(surface,          other.surface,          t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      textPrimary:      Color.lerp(textPrimary,      other.textPrimary,      t)!,
      textSecondary:    Color.lerp(textSecondary,    other.textSecondary,    t)!,
      textTertiary:     Color.lerp(textTertiary,     other.textTertiary,     t)!,
      outline:          Color.lerp(outline,          other.outline,          t)!,
      outlineVariant:   Color.lerp(outlineVariant,   other.outlineVariant,   t)!,
      shadow06:         Color.lerp(shadow06,         other.shadow06,         t)!,
      shadow08:         Color.lerp(shadow08,         other.shadow08,         t)!,
      shadow12:         Color.lerp(shadow12,         other.shadow12,         t)!,
      shadow25:         Color.lerp(shadow25,         other.shadow25,         t)!,
      chipSelectedBg:   Color.lerp(chipSelectedBg,   other.chipSelectedBg,   t)!,
      primaryTint:      Color.lerp(primaryTint,      other.primaryTint,      t)!,
      warning:          Color.lerp(warning,          other.warning,          t)!,
      navBarBg:         Color.lerp(navBarBg,         other.navBarBg,         t)!,
    );
  }
}
