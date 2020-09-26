import 'package:flutter/material.dart';

// ignore: non_constant_identifier_names
NavigationRailDestination NavButton({IconData iconData, String label}) {
  return NavigationRailDestination(
    icon: Icon(iconData, size: 20),
    selectedIcon: Icon(
      iconData,
      size: 20,
      color: Colors.cyan,
    ),
    label: Text(label),
  );
}
