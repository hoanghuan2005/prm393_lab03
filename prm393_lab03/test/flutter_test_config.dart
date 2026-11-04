import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file in this folder
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Tests have no network; never try to download fonts
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
