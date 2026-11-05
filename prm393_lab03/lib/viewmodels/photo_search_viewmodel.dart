import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/describe_error.dart';
import '../firebase/platform_support.dart';
import '../models/item_recognition.dart';
import '../models/price_offer.dart';
import '../models/ui_state.dart';
import '../services/ai_photo_search_service.dart';
import '../services/ai_price_search_service.dart';
import '../services/analytics_service.dart';
import '../services/preferences_service.dart';
import '../services/remote_config_service.dart';

/// "Chụp để tìm": photo → AI names the item → search links / add to the wishlist.
/// The photo only lives in memory while the screen is open.
class PhotoSearchViewModel extends ChangeNotifier {
  final AiPhotoSearchService aiService;

  /// Optional "AI tìm giá ở các shop" (Google Search grounding, paid)
  final AiPriceSearchService? priceSearchService;
  final RemoteConfigService remoteConfigService;
  final PreferencesService preferencesService;
  final bool Function() _platformSupportsAi;
  final bool Function() _platformSupportsPriceSearch;

  /// Logs ai_result_accepted; optional so tests can leave it out
  final AppAnalyticsService? analyticsService;

  PhotoSearchViewModel({
    required this.aiService,
    this.analyticsService,
    this.priceSearchService,
    required this.remoteConfigService,
    required this.preferencesService,
    bool Function()? platformSupportsAi,
    bool Function()? platformSupportsPriceSearch,
  }) : _platformSupportsAi =
           platformSupportsAi ?? (() => PlatformSupport.supportsFirebaseAi),
       // Google's required "Search suggestions" are HTML shown in a WebView (mobile)
       _platformSupportsPriceSearch =
           platformSupportsPriceSearch ??
           (() =>
               PlatformSupport.isMobile && PlatformSupport.supportsFirebaseAi);

  /// The user took an AI result into their data ([AiFeatures])
  void aiResultAccepted(String feature) => unawaited(
    analyticsService?.logAiResultAccepted(feature: feature) ??
        Future<void>.value(),
  );

  static const String aiOffMessage =
      'Tính năng AI đang tắt hoặc chưa hỗ trợ trên thiết bị này. '
      'Bạn có thể bật lại công tắc "Dùng AI" ở màn Góc nhìn.';
  static const String failedMessage =
      'Chưa nhận diện được ảnh. Kiểm tra kết nối mạng rồi thử lại.';
  static const String notFoundMessage = 'Chưa nhận ra món đồ trong ảnh';
  static const String priceQuotaMessage =
      'AI tìm giá đang hết lượt dùng. Bạn vẫn xem được giá thấp nhất ở từng sàn bên dưới.';
  static const String priceFailedMessage =
      'Chưa tìm được giá. Kiểm tra kết nối mạng rồi thử lại.';
  static const String priceNotFoundMessage =
      'AI chưa tìm thấy nơi bán có giá rõ ràng. Thử chọn tên khác hoặc xem từng sàn bên dưới.';

  UiState<ItemRecognition> _state = const UiInitial();
  UiState<ItemRecognition> get state => _state;

  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;
  String _mimeType = 'image/jpeg';

  /// Name used for searching and for "Thêm vào danh sách cân nhắc"; the user can
  /// switch it to one of the alternatives
  String? _selectedName;
  String? get selectedName => _selectedName;

  /// A newer photo replaces an older analysis still running
  int _run = 0;

  UiState<PriceSearchResult> _priceState = const UiInitial();

  /// "AI tìm giá ở các shop" for [searchQuery]; reset when the name or photo changes
  UiState<PriceSearchResult> get priceState => _priceState;
  int _priceRun = 0;

  /// The button is shown only when the team turned grounding on (billing set up)
  bool get canSearchPrices =>
      priceSearchService != null &&
      remoteConfigService.enableAiPriceSearch &&
      _platformSupportsPriceSearch();

  Future<bool> _aiAllowed() async =>
      _platformSupportsAi() &&
      remoteConfigService.enableAiSuggestions &&
      await preferencesService.getAiInsightEnabled();

  Future<void> identify(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final run = ++_run;
    _imageBytes = bytes;
    _mimeType = mimeType;
    _selectedName = null;
    _clearPrices();
    _state = const UiLoading();
    notifyListeners();

    if (!await _aiAllowed()) {
      if (run != _run) return;
      _state = const UiError(message: aiOffMessage);
      notifyListeners();
      return;
    }

    UiState<ItemRecognition> next;
    try {
      final result = await aiService.identify(bytes, mimeType);
      next = result.isEmpty
          ? UiEmpty(
              message: notFoundMessage,
              actionTitle: 'Chụp lại',
              onAction: reset,
            )
          : UiSuccess(result);
      if (!result.isEmpty) _selectedName = result.name;
    } catch (e) {
      debugPrint('PhotoSearch AI failed: ${describeError(e)}');
      next = UiError(message: failedMessage, onRetry: retry);
    }
    if (run != _run) return;
    _state = next;
    notifyListeners();
  }

  /// Same photo again (after a network error)
  Future<void> retry() async {
    final bytes = _imageBytes;
    if (bytes != null) await identify(bytes, mimeType: _mimeType);
  }

  void selectName(String name) {
    if (_state is! UiSuccess<ItemRecognition> || name == _selectedName) return;
    _selectedName = name;
    _clearPrices();
    notifyListeners();
  }

  Future<void> searchPrices() async {
    final service = priceSearchService;
    final query = searchQuery;
    if (service == null || query == null || !canSearchPrices) return;
    if (_priceState is UiLoading<PriceSearchResult>) return;
    final run = ++_priceRun;
    _priceState = const UiLoading();
    notifyListeners();

    UiState<PriceSearchResult> next;
    if (!await _aiAllowed()) {
      next = const UiError(message: aiOffMessage);
    } else {
      try {
        final result = await service.search(query);
        next = result.isEmpty
            ? const UiEmpty(message: priceNotFoundMessage)
            : UiSuccess(result);
      } catch (e) {
        debugPrint('PhotoSearch price lookup failed: ${describeError(e)}');
        next = UiError(
          message: isQuotaError(e) ? priceQuotaMessage : priceFailedMessage,
          onRetry: searchPrices,
        );
      }
    }
    if (run != _priceRun) return;
    _priceState = next;
    notifyListeners();
  }

  /// Gemini answers "You exceeded your current quota" when grounding is not paid for
  @visibleForTesting
  static bool isQuotaError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('quota') || text.contains('resource_exhausted');
  }

  void _clearPrices() {
    _priceRun++;
    _priceState = const UiInitial();
  }

  /// Search text for the shop links, from the selected name
  String? get searchQuery {
    final s = _state;
    final name = _selectedName;
    if (s is! UiSuccess<ItemRecognition> || name == null) return null;
    // The brand only belongs to the main guess, not to the alternatives
    final brand = name == s.data.name ? s.data.brand : null;
    return ItemRecognition.searchQuery(name, brand: brand);
  }

  /// Back to "chọn ảnh"; the photo is dropped
  void reset() {
    discard();
    notifyListeners();
  }

  /// Same as [reset] without notifying: for the screen's dispose, when the widget tree
  /// is locked. Drops the photo from memory and ignores any reply still on its way.
  void discard() {
    _run++;
    _imageBytes = null;
    _selectedName = null;
    _clearPrices();
    _state = const UiInitial();
  }
}
