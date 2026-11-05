import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'app/admin_app.dart';
import 'firebase_options.dart';

/// reCAPTCHA Enterprise key of the project's web app, the same one the app's
/// web build uses. Public by design.
const _appCheckSiteKey = '6LfqQQEuAAAAABRHj6KthKFR3Zf7zqV3u3z4h4YO';

/// Optional: `--dart-define=APP_CHECK_DEBUG_TOKEN=...` (a token registered in the console)
const _appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// Local testing against the Firebase Emulator Suite (firebase emulators:start):
/// --dart-define=USE_EMULATORS=true
const _useEmulators = bool.fromEnvironment('USE_EMULATORS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } catch (e) {
    runApp(_BootFailureApp(error: '$e'));
    return;
  }

  if (_useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8085);
  } else {
    try {
      await FirebaseAppCheck.instance.activate(
        providerWeb: _appCheckDebugToken.isNotEmpty
            ? WebDebugProvider(debugToken: _appCheckDebugToken)
            : ReCaptchaEnterpriseProvider(_appCheckSiteKey),
      );
    } catch (e) {
      // Firestore keeps working while App Check is not enforced for it
      debugPrint('App Check not active: $e');
    }
  }

  runApp(const AdminApp());
}

class _BootFailureApp extends StatelessWidget {
  final String error;

  const _BootFailureApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ErrorView(message: 'Không khởi động được Firebase. $error'),
      ),
    );
  }
}
