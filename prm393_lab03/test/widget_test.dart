import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/widgets/states/empty_view.dart';
import 'package:prm393_lab03/widgets/states/error_view.dart';
import 'package:prm393_lab03/widgets/states/loading_view.dart';

void main() {
  testWidgets('Design system states smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: LoadingView(message: 'Testing Loading State'),
        ),
      ),
    );
    expect(find.text('Testing Loading State'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: EmptyView(title: 'Testing Empty State'),
        ),
      ),
    );
    expect(find.text('Testing Empty State'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ErrorView(message: 'Testing Error State'),
        ),
      ),
    );
    expect(find.text('Testing Error State'), findsOneWidget);
  });
}
