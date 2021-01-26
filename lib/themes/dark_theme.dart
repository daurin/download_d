import 'package:flutter/material.dart';

ThemeData darkTheme(BuildContext context) {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.grey.shade800,
    accentColor: Colors.blueAccent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

