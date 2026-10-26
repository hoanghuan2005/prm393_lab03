import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_fields.dart';

/// Embedded map `settings` inside users/{uid}
class UserSettings {
  final int coolingOffDays;

  /// Hour of day (0–23) for the review reminder
  final int reminderHour;
  final bool notificationsEnabled;

  const UserSettings({
    this.coolingOffDays = 3,
    this.reminderHour = 20,
    this.notificationsEnabled = true,
  });

  factory UserSettings.fromMap(Map<String, dynamic>? data) {
    const defaults = UserSettings();
    if (data == null) return defaults;
    return UserSettings(
      coolingOffDays:
          readInt(data['coolingOffDays']) ?? defaults.coolingOffDays,
      reminderHour: (readInt(data['reminderHour']) ?? defaults.reminderHour)
          .clamp(0, 23),
      notificationsEnabled: data['notificationsEnabled'] is bool
          ? data['notificationsEnabled'] as bool
          : defaults.notificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
    'coolingOffDays': coolingOffDays,
    'reminderHour': reminderHour,
    'notificationsEnabled': notificationsEnabled,
  };

  UserSettings copyWith({
    int? coolingOffDays,
    int? reminderHour,
    bool? notificationsEnabled,
  }) {
    return UserSettings(
      coolingOffDays: coolingOffDays ?? this.coolingOffDays,
      reminderHour: reminderHour ?? this.reminderHour,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          other.coolingOffDays == coolingOffDays &&
          other.reminderHour == reminderHour &&
          other.notificationsEnabled == notificationsEnabled;

  @override
  int get hashCode =>
      Object.hash(coolingOffDays, reminderHour, notificationsEnabled);
}

/// users/{uid} — document id is the Firebase Auth uid
class UserProfile {
  final String uid;
  final String? displayName;
  final bool isAnonymous;
  final DateTime? createdAt;
  final UserSettings settings;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.isAnonymous = false,
    this.createdAt,
    this.settings = const UserSettings(),
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = docData(doc);
    final settings = data['settings'];
    return UserProfile(
      uid: doc.id,
      displayName: readText(data['displayName']),
      isAnonymous: data['isAnonymous'] == true,
      createdAt: readDate(data['createdAt']),
      settings: UserSettings.fromMap(
        settings is Map<String, dynamic> ? settings : null,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'isAnonymous': isAnonymous,
    if (createdAt != null) 'createdAt': toTimestamp(createdAt),
    'settings': settings.toMap(),
  };

  UserProfile copyWith({
    String? uid,
    String? displayName,
    bool? isAnonymous,
    DateTime? createdAt,
    UserSettings? settings,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.uid == uid &&
          other.displayName == displayName &&
          other.isAnonymous == isAnonymous &&
          other.createdAt == createdAt &&
          other.settings == settings;

  @override
  int get hashCode =>
      Object.hash(uid, displayName, isAnonymous, createdAt, settings);
}
