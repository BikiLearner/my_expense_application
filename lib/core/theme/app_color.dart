import 'package:flutter/material.dart';

class AppColor {
  AppColor._();

  // Primary
  static const primary = Color(0xFF64FFDA);

  // Background
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceDark = Color(0xFF0A0A0F);
  static const surfaceDeep = Color(0xFF0F1115);
  static const surfaceNavy = Color(0xFF0A0E27);
  static const surfaceAlt = Color(0xFF1A1A1A);
  static const surfaceBlueGray = Color(0xFF171A21);
  static const surfaceCard = Color(0xFF141420);
  static const surfaceCardAlt = Color(0xFF1C2333);
  static const surfaceSlate = Color(0xFF1F232C);
  static const surfaceDarkGray = Color(0xFF252525);

  // Card/Input
  static const cardBg = Color(0xFF2C2C2C);
  static const cardBorder = Color(0xFF3C3C3C);
  static const cardBgSlate = Color(0xFF2D3748);
  static const cardBgGray = Color(0xFF374151);
  static const bannerBg = Color(0xFF2A2A2A);

  // Gradients
  static const gradientStart = Color(0xFF1E3A5F);
  static const gradientEnd = Color(0xFF2A5298);
  static const gradientDarkStart = Color(0xFF2C3E50);
  static const gradientDarkEnd = Color(0xFFDAA520);
  static const gradientRedStart = Color(0xFFff416c);
  static const gradientRedEnd = Color(0xFFff4b2b);
  static const analyticsGradientStart = Color(0xFF0D1117);
  static const analyticsGradientEnd = Color(0xFF161B22);

  // Expense Type
  static const luxury = Color(0xFFFF6B6B);
  static const needed = Color(0xFFFF9A3C);
  static const saving = Color(0xFF51CF66);

  // Analytics Palette
  static const paletteBlue = Color(0xFF7B8CFF);
  static const paletteAmber = Color(0xFFFFD166);
  static const palettePink = Color(0xFFE64980);
  static const paletteLightBlue = Color(0xFF74C0FC);
  static const paletteLime = Color(0xFFA9E34B);
  static const palettePurple = Color(0xFFCC5DE8);
  static const paletteOrange = Color(0xFFFFB347);
  static const paletteRed = Color(0xFFFF4757);
  static const paletteGreen = Color(0xFF2ECC71);

  // Heatmap
  static const heatmapNone = Color(0xFF1A1A2E);
  static const heatmapLow = Color(0xFF0D3D3D);
  static const heatmapMid = Color(0xFF0A6060);
  static const heatmapHigh = Color(0xFF0A9090);

  // KPI Medals
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFC0C0C0);
  static const bronze = Color(0xFFCD7F32);

  // Success/Error
  static const success = Color(0xFF4CAF50);

  // Text
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textGrey = Color(0xFF9AA0A6);
  static const textLight = Color(0xFFE8EAED);

  // Misc
  static const transparent = Colors.transparent;
  static const black = Color(0xFF000000);
  static const bottomSheetBg = Color(0xFF1E1E2E);

  // Bank Monthly Breakdown (Tailwind palette)
  static const twBlue600 = Color(0xFF2563EB);
  static const twBlue500 = Color(0xFF3B82F6);
  static const twBlue400 = Color(0xFF60A5FA);
  static const twEmerald = Color(0xFF10B981);
  static const twRed = Color(0xFFEF4444);
  static const twViolet = Color(0xFF8B5CF6);

  static const white = Colors.white;

  // Accent helpers
  static Color grey300 = Colors.grey[300]!;
  static Color grey400 = Colors.grey[400]!;
  static Color grey500 = Colors.grey[500]!;
  static Color grey600 = Colors.grey[600]!;
  static Color grey700 = Colors.grey[700]!;
  static Color grey800 = Colors.grey[800]!;

// ============================================================
  // Premium Credit Theme (screen chrome — app bar, FAB, banner)
  // Monochrome black & white / graphite palette
  // ============================================================
  static const creditPrimary = Color(0xFF1A1A1A);   // Near-black charcoal
  static const creditDark = Color(0xFF000000);       // Pure black
  static const creditLight = Color(0xFFD9D9D9);      // Soft light grey

  static const creditSurface = Color(0xFF121212);    // Screen background tint
  static const creditCard = Color(0xFF1E1E1E);        // Card surface fallback
  static const creditBorder = Color(0x33FFFFFF);      // Faint white hairline

  // Banner / FAB gradient
  static const creditGradientStart = Color(0xFF000000);
  static const creditGradientEnd = Color(0xFF3A3A3A);

  // Accent
  static const creditAccent = Color(0xFFE8E8E8);      // Platinum silver-white
  static const creditSoft = Color(0xFFF5F5F5);         // Off-white (active/success glow)

  // Status (kept as functional/semantic color-coding for readability)
  static const creditDue = Color(0xFFEF4444);         // Red
  static const creditPaid = Color(0xFF22C55E);        // Green
  static const creditEMI = Color(0xFFF59E0B);         // Amber
  static const creditLimit = Color(0xFF38BDF8);       // Sky Blue

  // ------------------------------------------------------------
  // Rotating premium card palettes — used so each credit card in
  // the list gets a distinct, bank-card-like look instead of one
  // repeated flat gradient. Now monochrome black/white/graphite.
  // ------------------------------------------------------------
  static const List<CreditCardPalette> creditCardPalettes = [
    CreditCardPalette(
      name: 'Obsidian',
      gradient: [Color(0xFF000000), Color(0xFF161616), Color(0xFF262626)],
      accent: Color(0xFFE8E8E8), // silver-white chip
      glow: Color(0xFF262626),
    ),
    CreditCardPalette(
      name: 'Graphite',
      gradient: [Color(0xFF1C1C1C), Color(0xFF2E2E2E), Color(0xFF3D3D3D)],
      accent: Color(0xFFF0F0F0),
      glow: Color(0xFF2E2E2E),
    ),
    CreditCardPalette(
      name: 'Platinum Frost',
      gradient: [Color(0xFF2A2A2A), Color(0xFF4A4A4A), Color(0xFF616161)],
      accent: Color(0xFFFFFFFF),
      glow: Color(0xFF4A4A4A),
    ),
    CreditCardPalette(
      name: 'Onyx Steel',
      gradient: [Color(0xFF0D0D0D), Color(0xFF232323), Color(0xFF3A3A3A)],
      accent: Color(0xFFDADADA),
      glow: Color(0xFF232323),
    ),
    CreditCardPalette(
      name: 'Pearl Noir',
      gradient: [Color(0xFF050505), Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
      accent: Color(0xFFFAFAFA),
      glow: Color(0xFF1A1A1A),
    ),
  ];
  /// Deterministically picks a palette for a card so the same card
  /// always renders with the same look across rebuilds.
  static CreditCardPalette paletteFor(String seed) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return creditCardPalettes[hash % creditCardPalettes.length];
  }
}

/// A cohesive gradient + accent pairing used to render a single
/// credit card in a distinct, premium style.
class CreditCardPalette {
  final String name;
  final List<Color> gradient;
  final Color accent;
  final Color glow;

  const CreditCardPalette({
    required this.name,
    required this.gradient,
    required this.accent,
    required this.glow,
  });
}