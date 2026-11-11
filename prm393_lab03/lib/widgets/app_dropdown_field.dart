import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';

class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.decoration,
    this.enabled = true,
  });

  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final InputDecoration decoration;
  final bool enabled;

  Future<void> _openMenu(BuildContext context) async {
    if (!enabled || onChanged == null) return;

    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.sizeOf(context);
    final selectedIndex = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height + 4,
        screenSize.width - offset.dx - renderBox.size.width,
        0,
      ),
      constraints: BoxConstraints.tightFor(width: renderBox.size.width),
      elevation: 8,
      color: AppSemanticColors.of(context).cardSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.borderMedium),
      items: [
        for (var index = 0; index < items.length; index++)
          PopupMenuItem<int>(
            value: index,
            height: 56,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space12,
                vertical: AppDimens.space4,
              ),
              decoration: items[index].value == value
                  ? BoxDecoration(
                      color: AppSemanticColors.of(context).primaryContainer,
                      borderRadius: AppDimens.borderSmall,
                    )
                  : null,
              alignment: Alignment.centerLeft,
              child: Text(items[index].label),
            ),
          ),
      ],
    );
    if (selectedIndex != null) onChanged!(items[selectedIndex].value);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _openMenu(context),
        child: InputDecorator(
          decoration: decoration.copyWith(
            enabled: enabled,
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            items.firstWhere((item) => item.value == value).label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
