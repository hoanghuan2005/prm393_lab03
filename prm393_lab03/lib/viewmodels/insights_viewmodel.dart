import 'package:flutter/foundation.dart';

import '../firebase/platform_support.dart';
import '../models/purchase_item.dart';
import '../models/spending_insight.dart';
import '../models/wishlist_item.dart';
import '../services/ai_insight_service.dart';
import '../services/crashlytics_service.dart';
import '../services/preferences_service.dart';
import '../services/remote_config_service.dart';

/// Why the screen is showing template sentences instead of AI wording
enum InsightFallbackReason {
  notEnoughData,
  userTurnedOff,
  disabledRemotely,
  unsupportedPlatform,
  aiFailed,
}

/// ViewModel for Góc nhìn (08) and Chiêm nghiệm tháng (09).
/// Stats are always computed locally; AI wording is requested only while the screen is visible.
class InsightsViewModel extends ChangeNotifier {
  final AiInsightService aiInsightService;
  final RemoteConfigService remoteConfigService;
  final PreferencesService preferencesService;
  final CrashlyticsService crashlyticsService;

  MonthlySpendingStats? _stats;
  InsightReport? _report;
  String? _reportKey;
  InsightFallbackReason? _fallbackReason;
  bool _isGenerating = false;
  bool _userAiEnabled = true;
  bool _isVisible = false;
  bool _disposed = false;

  InsightsViewModel({
    required this.aiInsightService,
    required this.remoteConfigService,
    required this.preferencesService,
    required this.crashlyticsService,
  }) {
    _loadPreference();
  }

  MonthlySpendingStats? get stats => _stats;
  bool get isGenerating => _isGenerating;
  bool get userAiEnabled => _userAiEnabled;
  InsightFallbackReason? get fallbackReason =>
      _reportKey == _stats?.cacheKey ? _fallbackReason : null;

  /// AI can be toggled by the user only when the platform and remote flag allow it
  bool get canToggleAi =>
      PlatformSupport.supportsFirebaseAi && remoteConfigService.enableAiInsight;

  /// Report for the current data; template sentences until AI wording arrives
  InsightReport? get report {
    final stats = _stats;
    if (stats == null) return null;
    if (_report != null && _reportKey == stats.cacheKey) return _report;
    return aiInsightService.buildTemplateReport(stats);
  }

  Future<void> _loadPreference() async {
    _userAiEnabled = await preferencesService.getAiInsightEnabled();
    if (_isVisible) await refresh(force: true);
  }

  /// Called from the ProxyProvider whenever purchases, wishlist or the selected month change.
  /// Runs during build, so it never notifies synchronously.
  void updateSources({
    required List<PurchaseItem> purchases,
    required List<WishlistItem> wishlistItems,
    required DateTime month,
  }) {
    final next = MonthlySpendingStats.compute(
      month: month,
      purchases: purchases,
      wishlistItems: wishlistItems,
    );
    if (next.cacheKey == _stats?.cacheKey) return;
    _stats = next;
    if (_isVisible) Future.microtask(refresh);
  }

  /// Góc nhìn tab shown/hidden; AI is only called for data the user is looking at
  void setVisible(bool visible) {
    if (_isVisible == visible) return;
    _isVisible = visible;
    if (visible) Future.microtask(refresh);
  }

  Future<void> setUserAiEnabled(bool enabled) async {
    _userAiEnabled = enabled;
    _notify();
    await preferencesService.setAiInsightEnabled(enabled);
    await refresh(force: true);
  }

  InsightFallbackReason? _blockingReason(MonthlySpendingStats stats) {
    if (!PlatformSupport.supportsFirebaseAi) {
      return InsightFallbackReason.unsupportedPlatform;
    }
    if (!remoteConfigService.enableAiInsight) {
      return InsightFallbackReason.disabledRemotely;
    }
    if (!_userAiEnabled) return InsightFallbackReason.userTurnedOff;
    if (!stats.hasEnoughDataForAi) return InsightFallbackReason.notEnoughData;
    return null;
  }

  /// Requests AI wording for the current month. [force] retries even if this data was already handled.
  Future<void> refresh({bool force = false}) async {
    final stats = _stats;
    if (stats == null || _disposed) return;
    final key = stats.cacheKey;
    if (_isGenerating || (!force && _reportKey == key)) return;

    final blocked = _blockingReason(stats);
    if (blocked != null) {
      _report = aiInsightService.buildTemplateReport(stats);
      _fallbackReason = blocked;
      _reportKey = key;
      _notify();
      return;
    }

    _isGenerating = true;
    _notify();

    InsightReport result;
    InsightFallbackReason? reason;
    try {
      result = await aiInsightService.generate(stats);
      if (result.source == InsightSource.template) {
        reason = InsightFallbackReason.aiFailed;
      }
    } catch (e, stack) {
      result = aiInsightService.buildTemplateReport(stats);
      reason = InsightFallbackReason.aiFailed;
      await crashlyticsService.recordHandledError(
        e,
        stack,
        reason: 'AI insight generation failed',
      );
    }

    _isGenerating = false;
    _report = result;
    _fallbackReason = reason;
    _reportKey = key;
    _notify();

    // Data changed while the request was in flight
    if (_isVisible && _stats?.cacheKey != key) await refresh();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
