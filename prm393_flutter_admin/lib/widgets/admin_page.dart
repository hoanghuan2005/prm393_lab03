import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../utils/tokens.dart';

/// Page frame of the wide-screen layout: a one-line description of the page,
/// its actions, and content limited to a readable width. The page name itself
/// is in the top bar ([title] is kept for screen readers).
class AdminPage extends StatelessWidget {
  static const double maxContentWidth = 1240;

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  const AdminPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    final padding = narrow ? AppDimens.space16 : AppDimens.space32;
    final description = Semantics(
      header: true,
      label: title,
      child: Text(
        subtitle ?? '',
        style: context.tokens.text(AppTextStyles.bodyMedium),
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrow || actions.isEmpty) ...[
                description,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.space12),
                  Wrap(
                    spacing: AppDimens.space8,
                    runSpacing: AppDimens.space8,
                    children: actions,
                  ),
                ],
              ] else
                Row(
                  children: [
                    Expanded(child: description),
                    const SizedBox(width: AppDimens.space16),
                    Wrap(spacing: AppDimens.space8, children: actions),
                  ],
                ),
              const SizedBox(height: AppDimens.space20),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
