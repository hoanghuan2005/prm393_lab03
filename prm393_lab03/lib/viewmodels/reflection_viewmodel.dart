import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/month_key.dart';
import '../models/reflection.dart';
import '../models/ui_state.dart';
import '../services/crashlytics_service.dart';
import '../services/reflection_service.dart';
import 'deferred_notify.dart';
import 'error_reporting.dart';

/// Chiêm nghiệm tháng: satisfaction rating 1–5 and a goal for next month.
/// uid comes from AuthViewModel; the month follows PurchaseViewModel's selected month.
class ReflectionViewModel extends ChangeNotifier
    with DeferredNotify, ErrorReporting {
  final ReflectionService reflectionService;
  @override
  final CrashlyticsService? crashlyticsService;

  StreamSubscription<Reflection?>? _subscription;
  StreamSubscription<Reflection?>? _goalSubscription;
  String? _goalForMonth;
  String? _uid;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  UiState<Reflection?> _state = const UiInitial();
  Reflection? _saved;
  int? _rating;
  bool _isSaving = false;
  String? _actionError;

  ReflectionViewModel({
    required this.reflectionService,
    this.crashlyticsService,
  });

  /// Message of the last failed save, for a SnackBar
  String? get actionError => _actionError;

  UiState<Reflection?> get state => _state;
  DateTime get month => _month;

  /// Next month, for "Mục tiêu cho tháng …"
  DateTime get nextMonth => DateTime(_month.year, _month.month + 1, 1);

  /// The month before, whose reflection set the goal for this one
  DateTime get previousMonth => DateTime(_month.year, _month.month - 1, 1);

  /// Goal written in the previous month's reflection ("Mục tiêu cho tháng …"),
  /// shown again during this month so the goal is looked back on. Null when none.
  String? get goalForMonth => _goalForMonth;

  Reflection? get saved => _saved;

  /// Rating currently selected on screen (starts from the saved one)
  int? get rating => _rating;
  bool get isSaving => _isSaving;

  void updateUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _subscribe();
  }

  void updateMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month, 1);
    if (normalized == _month) return;
    _month = normalized;
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = null;
    _goalSubscription?.cancel();
    _goalSubscription = null;
    _saved = null;
    _rating = null;
    _goalForMonth = null;
    final uid = _uid;
    if (uid == null) {
      _state = const UiInitial();
      notifyLater();
      return;
    }
    _goalSubscription = reflectionService
        .watch(uid, monthKey(previousMonth))
        .listen(
          (reflection) {
            if (reflection?.goal == _goalForMonth) return;
            _goalForMonth = reflection?.goal;
            notifyListeners();
          },
          // Only a reminder: the month's own reflection reports its errors
          onError: (Object _) {},
        );
    _state = const UiLoading();
    notifyLater();
    _subscription = reflectionService
        .watch(uid, monthKey(_month))
        .listen(
          (reflection) {
            _saved = reflection;
            _rating ??= reflection?.rating;
            _state = UiSuccess(reflection);
            notifyListeners();
          },
          onError: (Object error, StackTrace stack) {
            _state = UiError(
              message: messageFor(error, stack, reason: 'watchReflection'),
              onRetry: _subscribe,
            );
            notifyListeners();
          },
        );
  }

  void selectRating(int value) {
    _rating = value.clamp(1, 5);
    notifyListeners();
  }

  /// Back to the saved rating: the screen was left with "Bỏ thay đổi". This
  /// ViewModel outlives the screen, so the unsaved choice would otherwise come back.
  void discardChanges() {
    if (_rating == _saved?.rating) return;
    _rating = _saved?.rating;
    notifyListeners();
  }

  /// Saves rating + goal; false when nothing is selected or the write failed
  Future<bool> save(String goal) async {
    final uid = _uid;
    final rating = _rating;
    if (uid == null || rating == null) return false;
    final trimmed = goal.trim();
    _isSaving = true;
    notifyListeners();
    try {
      await reflectionService.save(
        uid,
        Reflection(
          month: monthKey(_month),
          rating: rating,
          goal: trimmed.isEmpty
              ? null
              : trimmed.substring(
                  0,
                  trimmed.length.clamp(0, AppConstants.noteMaxLength),
                ),
        ),
      );
      _actionError = null;
      return true;
    } catch (e, stack) {
      _actionError = messageFor(e, stack, reason: 'saveReflection');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _goalSubscription?.cancel();
    super.dispose();
  }
}
