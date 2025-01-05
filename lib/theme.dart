import 'package:flutter/material.dart';

// Custom color extension
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.translationIconActive,
    required this.translationIconInactive,
    required this.translationBackground,
    required this.chatBubblePrimary,
    required this.chatBubbleSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.imageDialogBackground,
    required this.closeButtonBackground,
    required this.dateSeparatorBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.switchActiveColor,
    required this.switchInactiveColor,
    required this.switchTrackColor,
  });

  final Color translationIconActive;
  final Color translationIconInactive;
  final Color translationBackground;
  final Color chatBubblePrimary;
  final Color chatBubbleSecondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color imageDialogBackground;
  final Color closeButtonBackground;
  final Color dateSeparatorBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color switchActiveColor;
  final Color switchInactiveColor;
  final Color switchTrackColor;

  @override
  CustomColors copyWith({
    Color? translationIconActive,
    Color? translationIconInactive,
    Color? translationBackground,
    Color? chatBubblePrimary,
    Color? chatBubbleSecondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? imageDialogBackground,
    Color? closeButtonBackground,
    Color? dateSeparatorBackground,
    Color? primaryText,
    Color? secondaryText,
    Color? switchActiveColor,
    Color? switchInactiveColor,
    Color? switchTrackColor,
  }) {
    return CustomColors(
      translationIconActive: translationIconActive ?? this.translationIconActive,
      translationIconInactive: translationIconInactive ?? this.translationIconInactive,
      translationBackground: translationBackground ?? this.translationBackground,
      chatBubblePrimary: chatBubblePrimary ?? this.chatBubblePrimary,
      chatBubbleSecondary: chatBubbleSecondary ?? this.chatBubbleSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      imageDialogBackground: imageDialogBackground ?? this.imageDialogBackground,
      closeButtonBackground: closeButtonBackground ?? this.closeButtonBackground,
      dateSeparatorBackground: dateSeparatorBackground ?? this.dateSeparatorBackground,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      switchActiveColor: switchActiveColor ?? this.switchActiveColor,
      switchInactiveColor: switchInactiveColor ?? this.switchInactiveColor,
      switchTrackColor: switchTrackColor ?? this.switchTrackColor,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      translationIconActive: Color.lerp(translationIconActive, other.translationIconActive, t)!,
      translationIconInactive: Color.lerp(translationIconInactive, other.translationIconInactive, t)!,
      translationBackground: Color.lerp(translationBackground, other.translationBackground, t)!,
      chatBubblePrimary: Color.lerp(chatBubblePrimary, other.chatBubblePrimary, t)!,
      chatBubbleSecondary: Color.lerp(chatBubbleSecondary, other.chatBubbleSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      imageDialogBackground: Color.lerp(imageDialogBackground, other.imageDialogBackground, t)!,
      closeButtonBackground: Color.lerp(closeButtonBackground, other.closeButtonBackground, t)!,
      dateSeparatorBackground: Color.lerp(dateSeparatorBackground, other.dateSeparatorBackground, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      switchActiveColor: Color.lerp(switchActiveColor, other.switchActiveColor, t)!,
      switchInactiveColor: Color.lerp(switchInactiveColor, other.switchInactiveColor, t)!,
      switchTrackColor: Color.lerp(switchTrackColor, other.switchTrackColor, t)!,
    );
  }
}

// Light theme custom colors
final _lightCustomColors = CustomColors(
  translationIconActive: const Color(0xFF9C27B0),
  translationIconInactive: Colors.grey,
  translationBackground: const Color(0xFFF3E5F5),
  chatBubblePrimary: Colors.green,
  chatBubbleSecondary: Colors.grey.shade300,
  success: Colors.green,
  warning: Colors.orange,
  error: Colors.red,
  imageDialogBackground: Colors.transparent,
  closeButtonBackground: Colors.black.withOpacity(0.7),
  dateSeparatorBackground: Colors.grey.shade200,
  primaryText: Colors.black,
  secondaryText: Colors.black54,
  switchActiveColor: Colors.black,
  switchInactiveColor: Colors.blue,
  switchTrackColor: Colors.white,
);

// Dark theme custom colors
final _darkCustomColors = CustomColors(
  translationIconActive: const Color(0xFFCE93D8),    // Light violet
  translationIconInactive: Colors.grey,
  translationBackground: const Color(0xFF4A148C),    // Dark violet
  chatBubblePrimary: Colors.green.shade700,
  chatBubbleSecondary: Colors.grey.shade800,
  success: Colors.green.shade700,
  warning: Colors.orange.shade700,
  error: Colors.red.shade700,
  imageDialogBackground: Colors.transparent,
  closeButtonBackground: Colors.black.withOpacity(0.7),
  dateSeparatorBackground: Colors.grey.shade800,
  primaryText: Colors.white,
  secondaryText: Colors.white70,
  switchActiveColor: Colors.white,
  switchInactiveColor: Colors.blue,
  switchTrackColor: Colors.black,
);

final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.purple,  // Changed to purple to match translation icon
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF9C27B0),  // Violet
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),  // Add this line
    actionsIconTheme: IconThemeData(color: Colors.white),  // Add this line
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF9C27B0),  // Violet
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black54),
    titleMedium: TextStyle(color: Colors.grey),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[300]!,
    selectedColor: Colors.green,
    labelStyle: const TextStyle(color: Colors.black),
  ),
  cardColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  dialogBackgroundColor: Colors.white,
  extensions: [_lightCustomColors],
);

final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.purple,  // Changed to purple to match translation icon
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
    foregroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.white),  // Add this line
    actionsIconTheme: const IconThemeData(color: Colors.white),  // Add this line
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFCE93D8),  // Light violet
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleMedium: TextStyle(color: Colors.grey),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[800]!,
    selectedColor: Colors.green.shade700,
    labelStyle: const TextStyle(color: Colors.white),
  ),
  cardColor: Colors.grey[900],
  scaffoldBackgroundColor: Colors.black,
  dialogBackgroundColor: Colors.grey[900],
  extensions: [_darkCustomColors],
);
