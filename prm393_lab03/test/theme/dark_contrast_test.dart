import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/contrast.dart';
import 'package:prm393_lab03/models/buying_motive.dart';
import 'package:prm393_lab03/theme/app_colors.dart';
import 'package:prm393_lab03/theme/app_semantic_colors.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/theme/motive_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late final theme = AppTheme.darkTheme;
  late final c = AppSemanticColors.fromTheme(theme);

  testWidgets(
    'dark text, hints and navigation remain readable on every neutral surface',
    (tester) async {
      final backgrounds = [c.background, c.cardSurface, c.mutedSurface];
      final foregrounds = {
        'primary': c.textPrimary,
        'body': c.textBody,
        'secondary': c.textSecondary,
        'hint': c.hint,
        'subtle': c.subtleText,
        'caption': c.captionText,
        'scheme error': theme.colorScheme.error,
        'nav': c.navInactive,
        'accent': c.accent,
        'emphasis': c.emphasis,
        'error': c.error,
        'info': c.info,
        'success': c.success,
        'warning': c.warning,
      };
      for (final fg in foregrounds.entries) {
        for (final bg in backgrounds) {
          expect(
            contrastRatio(fg.value, bg),
            greaterThanOrEqualTo(4.5),
            reason: '${fg.key} on $bg',
          );
        }
      }
      expect(theme.textTheme.bodyMedium!.color, AppColors.darkTextBody);
    },
  );

  testWidgets('container text and selected chips use the matching on-colour', (
    tester,
  ) async {
    final pairs = {
      'primary': (c.onPrimaryContainer, c.primaryContainer),
      'AI': (c.onAiContainer, c.aiContainer),
      'AI body': (c.aiBody, c.aiContainer),
      'success': (c.onSuccessContainer, c.successContainer),
      'error': (c.onErrorContainer, c.errorContainer),
      'info': (c.onInfoContainer, c.infoContainer),
      'warning': (c.onWarningContainer, c.warningContainer),
      'selected': (c.onSelectedChip, c.selectedChip),
      'success snackbar': (c.onSnackbarSuccess, c.snackbarSuccess),
      'notification': (c.onNotificationBadge, c.notificationBadge),
      'shopee button': (c.onBrandButton, c.shopeeBrand),
      'lazada button': (c.onBrandButton, c.lazadaBrand),
      'purchase button': (c.onStatusFill, c.success),
      'danger button': (c.onStatusFill, c.error),
    };
    for (final p in pairs.entries) {
      expect(
        contrastRatio(p.value.$1, p.value.$2),
        greaterThanOrEqualTo(4.5),
        reason: p.key,
      );
    }
    for (final m in BuyingMotive.values) {
      final palette = MotiveColors.dark.paletteOf(m);
      expect(
        contrastRatio(palette.foreground, palette.background),
        greaterThanOrEqualTo(4.5),
        reason: 'unselected ${m.name}',
      );
      expect(
        contrastRatio(c.onSelectedChip, palette.foreground),
        greaterThanOrEqualTo(4.5),
        reason: 'selected ${m.name}',
      );
    }
  });

  testWidgets(
    'inputs, cards, charts and Material component states have visible contrast',
    (tester) async {
      final input = theme.inputDecorationTheme;
      for (final b in [
        input.border,
        input.enabledBorder,
        input.focusedBorder,
        input.errorBorder,
      ]) {
        expect(
          contrastRatio(b!.borderSide.color, input.fillColor!),
          greaterThanOrEqualTo(3),
        );
      }
      expect(
        contrastRatio(c.cardBorder, c.cardSurface),
        greaterThanOrEqualTo(1.5),
      );
      expect(
        contrastRatio(c.cardSurface, c.background),
        greaterThanOrEqualTo(1.4),
      );
      expect(AppColors.darkCardSurface, AppColors.darkSurface);
      expect(AppColors.darkBorder, isNot(AppColors.darkSurfaceVariant));
      expect(
        contrastRatio(c.chartLine, c.cardSurface),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrastRatio(c.chartLowest, c.cardSurface),
        greaterThanOrEqualTo(3),
      );
      // The AI card overrides Switch colours; test the actual thumb/track pair too.
      expect(
        contrastRatio(AppColors.primary, c.switchTrack),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrastRatio(c.switchTrack, c.aiContainer),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrastRatio(
          theme.snackBarTheme.contentTextStyle!.color!,
          theme.snackBarTheme.backgroundColor!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      for (final states in [
        <WidgetState>{},
        {WidgetState.selected},
      ]) {
        final picker = theme.datePickerTheme;
        final dayBg = Color.alphaBlend(
          picker.dayBackgroundColor!.resolve(states)!,
          c.cardSurface,
        );
        expect(
          contrastRatio(picker.dayForegroundColor!.resolve(states)!, dayBg),
          greaterThanOrEqualTo(4.5),
        );
        final chipStyle = theme.chipTheme.labelStyle! as WidgetStateTextStyle;
        expect(
          contrastRatio(
            chipStyle.resolve(states).color!,
            states.isEmpty
                ? theme.chipTheme.backgroundColor!
                : theme.chipTheme.selectedColor!,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  testWidgets(
    'light palette and component colours retain their pre-migration values',
    (tester) async {
      final light = AppTheme.lightTheme;
      final c = AppSemanticColors.fromTheme(light);
      expect(light.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(light.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(light.colorScheme.primary, const Color(0xFFFFDE02));
      expect(light.colorScheme.onSurface, const Color(0xFF0F172A));
      expect(light.colorScheme.onSurfaceVariant, const Color(0xFF64748B));
      expect(
        light.inputDecorationTheme.enabledBorder!.borderSide.color,
        const Color(0xFFE2E8F0),
      );
      expect(
        light.inputDecorationTheme.hintStyle!.color,
        const Color(0xFF94A3B8),
      );
      expect(c.cardSurface, const Color(0xFFFFFFFF));
      expect(c.mutedSurface, const Color(0xFFF1F5F9));
      expect(c.onSelectedChip, const Color(0xFFFFFFFF));
      expect(c.onSuccessContainer, const Color(0xFF059669));
      expect(c.chartLine, const Color(0xFFA855F7));
      expect(c.onboardingGradientStart, const Color(0xFFFFF3B0));
      expect(c.onboardingGradientEnd, const Color(0xFFF1F6F2));
      expect(c.onboardingBorder, const Color(0xFFE8EDF2));
    },
  );

  test(
    'screens/widgets contain no hex colours or local dark colour branches',
    () {
      for (final directory in ['lib/screens', 'lib/widgets']) {
        for (final f in Directory(
          directory,
        ).listSync(recursive: true).whereType<File>()) {
          if (!f.path.endsWith('.dart')) continue;
          final source = f.readAsStringSync();
          expect(
            RegExp(r'Color\(0x').hasMatch(source),
            isFalse,
            reason: f.path,
          );
          if (!f.path.endsWith('profile_screen.dart')) {
            expect(
              RegExp(r'Brightness\.dark|\bisDark\b').hasMatch(source),
              isFalse,
              reason: f.path,
            );
          }
        }
      }
    },
  );
}
