import 'package:flutter/material.dart';

/// Centralized Color Tokens extracted from Figma "Why I Buy ver2".
/// Synchronized with Admin Web Portal (Tailwind CSS) color palette.
/// Names describe the role, not the hue. Screens/widgets use only these tokens
/// (see docs/design-tokens.md).
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY BRAND COLORS
  // Web: amber-400 (#FBBF24), amber-300 (#FCD34D)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFFFBBF24); // Tailwind amber-400
  static const Color primaryLight = Color(0xFFFCD34D); // Tailwind amber-300
  static const Color primaryContainer = Color(
    0xFFFFFCE6,
  ); // Light: Soft yellow bg
  static const Color onPrimary = Color(
    0xFF0F172A,
  ); // Tailwind slate-900 (text on yellow)

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE — Neutral Background & Surfaces
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF8FAFC); // Tailwind slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Tailwind slate-100
  static const Color divider = Color(0xFFE2E8F0); // Tailwind slate-200
  static const Color border = Color(0xFFE2E8F0); // Tailwind slate-200
  static const Color outline = Color(0xFFCBD5E1); // Tailwind slate-300

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE — Text Colors
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFF0F172A); // Tailwind slate-900
  static const Color textBody = Color(0xFF334155); // Tailwind slate-700
  static const Color textSecondary = Color(0xFF64748B); // Tailwind slate-500
  static const Color textHint = Color(0xFF94A3B8); // Tailwind slate-400
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Neutral emphasis for figures, labels and the "over budget" state
  static const Color accentNeutral = Color(0xFF47667B);

  // Navigation
  static const Color navInactive = Color(0xFF94A3B8); // Tailwind slate-400

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS COLORS (Shared light/dark — Web uses same Tailwind palette)
  // emerald-500, emerald-400, amber-500, rose-500, blue-500
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981); // Tailwind emerald-500
  static const Color successLight = Color(0xFF34D399); // Tailwind emerald-400
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color onSuccessContainer = Color(0xFF059669); // emerald-600
  static const Color warning = Color(0xFFF59E0B); // Tailwind amber-500
  static const Color error = Color(0xFFEF4444); // Tailwind red-500
  static const Color errorLight = Color(0xFFF87171); // Tailwind red-400 (dark)
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFFDC2626); // red-600
  static const Color info = Color(0xFF3B82F6); // Tailwind blue-500
  static const Color infoLight = Color(0xFF60A5FA); // Tailwind blue-400 (dark)

  // Rose (Crash/alert accent)
  static const Color rose = Color(0xFFF43F5E); // Tailwind rose-500
  static const Color roseLight = Color(0xFFFB7185); // Tailwind rose-400

  // Purple (Dormant/special accent)
  static const Color purple = Color(0xFFA855F7); // Tailwind purple-500
  static const Color purpleLight = Color(0xFFC084FC); // Tailwind purple-400

  // ═══════════════════════════════════════════════════════════════════════════
  // AI-WRITTEN INSIGHT HIGHLIGHT
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color aiContainer = Color(0xFFFEF3C7); // amber-100
  static const Color aiAccent = Color(0xFFB45309); // amber-700
  static const Color onAiContainer = Color(0xFF92400E); // amber-800

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME-OF-DAY SLOTS (Thói quen chi tiêu)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color slotMorning = Color(0xFF3B82F6); // blue-500
  static const Color slotNoon = Color(0xFF10B981); // emerald-500
  static const Color slotEvening = Color(0xFFF59E0B); // amber-500
  static const Color slotNight = Color(0xFF6366F1); // indigo-500

  // Charts
  static const Color chartStrong = Color(0xFF1E293B); // Tailwind slate-800

  // ═══════════════════════════════════════════════════════════════════════════
  // 8 MOTIVE CHIP COLORS (Synced with Web motiveDistributionData)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color motiveNeed = Color(0xFF3B82F6); // blue-500 (Web: #3B82F6)
  static const Color motiveNeedBg = Color(0xFFDBEAFE); // blue-100

  static const Color motiveWant = Color(0xFFEC4899); // pink-500 (Web: #EC4899)
  static const Color motiveWantBg = Color(0xFFFCE7F3); // pink-100

  static const Color motiveSale = Color(0xFFF59E0B); // amber-500 (Web: #F59E0B)
  static const Color motiveSaleBg = Color(0xFFFEF3C7); // amber-100

  static const Color motiveEmotion = Color(
    0xFFA855F7,
  ); // purple-500 (Web: #A855F7)
  static const Color motiveEmotionBg = Color(0xFFF3E8FF); // purple-100

  static const Color motiveSocial = Color(0xFF0EA5E9); // sky-500
  static const Color motiveSocialBg = Color(0xFFE0F2FE); // sky-100

  static const Color motiveConvenience = Color(0xFF14B8A6); // teal-500
  static const Color motiveConvenienceBg = Color(0xFFCCFBF1); // teal-100

  static const Color motiveAds = Color(0xFF2563EB); // blue-600
  static const Color motiveAdsBg = Color(0xFFDBEAFE); // blue-100

  static const Color motiveOther = Color(0xFF64748B); // slate-500
  static const Color motiveOtherBg = Color(0xFFF1F5F9); // slate-100

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE COLORS (Matching Web Admin Portal Tailwind dark palette)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF020617); // slate-950
  static const Color darkSurface = Color(0xFF0F172A); // slate-900
  static const Color darkSurfaceVariant = Color(0xFF1E293B); // slate-800
  static const Color darkBorder = Color(0xFF1E293B); // slate-800
  static const Color darkOutline = Color(0xFF334155); // slate-700

  static const Color darkTextPrimary = Color(0xFFF8FAFC); // slate-50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // slate-400
  static const Color darkTextHint = Color(0xFF64748B); // slate-500
  static const Color darkTextMuted = Color(0xFF475569); // slate-600
}
