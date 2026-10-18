import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A wordless handoff: the chef slides the pizza in and folds down the lid.
class PizzaBoxScene extends StatelessWidget {
  const PizzaBoxScene({
    super.key,
    required this.progress,
    required this.recipeId,
  });

  final double progress;
  final String recipeId;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BoxPainter(progress: progress, sweet: recipeId == 'chocolate'),
    size: Size.infinite,
  );
}

class _BoxPainter extends CustomPainter {
  const _BoxPainter({required this.progress, required this.sweet});
  final double progress;
  final bool sweet;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    final origin = Offset(size.width * .5, size.height * .5);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(unit);
    final t = progress.clamp(0.0, 1.0);
    final placement = Curves.easeInOutCubic.transform((t / .55).clamp(0, 1));
    final closing = Curves.easeInOutCubic.transform(
      ((t - .65) / .35).clamp(0, 1),
    );
    Paint ink(Color color) => Paint()..color = color;
    void oval(Rect rect, Color color) => canvas.drawOval(rect, ink(color));
    void rounded(Rect rect, Color color, [double radius = .025]) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          ink(color),
        );
    void line(Offset a, Offset b, Color color, double width) => canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );

    // The friendly chef stays behind the work surface.
    const face = Offset(.29, -.31);
    rounded(
      const Rect.fromLTWH(.20, -.27, .18, .23),
      const Color(0xFF79A491),
      .05,
    );
    rounded(
      const Rect.fromLTWH(.235, -.24, .11, .19),
      const Color(0xFFFFEAC7),
      .025,
    );
    line(
      const Offset(.25, -.26),
      const Offset(.25, -.19),
      const Color(0xFFE4BD8B),
      .013,
    );
    line(
      const Offset(.33, -.26),
      const Offset(.33, -.19),
      const Color(0xFFE4BD8B),
      .013,
    );
    oval(Rect.fromCircle(center: face, radius: .084), const Color(0xFF774A35));
    oval(
      Rect.fromCircle(center: face + const Offset(0, .012), radius: .073),
      const Color(0xFFF4BD8F),
    );
    for (final side in [-1.0, 1.0]) {
      oval(
        Rect.fromCircle(center: face + Offset(side * .031, .007), radius: .007),
        const Color(0xFF4E392F),
      );
      oval(
        Rect.fromCenter(
          center: face + Offset(side * .044, .032),
          width: .027,
          height: .013,
        ),
        const Color(0x66E68C7C),
      );
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: face + const Offset(0, .022),
        width: .038,
        height: .031,
      ),
      .15,
      math.pi - .3,
      false,
      Paint()
        ..color = const Color(0xFF8E5140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .005,
    );
    for (var i = 0; i < 3; i++) {
      oval(
        Rect.fromCircle(
          center: face + Offset((i - 1) * .045, -.075 - (i == 1 ? .016 : 0)),
          radius: .044,
        ),
        const Color(0xFFFFF8E6),
      );
    }
    rounded(
      Rect.fromCenter(
        center: face + const Offset(0, -.045),
        width: .145,
        height: .045,
      ),
      const Color(0xFFEADDC4),
      .01,
    );

    // Open box and its hinged lid, in a gentle overhead perspective.
    rounded(
      const Rect.fromLTWH(
        -.255,
        -.19,
        .51,
        .46,
      ).shift(const Offset(.012, .018)),
      const Color(0x386C442A),
    );
    rounded(
      const Rect.fromLTWH(-.255, -.19, .51, .46),
      const Color(0xFFB67E48),
    );
    rounded(
      const Rect.fromLTWH(-.235, -.17, .47, .415),
      const Color(0xFFE7BE84),
    );
    rounded(
      const Rect.fromLTWH(-.215, -.15, .43, .375),
      const Color(0xFFFFE4B3),
    );
    for (var i = 0; i < 16; i++) {
      line(
        Offset(-.20 + i * .027, -.14),
        Offset(-.20 + i * .027, .215),
        const Color(0x0F986532),
        .002,
      );
    }
    final pizzaY = .36 * (1 - placement) + .035 * placement;
    if (closing < .98) {
      canvas.save();
      canvas.translate(0, pizzaY);
      oval(
        const Rect.fromLTWH(-.19, -.155, .38, .32).shift(const Offset(0, .013)),
        const Color(0x326E3F24),
      );
      oval(const Rect.fromLTWH(-.19, -.16, .38, .32), const Color(0xFFC98A42));
      oval(
        const Rect.fromLTWH(-.174, -.145, .348, .29),
        const Color(0xFFF3C474),
      );
      oval(
        const Rect.fromLTWH(-.152, -.128, .304, .256),
        sweet ? const Color(0xFF693C2C) : const Color(0xFFDC7651),
      );
      for (var i = 0; i < 7; i++) {
        final a = i * 2.399;
        final p = Offset(math.cos(a) * .09, math.sin(a) * .075);
        if (sweet) {
          final berry = Path()
            ..moveTo(p.dx, p.dy + .028)
            ..cubicTo(
              p.dx - .05,
              p.dy - .01,
              p.dx - .024,
              p.dy - .04,
              p.dx,
              p.dy - .019,
            )
            ..cubicTo(
              p.dx + .027,
              p.dy - .04,
              p.dx + .046,
              p.dy - .005,
              p.dx,
              p.dy + .028,
            );
          canvas.drawPath(berry, ink(const Color(0xFFE95E57)));
          line(
            p + const Offset(-.01, -.021),
            p + const Offset(.01, -.021),
            const Color(0xFF6E9251),
            .009,
          );
        } else {
          oval(
            Rect.fromCenter(center: p, width: .051, height: .041),
            const Color(0xFF9F4E38),
          );
          oval(
            Rect.fromCircle(
              center: p + const Offset(.009, -.007),
              radius: .006,
            ),
            const Color(0xFFFFDCAD),
          );
        }
      }
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 4;
        final d = Offset(math.cos(a) * .18, math.sin(a) * .15);
        line(-d, d, const Color(0x99774431), .004);
      }
      canvas.restore();
    }
    // The hand follows the pizza, then withdraws before the lid closes.
    final withdrawal = ((t - .5) / .15).clamp(0.0, 1.0);
    final hand = Offset(
      .18 + withdrawal * .14,
      pizzaY + .05 - withdrawal * .18,
    );
    line(const Offset(.33, -.13), hand, const Color(0xFF79A491), .046);
    oval(
      Rect.fromCenter(center: hand, width: .065, height: .048),
      const Color(0xFFF4BD8F),
    );

    // A folded lid projects around its back hinge as it closes.
    final lidTop = -.43 + .24 * closing;
    final lidBottom = -.19 + .46 * closing;
    final lid = Rect.fromLTRB(-.255, lidTop, .255, lidBottom);
    rounded(
      lid,
      Color.lerp(const Color(0xFFE8C18D), const Color(0xFFD7A56E), closing)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid.deflate(.01), const Radius.circular(.02)),
      Paint()
        ..color = const Color(0xFFB58350)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .004,
    );
    line(
      const Offset(-.24, -.19),
      const Offset(.24, -.19),
      const Color(0xFFAA7744),
      .006,
    );
    final logo = lid.center;
    final logoScale = (lid.height / .46).clamp(.3, 1.0);
    canvas.save();
    canvas.translate(logo.dx, logo.dy);
    canvas.scale(1.0, logoScale);
    oval(const Rect.fromLTWH(-.075, -.075, .15, .15), const Color(0x22FFF4D5));
    final slice = Path()
      ..moveTo(-.055, -.04)
      ..quadraticBezierTo(0, -.075, .055, -.04)
      ..lineTo(0, .07)
      ..close();
    canvas.drawPath(slice, ink(const Color(0xFFBC6440)));
    canvas.drawArc(
      const Rect.fromLTWH(-.06, -.062, .12, .06),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFFFD994)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .015
        ..strokeCap = StrokeCap.round,
    );
    for (final p in [
      const Offset(-.022, -.018),
      const Offset(.024, -.02),
      const Offset(0, .022),
    ]) {
      oval(Rect.fromCircle(center: p, radius: .01), const Color(0xFFF6D393));
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) =>
      progress != oldDelegate.progress || sweet != oldDelegate.sweet;
}
