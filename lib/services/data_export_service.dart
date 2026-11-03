import 'dart:convert';

import 'package:file_saver/file_saver.dart';

/// Saves an exported file into the device's Downloads folder (screen 10 "đã xuất
/// dữ liệu"). Android writes through MediaStore, Windows to the user's Downloads
/// folder, web starts a browser download. Nothing leaves the device.
abstract interface class DataExportService {
  /// [fileName] without extension; returns where the file went (path or content URI)
  Future<String?> saveCsv(String fileName, String content);
}

class FileSaverDataExportService implements DataExportService {
  @override
  Future<String?> saveCsv(String fileName, String content) =>
      FileSaver.instance.saveToDownloads(
        name: fileName,
        bytes: utf8.encode(content),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
}
