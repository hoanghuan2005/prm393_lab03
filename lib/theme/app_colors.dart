import 'package:flutter/material.dart';

/// Centralized Color Tokens extracted from Figma "Why I Buy ver2"
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFFFFDE02); // Figma #FFDE02 Bright Yellow
  static const Color primaryContainer = Color(
    0xFFFFFCE6,
  ); // Figma #FFFCE6 Light Yellow
  static const Color onPrimary = Color(
    0xFF070E20,
  ); // Figma #070E20 Dark Navy/Black

  // Neutral Background & Surfaces
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color outline = Color(0xFFD1D5DB);

  // Text Colors
  static const Color textPrimary = Color(0xFF070E20);
  static const Color textSecondary = Color(0xFF6D6E73);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // 8 Motive Chip Colors (Why I Buy Core Feature)
  static const Color motiveNeed = Color(0xFF4F46E5); // Nhu cầu
  static const Color motiveNeedBg = Color(0xFFEEF2FF);

  static const Color motiveWant = Color(0xFFEC4899); // Mong muốn
  static const Color motiveWantBg = Color(0xFFFCE7F3);

  static const Color motiveSale = Color(0xFFD97706); // Khuyến mãi / Sale
  static const Color motiveSaleBg = Color(0xFFFEF3C7);

  static const Color motiveEmotion = Color(
    0xFF7C3AED,
  ); // Cảm xúc (Trigger Cooldown 3 days)
  static const Color motiveEmotionBg = Color(0xFFEDE9FE);

  static const Color motiveSocial = Color(0xFF0284C7); // MXH / Trend / FOMO
  static const Color motiveSocialBg = Color(0xFFE0F2FE);

  static const Color motiveConvenience = Color(0xFF0D9488); // Tiện lợi
  static const Color motiveConvenienceBg = Color(0xFFCCFBF1);

  static const Color motiveAds = Color(0xFF2563EB); // Quảng cáo
  static const Color motiveAdsBg = Color(0xFFDBEAFE);

  static const Color motiveOther = Color(0xFF64748B); // Khác
  static const Color motiveOtherBg = Color(0xFFF1F5F9);
}
