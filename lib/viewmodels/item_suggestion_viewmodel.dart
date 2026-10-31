import 'package:flutter/foundation.dart';

import '../firebase/platform_support.dart';
import '../models/budget_group.dart';
import '../models/item_suggestion.dart';
import '../models/owned_item.dart';
import '../models/purchase_item.dart';
import '../models/wishlist_item.dart';
import '../models/wishlist_status.dart';
import '../services/ai_suggestion_service.dart';
import '../services/preferences_service.dart';
import '../services/remote_config_service.dart';

/// Suggestions while adding or deciding on an item (spec AI features 3 and 4):
/// a budget group for the title, and things already bought or considered that look
/// like the same kind of item. Code answers first; AI is asked only when code cannot
/// tell, and every failure simply means "no suggestion". Nothing is applied without a tap.
class ItemSuggestionViewModel extends ChangeNotifier {
  final AiSuggestionService aiSuggestionService;
  final RemoteConfigService remoteConfigService;
  final PreferencesService preferencesService;
  final bool Function() _platformSupportsAi;
  final DateTime Function() _now;

  /// Spec: purchases from the last 30 days count as "đã có"
  static const int recentDays = 30;
  static const int maxShown = 3;

  /// Food and drinks are used up; buying them again is not a duplicate
  static const String consumableGroupId = 'food';

  List<PurchaseItem> _purchases = const [];
  List<WishlistItem> _wishlistItems = const [];
  List<OwnedItem> _ownedItems = const [];

  ItemSuggestionViewModel({
    required this.aiSuggestionService,
    required this.remoteConfigService,
    required this.preferencesService,
    bool Function()? platformSupportsAi,
    DateTime Function()? now,
  }) : _platformSupportsAi =
           platformSupportsAi ?? (() => PlatformSupport.supportsFirebaseAi),
       _now = now ?? DateTime.now;

  /// Fed by the ProxyProvider; read on demand, so nothing is redrawn
  void updateSources({
    required List<PurchaseItem> purchases,
    required List<WishlistItem> wishlistItems,
    List<OwnedItem> ownedItems = const [],
  }) {
    _purchases = purchases;
    _wishlistItems = wishlistItems;
    _ownedItems = ownedItems;
  }

  /// Same switches as Góc nhìn: platform, Remote Config and the user's AI setting
  Future<bool> _aiAllowed() async =>
      _platformSupportsAi() &&
      remoteConfigService.enableAiSuggestions &&
      await preferencesService.getAiInsightEnabled();

  Future<GroupSuggestion?> suggestGroup(
    String title,
    List<BudgetGroup> groups,
  ) async {
    final normalized = normalizeTitle(title);
    if (normalized.length < 2 || groups.isEmpty) return null;
    final ids = {for (final g in groups) g.id};
    final guessed = guessBudgetGroup(title);
    if (guessed != null && ids.contains(guessed)) {
      return GroupSuggestion(groupId: guessed, fromAi: false);
    }
    if (normalized.length < 3 || !await _aiAllowed()) return null;
    try {
      final id = await aiSuggestionService.suggestGroup(title, groups);
      return id == null || id == BudgetGroup.otherId
          ? null
          : GroupSuggestion(groupId: id, fromAi: true);
    } catch (e) {
      debugPrint('AI group suggestion unavailable: $e');
      return null;
    }
  }

  /// At most [maxShown] matches: clear ones from code first, then AI picks
  Future<List<DuplicateMatch>> findDuplicates(
    String title, {
    String? excludeItemId,
    String? budgetGroupId,
  }) async {
    final tokens = titleTokens(title);
    if (tokens.isEmpty) return const [];
    final group = budgetGroupId ?? guessBudgetGroup(title);
    if (group == consumableGroupId) return const [];

    final likely = <DuplicateCandidate>[];
    final possible = <(DuplicateCandidate, double)>[];
    for (final c in candidates(excludeItemId: excludeItemId)) {
      final other = titleTokens(c.title);
      final sameGroup =
          group != null &&
          group != BudgetGroup.otherId &&
          c.budgetGroupId == group;
      switch (compareTitles(tokens, other, sameGroup: sameGroup)) {
        case TitleSimilarity.likely:
          likely.add(c);
        case TitleSimilarity.possible:
          possible.add((c, titleOverlap(tokens, other)));
        case TitleSimilarity.none:
          break;
      }
    }

    final matches = [
      for (final c in likely) DuplicateMatch(candidate: c, fromAi: false),
    ];
    if (possible.isNotEmpty &&
        matches.length < maxShown &&
        await _aiAllowed()) {
      possible.sort((a, b) {
        final byOverlap = b.$2.compareTo(a.$2);
        return byOverlap != 0 ? byOverlap : b.$1.date.compareTo(a.$1.date);
      });
      final ranked = [for (final p in possible) p.$1];
      try {
        final picked = await aiSuggestionService.pickDuplicates(title, ranked);
        matches.addAll([
          for (final c in ranked)
            if (picked.contains(c.id))
              DuplicateMatch(candidate: c, fromAi: true),
        ]);
      } catch (e) {
        debugPrint('AI duplicate check unavailable: $e');
      }
    }
    return matches.take(maxShown).toList();
  }

  /// Things owned (shopping profile), purchases of the last [recentDays] days and items
  /// still being considered, newest first
  @visibleForTesting
  List<DuplicateCandidate> candidates({String? excludeItemId}) {
    final since = _now().subtract(const Duration(days: recentDays));
    final list = [
      for (final p in _purchases)
        if (p.occurredAt.isAfter(since) &&
            p.budgetGroupId != consumableGroupId &&
            (excludeItemId == null || p.wishlistItemId != excludeItemId))
          DuplicateCandidate(
            id: 'purchase:${p.id}',
            title: p.title,
            source: DuplicateSource.purchase,
            date: p.occurredAt,
            budgetGroupId: p.budgetGroupId,
            amountVnd: p.amountVnd,
          ),
      for (final w in _wishlistItems)
        if (w.status == WishlistStatus.considering &&
            w.id != excludeItemId &&
            w.budgetGroupId != consumableGroupId)
          DuplicateCandidate(
            id: 'wishlist:${w.id}',
            title: w.title,
            source: DuplicateSource.wishlist,
            date: w.createdAt,
            budgetGroupId: w.budgetGroupId,
            amountVnd: w.latestPriceVnd,
          ),
      for (final o in _ownedItems)
        if (o.budgetGroupId != consumableGroupId)
          DuplicateCandidate(
            id: 'owned:${o.id}',
            title: o.name,
            source: DuplicateSource.owned,
            date: o.createdAt,
            budgetGroupId: o.budgetGroupId,
          ),
    ];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
