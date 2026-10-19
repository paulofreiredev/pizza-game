import 'kitchen_materials.dart';
import 'ingredient_details.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

const preparedIngredients = {
  'calabresa',
  'cebola',
  'tomate',
  'queijo',
  'muçarela',
  'provolone',
  'gorgonzola',
  'parmesão',
  'frango',
  'camarão',
  'catupiri',
  'carne de sol',
  'morango',
  'chocolate',
  'confeitos',
  'manjericão',
};

/// Ready-to-use ingredients pile up independently of their cutting positions.
class PreparedIngredientBowl extends CustomPainter {
  const PreparedIngredientBowl(this.kind);
  final String kind;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(unit);
    final bowl = Rect.fromCenter(
      center: const Offset(0, .025),
      width: .91,
      height: .73,
    );
    canvas.drawOval(
      bowl.shift(const Offset(0, .045)),
      Paint()..color = const Color(0x30634735),
    );
    canvas.drawOval(
      bowl,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E8), Color(0xFFE2D6BF), Color(0xFF9E927D)],
        ).createShader(bowl),
    );
    final opening = Rect.fromCenter(
      center: const Offset(0, -.025),
      width: .82,
      height: .60,
    );
    canvas.drawOval(opening, Paint()..color = const Color(0xFFE8EBDC));
    canvas.save();
    canvas.clipPath(Path()..addOval(opening.deflate(.025)));
    canvas.drawOval(
      opening.deflate(.025),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFE3D8C3), Color(0xFFB4A68E)],
        ).createShader(opening),
    );
    final random = math.Random(73);
    for (var i = 0; i < 65; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble());
      final point = Offset(
        math.cos(angle) * radius * .36,
        -.025 + math.sin(angle) * radius * .25,
      );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(random.nextDouble() * math.pi);
      if (KitchenMaterials.paintFood(
        canvas,
        Rect.fromCenter(center: Offset.zero, width: .25, height: .25),
        kind,
      )) {
        canvas.restore();
        continue;
      }
      if (kind == 'camarão') {
        paintShrimp(canvas, Offset.zero, .095);
      } else if (kind == 'catupiri') {
        paintCatupiri(canvas, Offset.zero, .10);
      } else if (kind == 'calabresa') {
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(.005, .008),
            width: .17,
            height: .13,
          ),
          Paint()..color = const Color(0xFF733A2B),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: .15, height: .11),
          Paint()
            ..color = i.isEven
                ? const Color(0xFFBC7051)
                : const Color(0xFFC98563),
        );
        for (var j = 0; j < 3; j++) {
          canvas.drawCircle(
            Offset((j - 1) * .035, (j.isEven ? 1 : -1) * .02),
            .012,
            Paint()..color = const Color(0xFFF6D1AB),
          );
        }
      } else if (kind == 'cebola') {
        canvas.drawArc(
          Rect.fromCenter(center: Offset.zero, width: .17, height: .11),
          .2,
          math.pi * 1.45,
          false,
          Paint()
            ..color = const Color(0xFFAB76A2)
            ..strokeWidth = .025
            ..style = PaintingStyle.stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset.zero, width: .14, height: .085),
          .2,
          math.pi * 1.45,
          false,
          Paint()
            ..color = const Color(0xFFF6E2EE)
            ..strokeWidth = .018
            ..style = PaintingStyle.stroke,
        );
      } else if (kind == 'tomate') {
        final wedge = Path()
          ..moveTo(-.08, .025)
          ..quadraticBezierTo(0, -.12, .08, .025)
          ..close();
        canvas.drawPath(wedge, Paint()..color = const Color(0xFFC54632));
        canvas.drawLine(
          const Offset(-.045, .005),
          const Offset(.045, .005),
          Paint()
            ..color = const Color(0xFFFFAC73)
            ..strokeWidth = .015,
        );
      } else {
        final meat = kind == 'carne de sol';
        final chicken = kind == 'frango';
        final color = meat
            ? const Color(0xFF93583C)
            : chicken
            ? const Color(0xFFE9BC85)
            : kind == 'gorgonzola' && i % 4 == 0
            ? const Color(0xFF72958A)
            : i.isEven
            ? const Color(0xFFFFE9AD)
            : const Color(0xFFE6BF65);
        canvas.drawLine(
          const Offset(-.06, -.008),
          const Offset(.06, .008),
          Paint()
            ..color = const Color(0x22634A29)
            ..strokeWidth = .035
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          const Offset(-.06, -.015),
          const Offset(.06, 0),
          Paint()
            ..color = color
            ..strokeWidth = chicken || meat ? .032 : .021
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }
    canvas.restore();
    canvas.drawArc(
      bowl.deflate(.014),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFD5E0D6)
        ..strokeWidth = .036
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PreparedIngredientBowl oldDelegate) =>
      oldDelegate.kind != kind;
}
