import 'package:flutter/material.dart';

/// Floating snack bar shown for 5 seconds with a "Hoàn tác" action
void showUndoSnackBar(
  BuildContext context,
  String message,
  VoidCallback onUndo,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Hoàn tác', onPressed: onUndo),
      ),
    );
}
