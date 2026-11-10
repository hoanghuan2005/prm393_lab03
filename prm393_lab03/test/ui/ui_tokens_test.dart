import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/theme/app_colors.dart';
import 'package:prm393_lab03/theme/app_dimens.dart';
import 'package:prm393_lab03/theme/app_text_styles.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/widgets/app_header_actions.dart';

void main() {
  test(
    'typography tokens can inherit foreground without changing font size',
    () {
      final token = AppTextStyles.bodyLarge;
      final inherited = token.withInheritedColor;
      expect(inherited.color, isNull);
      expect(inherited.fontSize, token.fontSize);
      expect(inherited.fontFamily, token.fontFamily);
      expect(inherited.height, token.height);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'button foreground and profile target ${dark ? 'dark' : 'light'}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(actions: [AppHeaderActions(onProfileTap: () {})]),
              body: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () {},
                child: Text(
                  'Thao tác',
                  style: AppTextStyles.bodyLarge.withInheritedColor,
                ),
              ),
            ),
          ),
        );
        final text = tester.renderObject<RenderParagraph>(
          find.text('Thao tác'),
        );
        expect(text.text.style?.color, AppColors.onPrimary);
        final target = find.descendant(
          of: find.byTooltip('Cá nhân'),
          matching: find.byType(InkWell),
        );
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(AppDimens.minTouchTarget));
        expect(size.height, greaterThanOrEqualTo(AppDimens.minTouchTarget));
      },
    );
  }
}
