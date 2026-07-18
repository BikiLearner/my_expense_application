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
  // ============================================================
  static const creditPrimary = Color(0xFF1B2A4A);   // Deep navy
  static const creditDark = Color(0xFF0F1B33);       // Near-black navy
  static const creditLight = Color(0xFF6C8CC7);      // Soft steel blue

  static const creditSurface = Color(0xFF15192B);    // Screen background tint
  static const creditCard = Color(0xFF1C2340);        // Card surface fallback
  static const creditBorder = Color(0x33D4AF37);      // Faint gold hairline

  // Banner / FAB gradient
  static const creditGradientStart = Color(0xFF0F1B33);
  static const creditGradientEnd = Color(0xFF2A4270);

  // Accent
  static const creditAccent = Color(0xFFD4AF37);      // Champagne gold
  static const creditSoft = Color(0xFF8FE3C7);        // Mint (active/success glow)

  // Status
  static const creditDue = Color(0xFFEF4444);         // Red
  static const creditPaid = Color(0xFF22C55E);        // Green
  static const creditEMI = Color(0xFFF59E0B);         // Amber
  static const creditLimit = Color(0xFF38BDF8);       // Sky Blue

  // ------------------------------------------------------------
  // Rotating premium card palettes — used so each credit card in
  // the list gets a distinct, bank-card-like look instead of one
  // repeated flat gradient.
  // ------------------------------------------------------------
  static const List<CreditCardPalette> creditCardPalettes = [
    CreditCardPalette(
      name: 'Sapphire Nights',
      gradient: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      accent: Color(0xFFF5C542), // gold chip
      glow: Color(0xFF2C5364),
    ),
    CreditCardPalette(
      name: 'Emerald Executive',
      gradient: [Color(0xFF07332B), Color(0xFF0B5D45), Color(0xFF117A5D)],
      accent: Color(0xFFD4AF37),
      glow: Color(0xFF0B5D45),
    ),
    CreditCardPalette(
      name: 'Midnight Gold',
      gradient: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      accent: Color(0xFFFFD700),
      glow: Color(0xFF302B63),
    ),
    CreditCardPalette(
      name: 'Graphite Platinum',
      gradient: [Color(0xFF232526), Color(0xFF3A3D40), Color(0xFF1C1C1C)],
      accent: Color(0xFFE5E5E5),
      glow: Color(0xFF3A3D40),
    ),
    CreditCardPalette(
      name: 'Velvet Wine',
      gradient: [Color(0xFF2B0B1E), Color(0xFF5C1A3B), Color(0xFF3A1029)],
      accent: Color(0xFFE8B4B8),
      glow: Color(0xFF5C1A3B),
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