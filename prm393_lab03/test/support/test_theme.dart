import 'package:flutter/material.dart';
import 'package:prm393_lab03/theme/app_theme.dart';

/// Run the existing UI flows in either palette without changing their assertions:
/// flutter test --dart-define=TEST_DARK_THEME=true
ThemeData get testAppTheme => const bool.fromEnvironment('TEST_DARK_THEME')
    ? AppTheme.darkTheme
    : AppTheme.lightTheme;
