import 'dart:math' as math;

import 'package:flutter/material.dart';

class DoughMixturePainter extends CustomPainter {
  const DoughMixturePainter({
    required this.ingredients,
    required this.mixing,
    required this.progress,
    required this.phase,
    this.pouring,
    this.pourProgress = 1,
    this.pourFrom,
    this.spoon,
  });
  final Set<String> ingredients;
  final bool mixing;
  final double progress, phase, pourProgress;
  final String? pouring;
  final Offset? pourFrom, spoon;

  @override
  void paint(Canvas canvas, Size size) {
    final u = math.min(size.width, size.height), r = u * .31;
    final center = Offset(size.width * .5, size.height * .51);
    final t = progress.clamp(0.0, 1.0);
    final selected = mixing
        ? const {'farinha', 'água', 'sal', 'fermento'}
        : ingredients;
    double amount(String kind) => selected.contains(kind)
        ? (!mixing && pouring == kind
              ? Curves.easeOut.transform(pourProgress)
              : 1)
        : 0;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: r * .87)),
    );
    canvas.translate(center.dx, center.dy);
    if (amount('água') > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(r * .10, r * .07),
          width: r * 1.75 * amount('água'),
          height: r * 1.45 * amount('água'),
        ),
        Paint()
          ..color = Color.lerp(
            const Color(0xFFB4C8BC),
            const Color(0xFFE9D7B0),
            mixing ? t : amount('farinha') * .3,
          )!,
      );
    }
    if (amount('farinha') > 0) {
      final random = math.Random(41);
      if (mixing) canvas.rotate(phase * .34);
      final base = Rect.fromCircle(
        center: Offset.zero,
        radius: r * .81 * math.sqrt(amount('farinha')),
      );
      if (!mixing) {
        _paintFlour(canvas, r, amount('farinha'));
      } else {
        canvas.drawOval(
          base,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Color.lerp(
                  const Color(0xFFFFF5DB),
                  const Color(0xFFE9D1A0),
                  mixing ? t : 0,
                )!,
                const Color(0xFFD6C092),
              ],
            ).createShader(base),
        );
        for (var i = 0; i < 48; i++) {
          final angle = random.nextDouble() * math.pi * 2;
          final radius = math.sqrt(random.nextDouble()) * r * .73;
          final point = Offset(math.cos(angle), math.sin(angle)) * radius;
          final lump =
              r *
              (.035 + random.nextDouble() * .085) *
              (mixing ? 1 - t * .80 : amount('farinha'));
          canvas.drawOval(
            Rect.fromCenter(center: point, width: lump * 2, height: lump * 1.4),
            Paint()
              ..color = Color.lerp(
                const Color(0xFFFDF2D9),
                const Color(0xFFEAD2A4),
                mixing ? t : 0,
              )!,
          );
        }
      }
    }
    if (mixing) {
      for (var arm = 0; arm < 6; arm++) {
        final path = Path();
        for (var step = 0; step <= 40; step++) {
          final f = step / 40;
          final angle = f * math.pi * 1.6 + arm * math.pi / 3 + phase * .42;
          final radius = r * (.12 + f * .64);
          final point = Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius * (.88 + math.sin(phase) * .04),
          );
          if (step == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(
              const Color(0x88BAA278),
              const Color(0x66C1A274),
              t,
            )!
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * (.018 + t * .012)
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          path.shift(Offset(r * .016, -r * .016)),
          Paint()
            ..color = const Color(0x88FFF3D2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .012,
        );
      }
      if (spoon != null) {
        final tip = Offset((spoon!.dx - .5) * u, (spoon!.dy - .51) * u);
        canvas.drawArc(
          Rect.fromCircle(center: tip, radius: r * .19),
          phase,
          math.pi * 1.2,
          false,
          Paint()
            ..color = const Color(0x88B49A70)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .035
            ..strokeCap = StrokeCap.round,
        );
      }
    } else {
      for (final kind in ['sal', 'fermento']) {
        final quantity = amount(kind);
        final random = math.Random(kind == 'sal' ? 13 : 17);
        for (var i = 0; i < (95 * quantity).round(); i++) {
          final x =
              (random.nextDouble() - .5) * r * .75 +
              (kind == 'sal' ? r * .24 : -r * .27);
          final y = (random.nextDouble() - .5) * r * .6;
          canvas.drawCircle(
            Offset(x, y),
            r * (kind == 'sal' ? .011 : .018),
            Paint()
              ..color = kind == 'sal'
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFBA9863),
          );
        }
      }
    }
    canvas.restore();
    if (!mixing && pouring != null && pourProgress < 1 && pourProgress > 0) {
      final destination =
          center +
          Offset(
            pouring == 'sal'
                ? r * .24
                : pouring == 'fermento'
                ? -r * .27
                : 0,
            0,
          );
      final origin = Offset(
        pourFrom == null
            ? center.dx + r * .5
            : center.dx + (pourFrom!.dx - .5) * u,
        center.dy - r * 1.45,
      );
      final fade = (math.sin(pourProgress * math.pi) * .9).clamp(0.0, 1.0);
      if (pouring == 'água') {
        _paintWaterStream(canvas, origin, destination, r, fade, pourProgress);
      } else if (pouring == 'farinha') {
        _paintFlourFall(canvas, origin, destination, r, fade, pourProgress);
      } else {
        final random = math.Random(89);
        final count = pouring == 'farinha' ? 65 : 30;
        for (var i = 0; i < count; i++) {
          final fall = (pourProgress * 2 + random.nextDouble()) % 1;
          final point =
              Offset.lerp(origin, destination, fall * fall)! +
              Offset((random.nextDouble() - .5) * r * .24 * fall, 0);
          canvas.drawCircle(
            point,
            r *
                (pouring == 'farinha'
                    ? .016 + random.nextDouble() * .025
                    : .012),
            Paint()
              ..color =
                  (pouring == 'fermento'
                          ? const Color(0xFFC4A574)
                          : const Color(0xFFFFF8E8))
                      .withValues(alpha: fade),
          );
        }
      }
    }
  }

  void _paintFlour(Canvas canvas, double r, double quantity) {
    final spread = math.sqrt(quantity);
    final random = math.Random(47);
    final mound = Path();
    for (var i = 0; i <= 72; i++) {
      final angle = i * math.pi / 36;
      final radius =
          r *
          spread *
          (.72 + math.sin(angle * 5) * .025 + math.cos(angle * 9) * .018);
      final point = Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius * .87,
      );
      if (i == 0) {
        mound.moveTo(point.dx, point.dy);
      } else {
        mound.lineTo(point.dx, point.dy);
      }
    }
    mound.close();
    final bounds = Rect.fromCircle(
      center: Offset.zero,
      radius: r * .78 * spread,
    );
    canvas.drawPath(
      mound.shift(Offset(0, r * .025)),
      Paint()
        ..color = const Color(0x336D766F)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .035),
    );
    canvas.drawPath(
      mound,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.2, -.25),
          colors: [Color(0xFFFFFFFF), Color(0xFFFAFAF7), Color(0xFFDFE2DF)],
          stops: [0, .65, 1],
        ).createShader(bounds),
    );
    // Fine, uneven dust rather than large grains or beige dough lumps.
    for (var i = 0; i < 650; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble()) * r * .81 * spread;
      final point = Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius * .87,
      );
      canvas.drawCircle(
        point,
        r * (.0015 + random.nextDouble() * .004),
        Paint()
          ..color = i % 4 == 0
              ? const Color(0x889FAAA4)
              : const Color(0xDDFFFFFF),
      );
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(-r * .10, -r * .08),
        width: r * .94 * spread,
        height: r * .57 * spread,
      ),
      math.pi * 1.07,
      math.pi * .58,
      false,
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .014
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintFlourFall(
    Canvas canvas,
    Offset origin,
    Offset destination,
    double r,
    double fade,
    double time,
  ) {
    final random = math.Random(89);
    final veil = Path()
      ..moveTo(origin.dx - r * .025, origin.dy)
      ..quadraticBezierTo(
        origin.dx - r * .07,
        destination.dy - r * .4,
        destination.dx - r * .22,
        destination.dy,
      )
      ..quadraticBezierTo(
        destination.dx,
        destination.dy + r * .035,
        destination.dx + r * .22,
        destination.dy,
      )
      ..quadraticBezierTo(
        origin.dx + r * .07,
        destination.dy - r * .4,
        origin.dx + r * .025,
        origin.dy,
      )
      ..close();
    canvas.drawPath(
      veil,
      Paint()
        ..color = Colors.white.withValues(alpha: fade * .27)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .025),
    );
    for (var i = 0; i < 380; i++) {
      final fall = (time * 2.2 + random.nextDouble()) % 1;
      final point =
          Offset.lerp(origin, destination, fall * fall)! +
          Offset(
            (random.nextDouble() - .5) * r * (.06 + .39 * fall),
            (random.nextDouble() - .5) * r * .035,
          );
      canvas.drawCircle(
        point,
        r * (.0018 + random.nextDouble() * .0055),
        Paint()
          ..color = Colors.white.withValues(
            alpha: fade * (.35 + random.nextDouble() * .65),
          ),
      );
    }
    for (var i = 0; i < 5; i++) {
      final drift = (time * 1.6 + i * .21) % 1;
      final puff =
          destination + Offset((i - 2) * r * .10 * drift, -r * .13 * drift);
      canvas.drawOval(
        Rect.fromCenter(
          center: puff,
          width: r * (.15 + drift * .20),
          height: r * .08,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: fade * (1 - drift) * .20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .035),
      );
    }
  }

  void _paintWaterStream(
    Canvas canvas,
    Offset origin,
    Offset destination,
    double r,
    double fade,
    double time,
  ) {
    final control = Offset(origin.dx - r * .12, destination.dy - r * .5);
    Offset point(double t) =>
        origin * ((1 - t) * (1 - t)) +
        control * (2 * (1 - t) * t) +
        destination * (t * t);
    Offset edge(double t, double side) {
      final tangent =
          (control - origin) * (2 * (1 - t)) +
          (destination - control) * (2 * t);
      final normal = Offset(-tangent.dy, tangent.dx) / tangent.distance;
      final width = r * (.045 + t * .035 + math.sin(t * 18 - time * 22) * .004);
      return point(t) + normal * width * side;
    }

    final body = Path();
    for (var i = 0; i <= 36; i++) {
      final p = edge(i / 36, -1);
      if (i == 0) {
        body.moveTo(p.dx, p.dy);
      } else {
        body.lineTo(p.dx, p.dy);
      }
    }
    for (var i = 36; i >= 0; i--) {
      final p = edge(i / 36, 1);
      body.lineTo(p.dx, p.dy);
    }
    body.close();
    canvas.drawPath(
      body,
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                const Color(0xFF70B6CC).withValues(alpha: fade * .9),
                const Color(0xFFD9F2F5).withValues(alpha: fade),
                const Color(0xFF92CEDB).withValues(alpha: fade * .9),
              ],
              stops: const [0, .4, 1],
            ).createShader(
              Rect.fromLTRB(
                math.min(origin.dx, destination.dx) - r * .1,
                origin.dy,
                math.max(origin.dx, destination.dx) + r * .1,
                destination.dy,
              ),
            ),
    );
    final shine = Path();
    for (var i = 0; i <= 36; i++) {
      final p = edge(i / 36, -.34);
      if (i == 0) {
        shine.moveTo(p.dx, p.dy);
      } else {
        shine.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      shine,
      Paint()
        ..color = Colors.white.withValues(alpha: fade * .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .018
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 3; i++) {
      final ripple = (time * 2 + i / 3) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: destination,
          width: r * (.18 + ripple * .72),
          height: r * (.05 + ripple * .20),
        ),
        Paint()
          ..color = const Color(0xFFD7F4F5)
              .withValues(alpha: fade * (1 - ripple) * .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .014,
      );
    }
    for (var i = 0; i < 7; i++) {
      final flight = (time * 2.3 + i * .17) % 1;
      final side = i.isEven ? -1 : 1;
      final p =
          destination +
          Offset(
            side * r * (.07 + flight * .20),
            -math.sin(flight * math.pi) * r * .20,
          );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: r * .027, height: r * .045),
        Paint()
          ..color = const Color(0xFFCAEAF0)
              .withValues(alpha: fade * (1 - flight)),
      );
    }
  }

  @override
  bool shouldRepaint(DoughMixturePainter old) => true;
}
