import 'package:flutter/material.dart';

/// Exact Unity Dark Theme color palette and styles.
class UnityTheme {
  UnityTheme._();

  // Background Colors
  static const Color windowBg = Color(0xFF202020);
  static const Color panelBg = Color(0xFF383838);
  static const Color panelBgDark = Color(0xFF2A2A2A);
  static const Color panelHeader = Color(0xFF3C3C3C);
  static const Color panelHeaderInactive = Color(0xFF2C2C2C);
  static const Color toolbarBg = Color(0xFF303030);
  static const Color menuBarBg = Color(0xFF1E1E1E);

  // Borders & Dividers
  static const Color border = Color(0xFF1A1A1A);
  static const Color borderLight = Color(0xFF4A4A4A);
  static const Color splitBorder = Color(0xFF1F1F1F);

  // Input & Elements
  static const Color inputBg = Color(0xFF242424);
  static const Color inputBorder = Color(0xFF1B1B1B);
  static const Color buttonBg = Color(0xFF484848);
  static const Color buttonHover = Color(0xFF5A5A5A);
  static const Color buttonActive = Color(0xFF3A3A3A);

  // Selection & Accents (Unity Signature Blue)
  static const Color selectionBlue = Color(0xFF2C5D88);
  static const Color selectionBlueLight = Color(0xFF3B72A4);
  static const Color playGreen = Color(0xFF4CAF50);
  static const Color pauseAmber = Color(0xFFFFB300);

  // Axis Colors (RGB = XYZ)
  static const Color axisX = Color(0xFFE54B4B);
  static const Color axisY = Color(0xFF68B030);
  static const Color axisZ = Color(0xFF3D85C6);

  // Typography Colors
  static const Color textMain = Color(0xFFD2D2D2);
  static const Color textMuted = Color(0xFF8F8F8F);
  static const Color textDim = Color(0xFF666666);
  static const Color textBright = Color(0xFFFFFFFF);

  // Text Styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.bold,
    color: textMain,
    letterSpacing: 0.3,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 11.5,
    color: textMuted,
  );

  static const TextStyle inputStyle = TextStyle(
    fontSize: 11.5,
    color: textMain,
    fontFamily: 'monospace',
  );

  static ThemeData get themeData {
    return ThemeData.dark(useMaterial3: false).copyWith(
      scaffoldBackgroundColor: windowBg,
      canvasColor: panelBg,
      dividerColor: border,
      dialogTheme: const DialogThemeData(backgroundColor: panelBg),
      colorScheme: const ColorScheme.dark(
        primary: selectionBlue,
        secondary: selectionBlueLight,
        surface: panelBg,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(const Color(0xFF555555)),
        trackColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)),
        thickness: WidgetStateProperty.all(6.0),
        radius: Radius.zero,
      ),
    );
  }
}
