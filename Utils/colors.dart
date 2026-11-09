import 'package:flutter/material.dart';

/// App-wide colors inspired by the restaurant's Sri Lankan spice branding.
class MyColor {
  // Warm dark surfaces keep the app comfortable in its requested dark theme.
  static const Color darkBackground = Color(0xFF171310);
  static const Color darkSurface = Color(0xFF211B16);
  static const Color darkSurfaceRaised = Color(0xFF2C241D);
  static const Color outline = Color(0xFF756659);

  // Spice gold, leafy green, and chili red echo the restaurant logo and food.
  static const Color primary = Color(0xFFF2B544);
  static const Color onPrimary = Color(0xFF281900);
  static const Color secondary = Color(0xFFA9BE72);
  static const Color onSecondary = Color(0xFF20280D);
  static const Color tertiary = Color(0xFFEF8965);
  static const Color error = Color(0xFFFF8A80);

  // Legacy names are kept so existing screens use the updated brand palette.
  static const Color myYellow = primary;
  static const Color myGreen = secondary;
  static const Color myOrange = Color.fromARGB(255, 175, 53, 9);
  static const Color myRed = error;
  static const Color myWhite = Color(0xFFF6EFE6);
  static const Color invoicePaper = Color(0xFFF2F0E8);
  static const Color myBlack = darkBackground;

  // Shared utility colors used by older widgets and image overlays.
  static const Color myTransparent = Colors.transparent;
  static const Color myWhite70 = Color(0xFFCEC4B8);
  static const Color myWhite60 = Color(0xFFBEB2A5);
  static const Color myWhite12 = Colors.white12;
  static const Color myBlack12 = Colors.black12;
  static const Color myBlack26 = Color(0xFF9A8F84);
  static const Color myBlack87 = Colors.black87;
  static const Color myBlue = Color(0xFF8CB8E8);
  static const Color myGrey = Color(0xFFAAA198);
}
