import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// users/{uid}/budgetGroups/{groupId}
class BudgetGroup {
  static const String otherId = 'other';

  final String id;
  final String name;
  final int order;

  const BudgetGroup({
    required this.id,
    required this.name,
    required this.order,
  });

  factory BudgetGroup.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    return BudgetGroup(
      id: doc.id,
      name: readText(data['name']) ?? doc.id,
      order: readInt(data['order']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'order': order};

  BudgetGroup copyWith({String? id, String? name, int? order}) {
    return BudgetGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetGroup &&
          other.id == id &&
          other.name == name &&
          other.order == order;

  @override
  int get hashCode => Object.hash(id, name, order);
}

/// The 6 groups every new user starts with; ids are fixed and referenced by purchases/budgets
const List<BudgetGroup> defaultBudgetGroups = [
  BudgetGroup(id: 'food', name: 'Ăn uống', order: 0),
  BudgetGroup(id: 'fashion', name: 'Thời trang', order: 1),
  BudgetGroup(id: 'tech', name: 'Công nghệ', order: 2),
  BudgetGroup(id: 'beauty', name: 'Làm đẹp', order: 3),
  BudgetGroup(id: 'study', name: 'Học tập', order: 4),
  BudgetGroup(id: BudgetGroup.otherId, name: 'Khác', order: 5),
];
