import 'package:flutter/material.dart';

class AppConstants {
  // Change to your machine's IP when testing on a physical device
  static const String baseUrl = 'http://172.29.55.191:8000';

  static const List<String> disasterTypes = [
    'Flood',
    'Cyclone',
    'Earthquake',
    'Fire',
    'Storm',
    'Landslide',
  ];

  static const Map<String, Color> tierColors = {
    'No Loss':    Color(0xFF1B5E20),
    'Minor':      Color(0xFF43A047),
    'Moderate':   Color(0xFFFB8C00),
    'High':       Color(0xFFE53935),
    'Severe':     Color(0xFF880E4F),
    'Total Loss': Color(0xFF6A1B9A),
    'Pending':    Color(0xFF546E7A),
  };

  // Compensation as a % of declared property value
  static const Map<String, double> tierMultiplier = {
    'No Loss':    0.00,
    'Minor':      0.15,
    'Moderate':   0.40,
    'High':       0.70,
    'Severe':     0.90,
    'Total Loss': 1.00,
    'Pending':    0.00,
  };
}
