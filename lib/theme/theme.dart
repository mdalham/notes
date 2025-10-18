import 'package:flutter/material.dart';

import 'color.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,

  colorScheme: const ColorScheme.light(
    surface: bgLight,
    primaryContainer: containerLight,
    outline: outlineLight,
    primary: fontLight,
    onPrimary: subFontLight,
    onSurface: lightIconBackgroundColor,
  ),

);


final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,

    colorScheme: const ColorScheme.dark(
      surface: bgDark,
      primaryContainer: containerDark,
      outline: outlineDark,
      primary: fontDark,
      onPrimary: subFontDark,
      onSurface: darkIconBackgroundColor,
    )
);