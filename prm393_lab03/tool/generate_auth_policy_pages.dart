import 'dart:convert';
import 'dart:io';

import 'package:prm393_lab03/core/constants/legal_texts.dart';

String renderPolicyPage(InfoDocument document) {
  const escape = HtmlEscape();
  String html(String text) => escape.convert(text);
  return '''<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${html(document.title)} · Why I Buy?</title>
  <style>
    body { font: 1rem/1.7 system-ui, sans-serif; color: #182230; background: #f5f7fa; margin: 0; }
    main { max-width: 760px; margin: 2rem auto; padding: 1.5rem; background: white; border-radius: 16px; }
    h1 { line-height: 1.25; } h2 { font-size: 1.2rem; margin-top: 2rem; }
    a { color: #1558a6; overflow-wrap: anywhere; } p { white-space: pre-line; }
    nav { display: flex; flex-wrap: wrap; gap: 1rem; }
    @media (max-width: 800px) { main { margin: 0; border-radius: 0; } }
  </style>
</head>
<body><main>
  <nav aria-label="Chính sách"><a href="privacy.html">Quyền riêng tư</a><a href="data-deletion.html">Xoá dữ liệu</a></nav>
  <h1>${html(document.title)}</h1>
  <p>Cập nhật: ${html(document.updated)}</p>
  <p>${html(document.intro)}</p>
${document.sections.map((section) => '  <section><h2>${html(section.heading)}</h2><p>${html(section.body)}</p></section>').join('\n')}
  <footer><a href="mailto:${html(LegalTexts.supportEmail)}">${html(LegalTexts.supportEmail)}</a> · Why I Buy? — PRM393</footer>
</main></body>
</html>
''';
}

void main() {
  // Resolve relative to this script, independent of the terminal directory.
  final workspace = File.fromUri(Platform.script).parent.parent.parent;
  final web = Directory('${workspace.path}/prm393_flutter_admin/web');
  if (!web.existsSync()) {
    throw StateError('Không tìm thấy thư mục web hosting.');
  }
  for (final entry in {
    'privacy.html': LegalTexts.privacy,
    'data-deletion.html': LegalTexts.dataDeletion,
  }.entries) {
    File('${web.path}/${entry.key}')
        .writeAsStringSync(renderPolicyPage(entry.value));
    stdout.writeln('Generated ${entry.key}');
  }
}
