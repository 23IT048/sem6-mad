import 'package:flutter/material.dart';

class AppColors {
  // Modern Light Theme Colors
  static const Color primaryNavy = Color(0xFF1a1f36);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color cardWhite = Colors.white;
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color successGreen = Color(0xFF00C853);
  static const Color warningOrange = Color(0xFFFF6F00);
  static const Color mutedGray = Color(0xFF6B7280);
  static const Color borderGray = Color(0xFFE5E7EB);
  
  // Legacy colors (kept for compatibility)
  static const Color primaryBlue = primaryNavy;
  static const Color background = lightBackground;
  static const Color accentGreen = Color(0xFF008A67);
  static const Color darkBlue = Color(0xFF004D75);
  static const Color lightBlue = Color(0xFF4DA6D6);
  
  // Modern Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryNavy, Color(0xFF2d3561)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBlue, Color(0xFF64B5F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, Color(0xFF00E676)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFDFDFD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow for cards
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryNavy.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
