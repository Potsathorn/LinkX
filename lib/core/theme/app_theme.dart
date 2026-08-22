import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Palette {
  const Palette._();

  static const Color black = Color(0xFF000000);
  static const Color navy = Color(0xFF14213D);
  static const Color amber = Color(0xFFFCA311);
  static const Color grey = Color(0xFFE4E4E4);
  static const Color white = Color(0xFFFFFFFF);

  static const Color navyRaised = Color(0xFF1B2C50);
  static const Color navyLine = Color(0xFF24365E);
  static const Color navyEdge = Color(0xFF32497A);
  static const Color amberDeep = Color(0xFF4A3208);
  static const Color greyMuted = Color(0xFF8C8C8C);
  static const Color greyFaint = Color(0xFF5A5A5A);
}

class AppTheme {
  const AppTheme._();

  static const List<String> monoFallback = <String>[
    'Menlo',
    'Consolas',
    'Roboto Mono',
    'monospace',
  ];

  static const ColorScheme scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Palette.amber,
    onPrimary: Palette.black,
    primaryContainer: Palette.amberDeep,
    onPrimaryContainer: Palette.amber,
    secondary: Palette.grey,
    onSecondary: Palette.black,
    secondaryContainer: Palette.navyRaised,
    onSecondaryContainer: Palette.grey,
    tertiary: Palette.white,
    onTertiary: Palette.black,
    tertiaryContainer: Palette.navyRaised,
    onTertiaryContainer: Palette.white,
    error: Palette.amber,
    onError: Palette.black,
    errorContainer: Palette.amberDeep,
    onErrorContainer: Palette.amber,
    surface: Palette.black,
    onSurface: Palette.white,
    surfaceContainerLowest: Palette.black,
    surfaceContainerLow: Palette.navy,
    surfaceContainer: Palette.navy,
    surfaceContainerHigh: Palette.navyRaised,
    surfaceContainerHighest: Palette.navyRaised,
    onSurfaceVariant: Palette.grey,
    outline: Palette.navyEdge,
    outlineVariant: Palette.navyLine,
    inverseSurface: Palette.grey,
    onInverseSurface: Palette.black,
    inversePrimary: Palette.amberDeep,
    shadow: Palette.black,
    scrim: Palette.black,
  );

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Palette.black,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.black,
        foregroundColor: Palette.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: Border(bottom: BorderSide(color: Palette.navyLine)),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Palette.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Palette.navy,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Palette.navyLine),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.navy,
        hintStyle: const TextStyle(color: Palette.greyFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.navyLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.navyLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.amber, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.amber),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.amber, width: 1.6),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Palette.navy,
        selectedColor: Palette.amber,
        side: const BorderSide(color: Palette.navyLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: Palette.grey,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: Palette.black,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        showCheckmark: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.amber,
          foregroundColor: Palette.black,
          disabledBackgroundColor: Palette.navyRaised,
          disabledForegroundColor: Palette.greyFaint,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.grey,
          disabledForegroundColor: Palette.greyFaint,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: Palette.navyEdge),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.amber,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Palette.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Palette.navyRaised,
        contentTextStyle: const TextStyle(color: Palette.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Palette.navyEdge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: Palette.black,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Palette.amber.withValues(alpha: 0.16),
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? Palette.amber
                : Palette.greyFaint,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: states.contains(WidgetState.selected)
                ? Palette.amber
                : Palette.greyFaint,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Palette.amber,
        linearTrackColor: Palette.navyLine,
        circularTrackColor: Palette.navyLine,
      ),
      dividerTheme: const DividerThemeData(
        color: Palette.navyLine,
        space: 1,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Palette.amber
              : Palette.greyFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Palette.amber.withValues(alpha: 0.22)
              : Palette.navyRaised,
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color>(Palette.navyEdge),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Palette.navy,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Palette.navyEdge),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.black,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: Palette.navyEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          side: BorderSide(color: Palette.navyEdge),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Palette.navyRaised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Palette.navyEdge),
        ),
        textStyle: const TextStyle(color: Palette.white, fontSize: 11.5),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Palette.white,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Palette.white,
        ),
        bodyMedium: TextStyle(color: Palette.white),
        bodySmall: TextStyle(color: Palette.grey),
        labelLarge: TextStyle(letterSpacing: 0.6, color: Palette.white),
        labelMedium: TextStyle(letterSpacing: 0.6, color: Palette.grey),
        labelSmall: TextStyle(letterSpacing: 0.8, color: Palette.grey),
      ),
    );
  }

  static TextStyle mono(BuildContext context, {double size = 13}) {
    return TextStyle(
      fontFamily: monoFallback.first,
      fontFamilyFallback: monoFallback,
      fontSize: size,
      height: 1.45,
      letterSpacing: 0.2,
      color: Palette.white,
    );
  }

  static TextStyle hudLabel(
      {Color color = Palette.greyMuted, double size = 9.5}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      color: color,
    );
  }

  static List<BoxShadow> glow(Color color,
      {double blur = 16, double opacity = 0.35, double spread = -2}) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }
}
