import 'package:flutter/foundation.dart';

import '../firebase/platform_support.dart';
import '../models/pre_purchase_check.dart';
import '../models/ui_state.dart';
import '../services/ai_pre_purchase_service.dart';
import '../services/preferences_service.dart';
import '../services/remote_config_service.dart';

/// Flow 9 "Trước khi mua": screen 17 (AI đang phân tích) → 18 (Nhận định).
/// Always ends in a result: the template insight when AI is off or fails.
class PrePurchaseViewModel extends ChangeNotifier {
  final AiPrePurchaseService aiService;
  final RemoteConfigService remoteConfigService;
  final PreferencesService preferencesService;
  final bool Function() _platformSupportsAi;

  /// Screen 17 stays at least this long (Figma: ~1,5 giây) so it does not flash
  final Duration minLoading;

  PrePurchaseViewModel({
    required this.aiService,
    required this.remoteConfigService,
    required this.preferencesService,
    bool Function()? platformSupportsAi,
    this.minLoading = const Duration(milliseconds: 1500),
  }) : _platformSupportsAi =
           platformSupportsAi ?? (() => PlatformSupport.supportsFirebaseAi);

  UiState<PrePurchaseInsight> _state = const UiInitial();
  UiState<PrePurchaseInsight> get state => _state;

  /// A newer analysis replaces an older one still running
  int _run = 0;

  Future<bool> _aiAllowed() async =>
      _platformSupportsAi() &&
      remoteConfigService.enableAiSuggestions &&
      await preferencesService.getAiInsightEnabled();

  /// [facts] come from the user's own data (PrePurchaseFacts); may be empty
  Future<void> analyze(
    PrePurchaseAnswers answers, {
    List<PrePurchaseFact> facts = const [],
  }) async {
    final run = ++_run;
    _state = const UiLoading();
    notifyListeners();

    final started = DateTime.now();
    var insight = PrePurchaseRules.templateInsight(answers, facts: facts);
    if (await _aiAllowed()) {
      try {
        final text = await aiService.write(answers, facts: facts);
        insight = insight.withAi(
          summary: text.summary,
          question: text.question,
        );
      } catch (e) {
        debugPrint('PrePurchase AI unavailable, using template: $e');
      }
    }

    final left = minLoading - DateTime.now().difference(started);
    if (left > Duration.zero) await Future<void>.delayed(left);
    if (run != _run) return;
    _state = UiSuccess(insight);
    notifyListeners();
  }

  /// Leaving the flow: the next visit starts clean
  void reset() {
    _run++;
    _state = const UiInitial();
  }
}
