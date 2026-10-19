import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rounded shaker silhouette while the detailed material image is loading.
class SaltShakerPainter extends CustomPainter {
  const SaltShakerPainter(this.style);
  final String style;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);
    final wood = style == 'salt_wood';
    final metal = style == 'salt_steel' || style == 'salt_gold';
    final glass = style == 'salt_glass';
    final body = Path()
      ..moveTo(35, 29)
      ..lineTo(65, 29)
      ..cubicTo(63, 46, 79, 59, 77, 84)
      ..quadraticBezierTo(77, 94, 50, 94)
      ..quadraticBezierTo(23, 94, 23, 84)
      ..cubicTo(21, 59, 37, 46, 35, 29)
      ..close();
    canvas.drawOval(
      const Rect.fromLTWH(25, 89, 52, 8),
      Paint()..color = const Color(0x28634735),
    );
    final colors = wood
        ? const [Color(0xFFE8BE87), Color(0xFFB47843), Color(0xFFDAA66B)]
        : metal
        ? const [Color(0xFF8B9499), Color(0xFFF0F0EA), Color(0xFF69747B)]
        : style == 'salt_rose'
        ? const [Color(0xFFD8ADB7), Color(0xFFFFEBEE), Color(0xFFB77B8B)]
        : glass
        ? const [Color(0x997EA9AD), Color(0xAAEDF2EC), Color(0x9981A3A4)]
        : const [Color(0xFFDFD2B9), Color(0xFFFFFAEE), Color(0xFFC6B69D)];
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(colors: colors)
            .createShader(const Rect.fromLTWH(23, 29, 54, 65)),
    );
    canvas.save();
    canvas.clipPath(body);
    if (glass) {
      final grains = Paint()..color = const Color(0xFFF8F4E7);
      for (var i = 0; i < 140; i++) {
        final x = 27 + (i * 17 % 47).toDouble();
        final y = 57 + (i * 13 % 35).toDouble();
        canvas.drawCircle(Offset(x, y), 1.25, grains);
      }
    }
    if (wood) {
      for (var i = 0; i < 12; i++) {
        canvas.drawArc(
          Rect.fromLTWH(18.0 + i, 43.0 + i * 3, 61, 15),
          .2,
          2.7,
          false,
          Paint()
            ..color = const Color(0x55794A27)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65,
        );
      }
    }
    canvas.restore();
    final cap = wood ? const Color(0xFFD3A06B) : const Color(0xFFBCC3C2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 17, 38, 17),
        const Radius.circular(6),
      ),
      Paint()
        ..shader = LinearGradient(colors: [cap, Colors.white, cap])
            .createShader(const Rect.fromLTWH(31, 17, 38, 17)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(31, 11, 38, 16),
      Paint()..color = wood ? const Color(0xFFE2B884) : const Color(0xFFE9EBE4),
    );
    for (final point in [
      const Offset(43, 17),
      const Offset(54, 16),
      const Offset(48, 22),
      const Offset(59, 21),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: point, width: 3.5, height: 2.3),
        Paint()..color = const Color(0xFF5A5E56),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SaltShakerPainter oldDelegate) =>
      oldDelegate.style != style;
}
