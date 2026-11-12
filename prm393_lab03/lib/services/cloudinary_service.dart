import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Uploads images to Cloudinary with an UNSIGNED upload preset and returns the `secure_url`.
/// No API secret lives in the app; configure at build/run time:
///   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
class CloudinaryService {
  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'de2g3a3hr',
  );
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'prm393neww',
  );

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  final http.Client _client;

  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  Uri get _endpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// Uploads raw image bytes (e.g. from image_picker).
  Future<String> uploadBytes(
    Uint8List bytes, {
    String filename = 'photo.jpg',
  }) async {
    _ensureConfigured();
    final request = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    return _readUrl(response);
  }

  /// Copies a remote image (e.g. a Shopee CDN link) into Cloudinary.
  Future<String> uploadFromUrl(String url) async {
    _ensureConfigured();
    final response = await _client.post(
      _endpoint,
      body: {'file': url, 'upload_preset': uploadPreset},
    );
    return _readUrl(response);
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError('Cloudinary chưa được cấu hình (thiếu dart-define).');
    }
  }

  String _readUrl(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }
    final url =
        (jsonDecode(response.body) as Map<String, dynamic>)['secure_url'];
    if (url is! String || url.isEmpty) {
      throw Exception('Cloudinary response has no secure_url');
    }
    return url;
  }
}
