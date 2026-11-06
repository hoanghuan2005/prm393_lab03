import 'package:flutter/widgets.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

extension TokensX on BuildContext {
  /// Lab 2 tokens for the current light / dark theme
  AppTokens get tokens => AppTokens.of(this);
}
