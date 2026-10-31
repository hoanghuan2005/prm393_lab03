import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';
import 'item_suggestion.dart';

/// users/{uid}/ownedItems/{id} – "Đồ đang dùng" in the shopping profile (spec 7.2, A-12).
/// Entered by the user; never read from a Shopee purchase history.
class OwnedItem {
  static const int nameMaxLength = 60;
  static const int noteMaxLength = 100;
  static const int maxTags = 8;

  final String id;
  final String name;
  final String? budgetGroupId;

  /// Free tags such as "tai nghe", "hệ Apple"; matched against new items
  final List<String> tags;

  /// e.g. "dùng 2 năm"
  final String? note;
  final DateTime createdAt;

  const OwnedItem({
    required this.id,
    required this.name,
    this.budgetGroupId,
    this.tags = const [],
    this.note,
    required this.createdAt,
  });

  factory OwnedItem.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final tags = data['tags'];
    return OwnedItem(
      id: doc.id,
      name: readText(data['name']) ?? 'Đồ chưa đặt tên',
      budgetGroupId: readText(data['budgetGroupId']),
      tags: tags is List
          ? [
              for (final t in tags)
                if (t is String) t,
            ]
          : const [],
      note: readText(data['note']),
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'budgetGroupId': budgetGroupId,
    'tags': tags,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// "AirPods (dùng 2 năm)"
  String get label => note == null ? name : '$name ($note)';

  /// Spec 7.2: same budget group, or one of its tags (or its name) appears in [title]
  bool matches({required String title, String? budgetGroupId}) {
    if (budgetGroupId != null && budgetGroupId == this.budgetGroupId) {
      return true;
    }
    final padded = ' ${normalizeTitle(title)} ';
    return [name, ...tags].any((t) {
      final phrase = normalizeTitle(t);
      return phrase.length >= 2 && padded.contains(' $phrase ');
    });
  }

  /// "tai nghe, hệ Apple" → ["tai nghe", "hệ Apple"]; blanks and duplicates dropped
  static List<String> parseTags(String text) {
    final seen = <String>{};
    return [
      for (final t in text.split(','))
        if (t.trim().isNotEmpty && seen.add(normalizeTitle(t))) t.trim(),
    ].take(maxTags).toList();
  }
}

/// Style and favourite brands, stored on users/{uid} (spec 7.2). Tags only, all optional.
class ShoppingTags {
  final List<String> styles;
  final List<String> brands;

  const ShoppingTags({this.styles = const [], this.brands = const []});

  static List<String> _list(Object? value) => value is List
      ? [
          for (final v in value)
            if (v is String) v,
        ]
      : const [];

  factory ShoppingTags.fromMap(Map<String, dynamic> data) => ShoppingTags(
    styles: _list(data['shoppingStyles']),
    brands: _list(data['favoriteBrands']),
  );

  Map<String, dynamic> toMap() => {
    'shoppingStyles': styles,
    'favoriteBrands': brands,
  };
}
