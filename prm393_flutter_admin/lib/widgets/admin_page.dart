import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

/// Page frame of the wide-screen layout: title, subtitle, actions and content
/// limited to a readable width.
class AdminPage extends StatelessWidget {
  static const double maxContentWidth = 1200;

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
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.headlineLarge),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimens.space4),
          Text(subtitle!, style: AppTextStyles.bodyMedium),
        ],
      ],
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
                heading,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: AppDimens.space16),
                    Wrap(spacing: AppDimens.space8, children: actions),
                  ],
                ),
              const SizedBox(height: AppDimens.space24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
