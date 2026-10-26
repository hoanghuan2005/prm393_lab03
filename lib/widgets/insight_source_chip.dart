import 'package:flutter/material.dart';

/// Tells the user whether a sentence was written by AI or is the built-in template
class InsightSourceChip extends StatelessWidget {
  final bool fromAi;

  const InsightSourceChip({super.key, required this.fromAi});

  @override
  Widget build(BuildContext context) {
    final foreground = fromAi ? const Color(0xFF92400E) : const Color(0xFF4B5563);
    return Semantics(
      label: fromAi ? 'Do AI viết' : 'Câu mẫu',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: fromAi ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fromAi ? Icons.auto_awesome : Icons.notes_rounded, size: 12, color: foreground),
            const SizedBox(width: 4),
            Text(
              fromAi ? 'AI' : 'Câu mẫu',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
