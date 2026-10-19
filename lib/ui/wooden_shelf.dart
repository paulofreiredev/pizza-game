import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A beveled wood plank with visible grain and two recessed metal brackets.
class WoodenShelf extends StatelessWidget {
  const WoodenShelf({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 14 : 22,
    width: double.infinity,
    child: CustomPaint(painter: _ShelfPainter()),
  );
}

class _ShelfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final depth = size.height * .46;
    final board = Rect.fromLTWH(0, 0, size.width, depth);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        board.shift(const Offset(0, 4)),
        const Radius.circular(2),
      ),
      Paint()
        ..color = const Color(0x44643D22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE0B27A),
            Color(0xFFC08A51),
            Color(0xFF87502B),
            Color(0xFFA36A3B),
          ],
          stops: [0, .2, .85, 1],
        ).createShader(board),
    );
    final random = math.Random(71);
    for (var i = 0; i < 13; i++) {
      final y = depth * (.18 + random.nextDouble() * .65);
      final start = random.nextDouble() * size.width * .7;
      canvas.drawPath(
        Path()
          ..moveTo(start, y)
          ..quadraticBezierTo(
            start + size.width * .12,
            y - .8,
            math.min(size.width - 3, start + size.width * .33),
            y + .25,
          ),
        Paint()
          ..color = const Color(0x55774626)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .55,
      );
    }
    canvas.drawLine(
      const Offset(2, 1),
      Offset(size.width - 2, 1),
      Paint()
        ..color = const Color(0x99FFE3AF)
        ..strokeWidth = .7,
    );
    for (final fraction in [.18, .82]) {
      final x = size.width * fraction;
      final bracket = Path()
        ..moveTo(x - 7, depth)
        ..lineTo(x + 5, depth)
        ..lineTo(x + 5, size.height - 1)
        ..close();
      canvas.drawPath(
        bracket,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF4B382A), Color(0xFF7D6550)],
          ).createShader(Rect.fromLTWH(x - 7, depth, 12, size.height - depth)),
      );
      canvas.drawCircle(
        Offset(x + 2, depth + 3),
        .9,
        Paint()..color = const Color(0xFFD0AD7A),
      );
    }
  }

  @override
  bool shouldRepaint(_ShelfPainter oldDelegate) => false;
}
