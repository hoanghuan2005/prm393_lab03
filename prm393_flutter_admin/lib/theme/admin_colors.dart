import 'package:flutter/material.dart';

/// Centralized Color System for Flutter Web Admin Portal
/// Supports dynamic switching between Dark Mode and Light Mode
class AdminColors {
  AdminColors._();

  static bool isDark = true;

  // Background & Surfaces
  static Color get background => isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC); // slate-950 / slate-50
  static Color get sidebar => isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF); // slate-900 / white
  static Color get surface => isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF); // slate-900 / white
  static Color get surfaceLight => isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9); // slate-800 / slate-100
  static Color get border => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0); // slate-800 / slate-200
  static Color get borderSubtle => isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1); // slate-700 / slate-300

  // Brand Accents
  static const Color primary = Color(0xFFFBBF24); // Tailwind amber-400
  static const Color primaryLight = Color(0xFFFCD34D); // Tailwind amber-300
  static const Color onPrimary = Color(0xFF0F172A); // slate-900

  // Status & Metrics Accents
  static const Color emerald = Color(0xFF10B981);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFFA855F7);
  static const Color rose = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);

  // Text Colors
  static Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A); // slate-50 / slate-900
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B); // slate-400 / slate-500
  static Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8); // slate-500 / slate-400
}
