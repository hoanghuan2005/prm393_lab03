import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/constants/legal_texts.dart';

import '../tool/generate_auth_policy_pages.dart';

void main() {
  for (final entry in {
    'privacy.html': LegalTexts.privacy,
    'data-deletion.html': LegalTexts.dataDeletion,
  }.entries) {
    test('${entry.key} matches app source and contains all sections', () {
      final html = renderPolicyPage(entry.value);
      expect(
        // Git on Windows (core.autocrlf) checks the page out with CRLF line endings
        File(
          '../prm393_flutter_admin/web/${entry.key}',
        ).readAsStringSync().replaceAll('\r\n', '\n'),
        html,
      );
      for (final section in entry.value.sections) {
        expect(html, contains(const HtmlEscape().convert(section.heading)));
        expect(html, contains(const HtmlEscape().convert(section.body)));
      }
      expect(html, contains('daotamhoang2005@gmail.com'));
      expect(html, isNot(contains('<script')));
    });
  }
}
