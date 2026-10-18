import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Botanical illustration shared by the shop and the kitchen scenery.
class DecorativePlant extends CustomPainter {
  const DecorativePlant(this.style);
  final String style;

  @override
  void paint(Canvas canvas, Size size) {
    if (style != 'plant_flowers' && style != 'plant_fern') return;
    final scale = math.min(size.width / 160, size.height / 190);
    canvas.save();
    canvas.translate(
      (size.width - 160 * scale) / 2,
      (size.height - 190 * scale) / 2,
    );
    canvas.scale(scale);
    final flowers = style == 'plant_flowers';
    canvas.drawOval(
      const Rect.fromLTWH(30, 168, 102, 15),
      Paint()
        ..color = const Color(0x236B4934)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    void leaf(Offset base, Offset tip, double width, Color color) {
      final delta = tip - base;
      final normal = Offset(-delta.dy, delta.dx) / delta.distance * width;
      final middle = Offset.lerp(base, tip, .52)!;
      final shape = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          middle.dx + normal.dx,
          middle.dy + normal.dy,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          middle.dx - normal.dx * .7,
          middle.dy - normal.dy * .7,
          base.dx,
          base.dy,
        );
      canvas.drawPath(shape, Paint()..color = color);
      canvas.drawLine(
        base,
        tip,
        Paint()
          ..color = const Color(0x557AA36B)
          ..strokeWidth = .7,
      );
    }

    final stemPaint = Paint()
      ..color = const Color(0xFF51784E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (flowers) {
      const heads = [
        Offset(39, 67),
        Offset(65, 39),
        Offset(103, 46),
        Offset(124, 77),
        Offset(80, 76),
      ];
      for (var i = 0; i < heads.length; i++) {
        final tip = heads[i];
        final origin = Offset(77 + i * 2, 139);
        final control = Offset(tip.dx + (i.isEven ? -12 : 10), 105);
        canvas.drawPath(
          Path()
            ..moveTo(origin.dx, origin.dy)
            ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy),
          stemPaint,
        );
        final middle = Offset.lerp(origin, tip, .48)!;
        leaf(
          middle,
          middle + Offset(i.isEven ? -25 : 25, -16),
          7,
          i.isEven ? const Color(0xFF6E965C) : const Color(0xFF507A4B),
        );
        leaf(
          middle + const Offset(0, 14),
          middle + Offset(i.isEven ? 20 : -20, -3),
          6,
          const Color(0xFF7EA16A),
        );
      }
      for (var i = 0; i < heads.length; i++) {
        final center = heads[i];
        final radius = i == 4 ? 15.0 : 17.0;
        final light = i.isEven
            ? const Color(0xFFF7D4C9)
            : const Color(0xFFFFF3D5);
        final dark = i.isEven
            ? const Color(0xFFD78F91)
            : const Color(0xFFE5C17C);
        for (var petal = 0; petal < 8; petal++) {
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(petal * math.pi / 4 + i * .3);
          final bounds = Rect.fromCenter(
            center: Offset(0, -radius * .57),
            width: radius * .70,
            height: radius * 1.12,
          );
          canvas.drawOval(
            bounds.shift(const Offset(.5, 1)),
            Paint()..color = const Color(0x226B4934),
          );
          canvas.drawOval(
            bounds,
            Paint()
              ..shader = LinearGradient(
                colors: [light, dark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
          );
          canvas.restore();
        }
        canvas.drawCircle(
          center + const Offset(0, 1),
          6,
          Paint()..color = const Color(0xFFAD783B),
        );
        canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFE9B94E));
        for (var dot = 0; dot < 7; dot++) {
          final angle = dot * 2.4;
          canvas.drawCircle(
            center + Offset(math.cos(angle), math.sin(angle)) * 3.1,
            .7,
            Paint()..color = const Color(0xFFFFE4A0),
          );
        }
      }
    } else {
      // Arching fronds with paired, tapered leaflets instead of round blobs.
      for (var frond = 0; frond < 9; frond++) {
        final angle = -math.pi + frond * math.pi / 8;
        final tip = Offset(
          80 + math.cos(angle) * 66,
          93 + math.sin(angle) * 68,
        );
        const base = Offset(80, 140);
        final control = Offset(
          80 + math.cos(angle) * 37,
          45 + math.sin(angle) * 21,
        );
        canvas.drawPath(
          Path()
            ..moveTo(base.dx, base.dy)
            ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy),
          stemPaint..strokeWidth = 1.5,
        );
        for (var pair = 1; pair <= 10; pair++) {
          final t = pair / 11;
          final point =
              base * ((1 - t) * (1 - t)) +
              control * (2 * (1 - t) * t) +
              tip * (t * t);
          final tangent =
              (control - base) * (2 * (1 - t)) + (tip - control) * (2 * t);
          final direction = tangent / tangent.distance;
          final side = Offset(-direction.dy, direction.dx);
          final length = 15 * math.sin(t * math.pi) + 3;
          for (final sign in [-1, 1]) {
            leaf(
              point,
              point + side * (sign * length) + direction * 6,
              3.2 * (1 - t) + .8,
              (pair + frond + sign).isEven
                  ? const Color(0xFF537F4B)
                  : const Color(0xFF80A467),
            );
          }
        }
      }
    }
    final pot = Path()
      ..moveTo(47, 132)
      ..lineTo(113, 132)
      ..lineTo(104, 171)
      ..quadraticBezierTo(80, 183, 56, 171)
      ..close();
    const potBounds = Rect.fromLTWH(46, 130, 68, 50);
    canvas.drawPath(
      pot,
      Paint()
        ..shader = LinearGradient(
          colors: flowers
              ? [
                  const Color(0xFFE7C4B4),
                  const Color(0xFFC99587),
                  const Color(0xFFB17A6F),
                ]
              : [
                  const Color(0xFFD49D70),
                  const Color(0xFFB97550),
                  const Color(0xFF965B40),
                ],
          stops: const [0, .55, 1],
        ).createShader(potBounds),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 128, 72, 10),
        const Radius.circular(4),
      ),
      Paint()
        ..color = flowers ? const Color(0xFFE7C9BA) : const Color(0xFFD49B73),
    );
    canvas.drawLine(
      const Offset(53, 143),
      const Offset(59, 167),
      Paint()
        ..color = const Color(0x55FFF3DC)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      const Rect.fromLTWH(55, 157, 50, 16),
      .15,
      math.pi - .3,
      false,
      Paint()
        ..color = const Color(0x33734836)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(DecorativePlant oldDelegate) => oldDelegate.style != style;
}
