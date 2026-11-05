import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/data/mock_admin_data.dart';
import 'package:prm393_flutter_admin/screens/ai_assistant_screen.dart';
import 'package:prm393_flutter_admin/services/admin_ai_service.dart';
import 'package:prm393_flutter_admin/services/admin_service.dart';
import 'package:provider/provider.dart';

String _reply({
  String question = 'Điều gì khiến bạn muốn có món này vào lúc này?',
  String title = 'Bạn đang cân nhắc món nào?',
  String body = 'Ghi lại vì sao bạn muốn có nó trước khi quyết định.',
  String category = 'dormant',
}) => jsonEncode({
  'question': question,
  'insight': 'Nhiều người cài app nhưng chưa lưu món nào.',
  'title': title,
  'body': body,
  'category': category,
  'screen': 'wishlist_add',
});

void main() {
  final metrics = MockAdminData.defaultMetrics;

  test('the prompt only holds aggregate numbers, no user data', () {
    final prompt = AdminAiService.buildPrompt('Trà sữa mỗi ngày', metrics);
    expect(prompt, contains('"caiAppChuaDung":${metrics.dormantUsers}'));
    for (final user in MockAdminData.defaultUsers) {
      expect(prompt, isNot(contains(user.email)));
      expect(prompt, isNot(contains(user.uid)));
      expect(prompt, isNot(contains(user.displayName)));
    }
  });

  test('a valid reply becomes an AI suggestion', () async {
    final ai = AdminAiService(generator: (model, prompt) async => _reply());
    final result = await ai.suggest('Trà sữa', metrics);
    expect(result.fromAi, isTrue);
    expect(result.suggestion.category, 'dormant');
    expect(result.suggestion.targetScreen, 'wishlist_add');
  });

  test(
    'advice, numbers, overlong text or broken JSON fall back to the template',
    () {
      expect(
        AdminAiService.parse(_reply(body: 'Bạn nên mua ngay hôm nay.'), 't'),
        isNull,
      );
      expect(
        AdminAiService.parse(_reply(title: 'Giảm 50% hôm nay'), 't'),
        isNull,
      );
      expect(AdminAiService.parse(_reply(body: 'a' * 181), 't'), isNull);
      expect(AdminAiService.parse('{not json', 't'), isNull);
      // The insight may only quote numbers that were sent
      final quoted = jsonEncode({
        ...jsonDecode(_reply()) as Map,
        'insight': 'Có 176 người cài app chưa dùng.',
      });
      final invented = jsonEncode({
        ...jsonDecode(_reply()) as Map,
        'insight': 'Tương tác tăng 42%.',
      });
      expect(
        AdminAiService.parse(quoted, 't', allowedNumbers: {176}),
        isNotNull,
      );
      expect(
        AdminAiService.parse(invented, 't', allowedNumbers: {176}),
        isNull,
      );
      // An unknown category is not trusted
      expect(
        AdminAiService.parse(_reply(category: 'vip'), 't')!.category,
        'all',
      );
    },
  );

  test('an AI error gives the template and says why', () async {
    final ai = AdminAiService(
      generator: (model, prompt) async => throw Exception('Failed to fetch'),
    );
    final result = await ai.suggest('Trà sữa', metrics);
    expect(result.fromAi, isFalse);
    expect(result.suggestion.id, 'template_custom');
    expect(result.fallbackReason, 'Không kết nối được tới AI.');
  });

  Future<void> pumpScreen(WidgetTester tester, AdminAiService ai) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminService(),
        child: MaterialApp(
          home: Scaffold(body: AiAssistantScreen(aiService: ai)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Trà sữa mỗi ngày');
    await tester.tap(find.text('Tạo Gợi Ý Thông Minh'));
    await tester.pumpAndSettle();
  }

  testWidgets('the screen labels AI output and the model', (tester) async {
    await pumpScreen(
      tester,
      AdminAiService(generator: (m, p) async => _reply()),
    );
    expect(find.text('AI · ${AdminAiService.defaultModel}'), findsOneWidget);
    expect(
      find.text('"Điều gì khiến bạn muốn có món này vào lúc này?"'),
      findsOneWidget,
    );
    expect(
      find.textContaining('sửa tiêu đề, nội dung ở tab Push'),
      findsOneWidget,
    );
    expect(find.text('Gemini 1.5 Flash'), findsNothing);
  });

  testWidgets('the screen says when it shows the template', (tester) async {
    await pumpScreen(
      tester,
      AdminAiService(
        generator: (m, p) async => throw Exception('quota exceeded'),
      ),
    );
    expect(find.text('CÂU MẪU (AI KHÔNG DÙNG ĐƯỢC)'), findsOneWidget);
    expect(find.text('AI đã hết lượt dùng.'), findsOneWidget);
  });
}
