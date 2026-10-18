import 'dart:math' as math;

import 'package:flutter/material.dart';

void paintShrimp(Canvas canvas, Offset center, double radius) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  final body = Path()
    ..moveTo(.55, -.55)
    ..cubicTo(-.25, -1.25, -1.1, -.52, -.72, .3)
    ..cubicTo(-.35, 1.0, .62, .79, .48, .15);
  canvas.drawPath(
    body.shift(const Offset(.03, .06)),
    Paint()
      ..color = const Color(0x447E4A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .52
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawPath(
    body,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF8B17B), Color(0xFFFCE1BE), Color(0xFFE78D60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(-1, -1, 2, 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = .46
      ..strokeCap = StrokeCap.round,
  );
  for (var i = 0; i < 5; i++) {
    final angle = -math.pi * .9 + i * .43;
    final point = Offset(math.cos(angle) * .67, math.sin(angle) * .66);
    canvas.drawLine(
      point * .74,
      point * 1.20,
      Paint()
        ..color = const Color(0xBBD98159)
        ..strokeWidth = .055
        ..strokeCap = StrokeCap.round,
    );
  }
  canvas.drawPath(
    Path()
      ..moveTo(.53, -.53)
      ..lineTo(.94, -.74)
      ..lineTo(.84, -.31)
      ..close(),
    Paint()..color = const Color(0xFFDF8D64),
  );
  canvas.restore();
}

void paintCatupiri(Canvas canvas, Offset center, double radius) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  final dollop = Path()
    ..moveTo(-.65, .4)
    ..cubicTo(-1, -.05, -.28, -.7, .15, -.8)
    ..cubicTo(.07, -.3, .95, -.12, .68, .4)
    ..cubicTo(.42, .85, -.35, .87, -.65, .4)
    ..close();
  canvas.drawPath(
    dollop.shift(const Offset(.035, .07)),
    Paint()..color = const Color(0x337C6040),
  );
  canvas.drawPath(
    dollop,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFF4DC), Color(0xFFE3CFAD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(-1, -1, 2, 2)),
  );
  canvas.drawPath(
    Path()
      ..moveTo(-.4, .2)
      ..quadraticBezierTo(-.18, -.08, .13, -.36),
    Paint()
      ..color = const Color(0xDDFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .13
      ..strokeCap = StrokeCap.round,
  );
  canvas.restore();
}
