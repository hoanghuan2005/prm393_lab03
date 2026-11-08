import 'package:flutter/foundation.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../services/admin_ai_service.dart';
import 'safe_notifier.dart';

/// "Trợ lý AI": a topic → Gemini writes a self-reflection question and a
/// message draft from aggregate numbers only. The draft is never sent from
/// here: it goes to the announcement form to be read and edited first.
class AiAssistantViewModel extends ChangeNotifier with SafeNotifier {
  static const List<String> topicIdeas = [
    'Người cài app nhưng chưa thêm món nào',
    'Mua đồ công nghệ mùa sale 11.11',
    'Trà sữa mỗi ngày',
    'Mua sắm lúc khuya',
  ];

  final AdminAiService _ai;
  final Future<AdminAiMetrics> Function() _metrics;

  UiState<AdminAiResult> _state = const UiInitial();
  String? _lastTopic;

  AiAssistantViewModel(this._ai, this._metrics);

  UiState<AdminAiResult> get state => _state;
  bool get isLoading => _state is UiLoading;
  String get model => _ai.model;
  String? get lastTopic => _lastTopic;

  static String? validateTopic(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return 'Nhập một chủ đề, ví dụ "Trà sữa mỗi ngày"';
    if (t.length > 120) return 'Tối đa 120 ký tự';
    return null;
  }

  /// Always ends with a result: AI output, or the team's template with the reason
  Future<void> suggest(String topic) async {
    if (validateTopic(topic) != null || isLoading) return;
    _lastTopic = topic.trim();
    _state = const UiLoading();
    notifySafely();
    final metrics = await _metrics();
    final result = await _ai.suggest(topic, metrics);
    _state = UiSuccess(result);
    notifySafely();
  }
}
