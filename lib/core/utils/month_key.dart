/// "2026-10": key used for monthly budgets and reports
String monthKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
