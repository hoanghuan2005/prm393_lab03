import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom Vector Logo for "Why I Buy"
/// Matches the 3 vertical bars + search loop from Figma
class WhyIBuyLogo extends StatelessWidget {
  final double size;
  final Color color;

  const WhyIBuyLogo({
    super.key,
    this.size = 48,
    this.color = AppColors.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WhyIBuyLogoPainter(color: color),
      ),
    );
  }
}

class _WhyIBuyLogoPainter extends CustomPainter {
  final Color color;

  _WhyIBuyLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width * 0.16;
    final r = Radius.circular(barWidth / 2);

    // Bar 1 (Short left)
    final bar1Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.45, barWidth, size.height * 0.35),
      r,
    );
    canvas.drawRRect(bar1Rect, paint);

    // Bar 2 (Medium center)
    final bar2Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.28, barWidth, size.height * 0.52),
      r,
    );
    canvas.drawRRect(bar2Rect, paint);

    // Bar 3 (Tall right)
    final bar3Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.61, size.height * 0.20, barWidth, size.height * 0.35),
      r,
    );
    canvas.drawRRect(bar3Rect, paint);

    // Magnifying glass circle on bottom right
    final loopCenter = Offset(size.width * 0.69, size.height * 0.65);
    final loopRadius = size.width * 0.16;
    canvas.drawCircle(loopCenter, loopRadius, strokePaint);

    // Magnifying glass handle
    canvas.drawLine(
      Offset(size.width * 0.79, size.height * 0.77),
      Offset(size.width * 0.94, size.height * 0.92),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WhyIBuyLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
