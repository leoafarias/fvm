import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark theme
ThemeData darkTheme() {
  return ThemeData(
    textTheme: GoogleFonts.ibmPlexSansTextTheme(ThemeData.dark().textTheme),
    brightness: Brightness.dark,
    primarySwatch: Colors.cyan,
    accentColor: Colors.cyan,
    // cardColor: const Color(0xFF222222),
    // scaffoldBackgroundColor: const Color(0xFF0E0E0E),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      color: Color(0xFF333333),
    ),
    cardTheme: const CardTheme(shape: RoundedRectangleBorder()),
    dialogTheme: DialogTheme(
      elevation: 10,
      shape: Border.all(color: Colors.white24),
      backgroundColor: Colors.black87,
    ),
  ).copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
