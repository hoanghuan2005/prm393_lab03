import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/main.dart';
import 'package:provider/provider.dart';
import 'package:prm393_flutter_admin/services/admin_service.dart';

void main() {
  testWidgets('WhyIBuyAdminApp smoke test on web screen', (WidgetTester tester) async {
    // Set web desktop screen resolution
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminService(),
        child: const WhyIBuyAdminApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Why I Buy'), findsWidgets);
    expect(find.text('Bảng Điều Khiển & Thống Kê'), findsOneWidget);
  });
}
