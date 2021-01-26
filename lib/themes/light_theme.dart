import 'package:flutter/material.dart';

ThemeData lightTheme(BuildContext context) {
  return ThemeData(
    primaryColor: Colors.blue,
    accentColor: Colors.blueAccent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
