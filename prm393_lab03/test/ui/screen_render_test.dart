import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:prm393_lab03/theme/app_theme.dart';

import 'ui_audit_harness.dart';

/// Baseline collection is opt-in. Normal runs always fail on rendering errors.
const _recordOnly = bool.fromEnvironment('UI_AUDIT_RECORD_ONLY');

void main() {
  final results = <Map<String, Object?>>[];
  tearDownAll(() {
    final file = File(
      'build/ui-audit/${_recordOnly ? 'baseline' : 'results'}.json',
    );
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
  });
  final names = UiAuditHarness(false).screens.keys;
  for (final name in names) {
    for (final width in [360.0, 412.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final dark in [false, true]) {
          for (final populated in [false, true]) {
            final size = Size(width, width == 360 ? 640 : 915);
            final label =
                '$name ${size.width.toInt()}x${size.height.toInt()} '
                'text=$scale ${dark ? 'dark' : 'light'} ${populated ? 'full' : 'empty'}';
            testWidgets(label, (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              if (name.endsWith('_keyboard')) {
                tester.view.viewInsets = const FakeViewPadding(bottom: 300);
              }
              addTearDown(tester.view.reset);
              final oldScanner = MobileScannerPlatform.instance;
              MobileScannerPlatform.instance = AuditScanner(denied: !populated);
              addTearDown(() => MobileScannerPlatform.instance = oldScanner);
              final errors = <String>{};
              final original = FlutterError.onError;
              FlutterError.onError = (details) {
                errors.add(details.toString());
              };
              final h = UiAuditHarness(populated);
              try {
                final app = await h.app(
                  name,
                  dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                  scale,
                );
                await tester.pumpWidget(app);
                await tester.pump(const Duration(milliseconds: 300));
                if (name == 'record_purchase_step2') {
                  await tester.ensureVisible(find.text('Tiếp tục'));
                  await tester.tap(find.text('Tiếp tục'));
                  await tester.pump(const Duration(milliseconds: 300));
                }
                await tester.pump(const Duration(milliseconds: 300));
                if (name == 'modal/notifications') {
                  await tester.tap(find.byTooltip('Thông báo'));
                  await tester.pump(const Duration(milliseconds: 400));
                } else if (name.startsWith('modal/') ||
                    name.startsWith('dialog/')) {
                  await tester.tap(find.text('Mở kiểm tra'));
                  await tester.pump(const Duration(milliseconds: 400));
                }
                // Lazy lists must also build the middle/end, not just the first screenful.
                for (final fraction in [1.0, 0.5, 0.0]) {
                  final scrollables = tester
                      .stateList<ScrollableState>(find.byType(Scrollable))
                      .toList();
                  for (final state in scrollables) {
                    if (state.mounted &&
                        state.position.hasContentDimensions &&
                        state.position.axis == Axis.vertical) {
                      state.position.jumpTo(
                        state.position.maxScrollExtent * fraction,
                      );
                    }
                  }
                  await tester.pump(const Duration(milliseconds: 100));
                }
                final exception = tester.takeException();
                if (exception != null) errors.add(exception.toString());
              } catch (error, stack) {
                errors.add('$error\n$stack');
              } finally {
                await tester.pumpWidget(const SizedBox.shrink());
                await tester.pump();
                h.dispose();
                FlutterError.onError = original;
              }
              results.add({
                'screen': name,
                'width': width,
                'height': size.height,
                'scale': scale,
                'theme': dark ? 'dark' : 'light',
                'data': populated ? 'full' : 'empty',
                'errors': errors.toList(),
              });
              if (!_recordOnly) expect(errors, isEmpty, reason: label);
            });
          }
        }
      }
    }
  }
}
