import 'package:flutter/material.dart';

/// Design tokens and styling for a natural, premium sports arcade theme.
/// Clean, authentic stadium pitch aesthetics, crisp typography, and realistic depth.
class GameTheme {
  // --- Natural Stadium Pitch Tones ---
  static const Color pitchBase = Color(0xFF0F1F1D);       // Deep emerald stadium night base
  static const Color pitchLawnBand = Color(0xFF142926);   // Alternating grass cut stripes
  static const Color pitchVignette = Color(0xFF091413);   // Soft outer stadium vignette
  static const Color pitchLine = Color(0x38FFFFFF);       // Crisp chalk court lines
  static const Color pitchGoalArea = Color(0x10FFFFFF);   // Subtle goal area tint
  static const Color netLine = Color(0x22FFFFFF);         // Cross-hatch goal net lines

  // --- Team / Player Accents ---
  // Player 1 (Bottom / You): Athletic Electric Blue
  static const Color player1 = Color(0xFF0284C7);
  static const Color player1Light = Color(0xFF38BDF8);
  static const Color player1Dark = Color(0xFF0369A1);

  // Player 2 / AI (Top): Athletic Coral / Orange
  static const Color player2 = Color(0xFFEA580C);
  static const Color player2Light = Color(0xFFFB923C);
  static const Color player2Dark = Color(0xFFC2410C);

  // Warm Trophy / Gold
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);

  // --- UI Surfaces & Glassmorphism ---
  static const Color cardBg = Color(0xF2111827);          // Deep slate obsidian glass
  static const Color cardSurface = Color(0xFF1F2937);     // Elevated chip / card background
  static const Color cardBorder = Color(0x1FFFFFFF);      // Delicate, crisp 1px border
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);   // Slate 400
  static const Color textMuted = Color(0xFF64748B);       // Slate 500

  // --- Aliases for compatibility ---
  static const Color cyan = player1;
  static const Color cyanDark = player1Dark;
  static const Color cyanGlow = Color(0x330284C7);

  static const Color orange = player2;
  static const Color orangeLight = player2Light;
  static const Color orangeGlow = Color(0x33EA580C);

  static const Color yellow = gold;
  static const Color yellowGlow = Color(0x33F59E0B);

  static const Color bgDark = pitchBase;
  static const Color bgCenter = pitchLawnBand;
  static const Color bgEdges = pitchVignette;
  static const Color gridLine = pitchLine;
  static const Color courtCenterLine = pitchLine;

  // --- Natural Elevation & Depth Shadows (No harsh radioactive bloom) ---
  static List<BoxShadow> softElevation({double blur = 20.0, double dy = 8.0, double alpha = 0.35}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
  }

  static List<BoxShadow> subtleAccentShadow(Color color, {double blur = 14.0, double dy = 4.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.28),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: blur * 0.7,
        offset: Offset(0, dy * 1.5),
      ),
    ];
  }

  // Refined alias for backwards compatibility (softened from harsh neon)
  static List<BoxShadow> neonGlow(Color color, {double blur = 14.0, double spread = 0.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.25),
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: blur * 0.8,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
