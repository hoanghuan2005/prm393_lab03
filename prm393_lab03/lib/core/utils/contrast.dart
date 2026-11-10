import 'dart:ui';

/// WCAG 2.1 contrast after compositing [foreground] over [background].
/// The background must be opaque: contrast on an unknown backdrop is undefined.
double contrastRatio(Color foreground, Color background) {
  if (background.a != 1) {
    throw ArgumentError.value(background, 'background', 'Must be opaque');
  }
  final first = Color.alphaBlend(foreground, background).computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first < second ? first : second;
  return (lighter + 0.05) / (darker + 0.05);
}
