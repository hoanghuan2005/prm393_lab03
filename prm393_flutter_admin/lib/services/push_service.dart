import 'dart:convert';

import 'package:http/http.dart' as http;

import 'admin_auth_service.dart';

class PushException implements Exception {
  final String message;

  const PushException(this.message);

  @override
  String toString() => message;
}

/// Optional extra: the team's local Spring Boot push server (spring-boot-push)
/// sends an FCM notification next to the announcement. The system works
/// without it — announcements reach the app through Firestore — so it is only
/// enabled when the web is built or run with --dart-define=PUSH_API_BASE_URL=…
abstract class PushService {
  bool get isConfigured;

  /// Returns how many devices received it
  Future<int> broadcast({required String title, required String body});
}

class HttpPushService implements PushService {
  static const String baseUrl = String.fromEnvironment('PUSH_API_BASE_URL');

  final AdminAuthService _auth;
  final http.Client _client;

  HttpPushService(this._auth, [http.Client? client])
    : _client = client ?? http.Client();

  @override
  bool get isConfigured => baseUrl.isNotEmpty;

  @override
  Future<int> broadcast({required String title, required String body}) async {
    final token = await _auth.idToken();
    if (token == null) throw const PushException('Phiên đăng nhập đã hết hạn.');
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/api/notifications/send'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'title': title,
              'body': body,
              'targetAudience': 'all',
              'targetScreen': 'inbox',
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw PushException('Không kết nối được server push ($baseUrl).');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const PushException(
        'Server push từ chối: tài khoản không phải admin.',
      );
    }
    if (response.statusCode != 200) {
      throw PushException('Server push lỗi (HTTP ${response.statusCode}).');
    }
    final data = jsonDecode(response.body);
    return data is Map && data['sentTokens'] is num
        ? (data['sentTokens'] as num).toInt()
        : 0;
  }
}
