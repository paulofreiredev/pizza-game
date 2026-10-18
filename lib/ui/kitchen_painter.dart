import 'dart:ui' as ui;

import 'ready_pizza_photo.dart';
import 'ingredient_details.dart';
import 'dough_mixture.dart';
import 'decorative_plant.dart';
import 'prepared_ingredient_bowl.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

class KitchenPainter extends CustomPainter {
  const KitchenPainter({
    required this.stage,
    required this.progress,
    required this.recipeId,
    this.toppings = const [],
    this.toppingKinds = const [],
    this.saucePoints = const [],
    this.cosmetic = 'cream',
    this.ovenStyle = 'oven_default',
    this.plantStyle = 'plant_default',
    this.toolPosition,
    this.showTool = true,
    this.ovenOpen = true,
    this.ovenDoorProgress,
    this.cuttingTrail = const [],
    this.ovenActions = 0,
    this.cutAnimation = 1,
    this.cutCount = -1,
    this.boardOnly = false,
    this.doughIngredients = const {},
    this.pourIngredient,
    this.pourProgress = 1,
    this.pourFrom,
    this.mixPhase = 0,
    this.readyPizzaImage,
  });
  final String stage, recipeId, cosmetic, ovenStyle, plantStyle;
  final double progress;
  final ui.Image? readyPizzaImage;
  final Set<String> doughIngredients;
  final String? pourIngredient;
  final double pourProgress, mixPhase;
  final Offset? pourFrom;
  final Offset? toolPosition;
  final bool showTool, ovenOpen, boardOnly;
  final int ovenActions, cutCount;
  final double cutAnimation;
  final double? ovenDoorProgress;
  final List<Offset> cuttingTrail;
  final List<Offset> toppings, saucePoints;
  final List<String> toppingKinds;

  @override
  void paint(Canvas c, Size s) {
    final u = math.min(s.width, s.height), r = u * .31;
    final center = Offset(s.width * .5, s.height * .51);
    final sweet = recipeId == 'chocolate';
    final tool = toolPosition == null
        ? center
        : center +
              Offset((toolPosition!.dx - .5) * u, (toolPosition!.dy - .51) * u);
    void dot(Offset p, double radius, Color color) =>
        c.drawCircle(p, radius, Paint()..color = color);
    void box(Rect rect, Color color, [double round = 12]) {
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(round));
      c.drawRRect(
        rr.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x25613927),
      );
      c.drawRRect(rr, Paint()..color = color);
      c.drawRRect(
        rr,
        Paint()
          ..color = const Color(0x55684332)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Every ingredient keeps its own silhouette, even at the oven's scale.
    void ingredient(
      Offset position,
      String kind,
      int seed, [
      double scale = 1,
    ]) {
      c.save();
      c.translate(position.dx, position.dy);
      c.rotate(math.sin(seed * 2.3) * .55);
      c.scale(r * scale);
      final bounds = Rect.fromLTRB(-.13, -.15, .13, .16);
      Paint fill(Color color) => Paint()..color = color;
      void ellipse(Rect rect, Color color) => c.drawOval(rect, fill(color));
      if (kind == 'morango') {
        final berry = Path()
          ..moveTo(0, -.105)
          ..cubicTo(-.10, -.18, -.17, -.085, -.115, .015)
          ..cubicTo(-.09, .075, -.025, .145, 0, .16)
          ..cubicTo(.035, .14, .10, .055, .12, -.01)
          ..cubicTo(.17, -.11, .075, -.175, 0, -.105)
          ..close();
        c.drawPath(
          berry.shift(const Offset(.012, .022)),
          fill(const Color(0x48653526)),
        );
        c.drawPath(
          berry,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFF8274), Color(0xFFD82E40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
        );
        if (seed.isOdd) {
          final flesh = Path()
            ..moveTo(0, -.08)
            ..cubicTo(-.095, -.15, -.10, -.025, -.06, .04)
            ..quadraticBezierTo(-.025, .11, 0, .135)
            ..quadraticBezierTo(.10, .025, .07, -.055)
            ..quadraticBezierTo(.04, -.12, 0, -.08);
          c.drawPath(flesh, fill(const Color(0xFFFFB7A0)));
          c.drawPath(
            Path()
              ..moveTo(0, -.065)
              ..quadraticBezierTo(-.025, .015, 0, .11)
              ..quadraticBezierTo(.035, .005, 0, -.065),
            fill(const Color(0xFFFFE2C2)),
          );
        }
        for (var j = 0; j < 9; j++) {
          final row = j ~/ 3;
          final x = (j % 3 - 1) * (.065 - row * .014);
          ellipse(
            Rect.fromCenter(
              center: Offset(x, -.06 + row * .063),
              width: .013,
              height: .026,
            ),
            const Color(0xFFFFE399),
          );
        }
        ellipse(
          Rect.fromLTWH(-.085, -.085, .035, .07),
          const Color(0x55FFFFFF),
        );
        for (var j = 0; j < 5; j++) {
          final angle = -math.pi + j * math.pi / 4;
          final leaf = Path()
            ..moveTo(0, -.11)
            ..quadraticBezierTo(
              math.cos(angle) * .055,
              -.15 + math.sin(angle) * .035,
              math.cos(angle) * .10,
              -.11 + math.sin(angle) * .07,
            )
            ..quadraticBezierTo(math.cos(angle) * .04, -.09, 0, -.11);
          c.drawPath(
            leaf,
            fill(j.isEven ? const Color(0xFF3F7848) : const Color(0xFF74A652)),
          );
        }
      } else if (kind == 'camarão') {
        paintShrimp(c, Offset.zero, .16);
      } else if (kind == 'catupiri') {
        paintCatupiri(c, Offset.zero, .20);
      } else if ((kind == 'frango' || kind == 'carne de sol')) {
        for (var j = 0; j < 7; j++) {
          final q = Offset((j % 3 - 1) * .07, (j ~/ 3 - 1) * .06);
          c.drawLine(
            q,
            q + const Offset(.10, -.045),
            Paint()
              ..color = j.isEven
                  ? const Color(0xFFE6BC7C)
                  : const Color(0xFFFFDEA7)
              ..strokeWidth = .035
              ..strokeCap = StrokeCap.round,
          );
        }
      } else if (kind == 'calabresa') {
        c.scale(1.1);
        ellipse(
          Rect.fromCircle(center: const Offset(.009, .018), radius: .12),
          const Color(0x486B3524),
        );
        ellipse(
          Rect.fromCircle(center: Offset.zero, radius: .12),
          const Color(0xFF783526),
        );
        final meat = Path();
        for (var j = 0; j < 18; j++) {
          final angle = j * math.pi * 2 / 18;
          final d = .104 + math.sin(j * 3.7) * .006;
          final p = Offset(math.cos(angle) * d, math.sin(angle) * d);
          if (j == 0) {
            meat.moveTo(p.dx, p.dy);
          } else {
            meat.lineTo(p.dx, p.dy);
          }
        }
        meat.close();
        c.drawPath(
          meat,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFDA8965), Color(0xFFAF4E3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
        );
        for (var j = 0; j < 8; j++) {
          final a = j * 2.399 + seed;
          final d = .035 + (j % 3) * .022;
          ellipse(
            Rect.fromCenter(
              center: Offset(math.cos(a) * d, math.sin(a) * d),
              width: .023 + (j % 2) * .012,
              height: .016,
            ),
            const Color(0xFFFFD6A5),
          );
        }
      } else if (kind == 'cebola') {
        c.scale(1.25);
        ellipse(
          Rect.fromCircle(center: Offset.zero, radius: .13),
          const Color(0x44FFEAF4),
        );
        for (var j = 0; j < 3; j++) {
          c.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: .125 - j * .031),
            seed.isEven ? .2 : -.5,
            math.pi * 1.8,
            false,
            Paint()
              ..color = j.isEven
                  ? const Color(0xCCA86A9B)
                  : const Color(0xDDF9DDEC)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .016,
          );
        }
      } else if ([
        'queijo',
        'muçarela',
        'provolone',
        'gorgonzola',
        'parmesão',
      ].contains(kind)) {
        for (var j = 0; j < 24; j++) {
          final x = math.cos(j * 2.4 + seed) * (.10 + (j % 4) * .045);
          final y = math.sin(j * 2.4 + seed) * (.09 + (j % 3) * .045);
          final strand = Path()
            ..moveTo(x - .065, y - .018)
            ..quadraticBezierTo(x, y + .025, x + .075, y - .012);
          c.drawPath(
            strand.shift(const Offset(.006, .01)),
            Paint()
              ..color = const Color(0x447A512B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .023
              ..strokeCap = StrokeCap.round,
          );
          c.drawPath(
            strand,
            Paint()
              ..color = j.isEven
                  ? const Color(0xFFFFD467)
                  : const Color(0xFFFFEDAC)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .018
              ..strokeCap = StrokeCap.round,
          );
          c.drawPath(
            strand.shift(const Offset(0, -.004)),
            Paint()
              ..color = const Color(0x99FFF7D4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .005
              ..strokeCap = StrokeCap.round,
          );
        }
      } else if (kind == 'chocolate') {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-.12, -.09, .12, .10),
            const Radius.circular(.018),
          ),
          fill(const Color(0xFF482B26)),
        );
        for (var j = 0; j < 4; j++) {
          final rect = Rect.fromLTWH(
            -.105 + (j % 2) * .112,
            -.075 + (j ~/ 2) * .085,
            .095,
            .07,
          );
          c.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(.012)),
            Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFA46E4F), Color(0xFF69402F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(rect),
          );
        }
      } else if (kind == 'manjericão') {
        final leaf = Path()
          ..moveTo(-.14, .04)
          ..cubicTo(-.14, -.11, .08, -.13, .15, -.06)
          ..cubicTo(.12, .065, -.02, .12, -.14, .04);
        c.drawPath(
          leaf.shift(const Offset(.008, .014)),
          fill(const Color(0x44624626)),
        );
        c.drawPath(leaf, fill(const Color(0xFF55834A)));
        c.drawLine(
          const Offset(-.12, .035),
          const Offset(.12, -.055),
          Paint()
            ..color = const Color(0xFF99B965)
            ..strokeWidth = .012,
        );
      } else if (kind == 'confeitos') {
        for (var j = 0; j < 5; j++) {
          final p = Offset(math.cos(j * 2) * .065, math.sin(j * 2) * .065);
          c.drawLine(
            p,
            p + const Offset(.025, .018),
            Paint()
              ..color = [
                Colors.pinkAccent,
                Colors.amber,
                Colors.lightBlueAccent,
                Colors.lightGreen,
                Colors.white,
              ][j]
              ..strokeWidth = .021
              ..strokeCap = StrokeCap.round,
          );
        }
      }
      c.restore();
    }

    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE8BF89), Color(0xFFCF985F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & s),
    );
    for (var i = 0; i < 9; i++) {
      final y = s.height * i / 8;
      c.drawLine(
        Offset(0, y),
        Offset(s.width, y),
        Paint()
          ..color = const Color(0x337D4F2D)
          ..strokeWidth = 2,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * ((i * .27) % 1), y + 12),
          width: 70,
          height: 9,
        ),
        Paint()
          ..color = const Color(0x127D4F2D)
          ..style = PaintingStyle.stroke,
      );
    }
    final clothColor = switch (cosmetic) {
      'sage' => const Color(0x556C895C),
      'rose' => const Color(0x55BB715D),
      'sunset' => const Color(0x55DCA438),
      _ => const Color(0x5571A4C2),
    };
    c.save();
    c.translate(s.width * .08, s.height * .72);
    c.rotate(-.12);
    final cloth = Rect.fromLTWH(-s.width * .15, 0, s.width * .5, s.height * .5);
    c.clipRect(cloth);
    c.drawRect(cloth, Paint()..color = const Color(0xFFFFF2DC));
    for (var i = -4; i < 40; i++) {
      c.drawRect(
        Rect.fromLTWH(i * 22, 0, 11, s.height),
        Paint()..color = clothColor,
      );
      c.drawRect(
        Rect.fromLTWH(-s.width, i * 22, s.width * 2, 11),
        Paint()..color = clothColor,
      );
    }
    c.restore();
    if (plantStyle == 'plant_fern' || plantStyle == 'plant_flowers') {
      c.save();
      c.translate(s.width * .80, s.height * .025);
      DecorativePlant(plantStyle).paint(c, Size(u * .18, u * .215));
      c.restore();
    }
    if (boardOnly) return;
    if (stage == 'oven') {
      final oven = Rect.fromCenter(
        center: center,
        width: u * .9,
        height: u * .78,
      );
      box(
        oven,
        ovenStyle == 'oven_copper'
            ? const Color(0xFFBE784F)
            : ovenStyle == 'oven_rose'
            ? const Color(0xFFD39A9E)
            : const Color(0xFF9AABA0),
        24,
      );
      box(oven.deflate(u * .06), const Color(0xFF483E36), 16);
      final glow = Rect.fromCenter(
        center: center,
        width: u * .68,
        height: u * .43,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(glow, const Radius.circular(12)),
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(
                const Color(0xFFE7B86D),
                const Color(0xFFFF9B32),
                progress,
              )!,
              const Color(0xFF79412C),
            ],
          ).createShader(glow),
      );
      if (ovenActions >= 3 && readyPizzaImage != null) {
        paintReadyPizza(
          c,
          readyPizzaImage!,
          Rect.fromCircle(center: center, radius: r * .64),
        );
      } else if (ovenActions > 0) {
        dot(center, r * .64, const Color(0xFFDBA658));
        dot(
          center,
          r * .53,
          sweet ? const Color(0xFF6F3926) : const Color(0xFFC85838),
        );
        for (var i = 0; i < toppings.length; i++) {
          final point = toppings[i];
          final p =
              center + Offset((point.dx - .5) * u, (point.dy - .51) * u) * .64;
          if ((p - center).distance > r * .57) continue;
          ingredient(
            p,
            i < toppingKinds.length
                ? toppingKinds[i]
                : (sweet ? 'morango' : 'calabresa'),
            i,
            .64,
          );
        }
      }
      final opening = (ovenDoorProgress ?? (ovenOpen ? 1.0 : 0.0)).clamp(
        0.0,
        1.0,
      );
      final door = Rect.fromLTRB(
        center.dx - u * (.34 + .05 * opening),
        glow.top + (oven.bottom - u * .045 - glow.top) * opening,
        center.dx + u * (.34 + .05 * opening),
        glow.bottom + (oven.bottom + u * .085 - glow.bottom) * opening,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(door, const Radius.circular(12)),
        Paint()
          ..color = Color.lerp(
            const Color(0x66647771),
            const Color(0xFF667A70),
            opening,
          )!,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(door, const Radius.circular(12)),
        Paint()
          ..color = const Color(0xFF83988C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * .018,
      );
      box(
        Rect.fromCenter(
          center: Offset(center.dx, oven.bottom - u * .04 + u * .06 * opening),
          width: u * .43,
          height: u * .035,
        ),
        const Color(0xFFDDD4B9),
        6,
      );
      return;
    }
    if (stage == 'ingredients' || stage == 'mix') {
      dot(center + const Offset(0, 8), r * 1.1, const Color(0x28704C32));
      dot(center, r * 1.08, const Color(0xFFA7B8AC));
      dot(center, r * .94, const Color(0xFF677E77));
      DoughMixturePainter(
        ingredients: doughIngredients,
        mixing: stage == 'mix',
        progress: progress,
        phase: mixPhase,
        pouring: pourIngredient,
        pourProgress: pourProgress,
        pourFrom: pourFrom,
        spoon: toolPosition,
      ).paint(c, s);
      if (stage == 'mix' && showTool) {
        c.save();
        c.translate(tool.dx, tool.dy);
        box(
          Rect.fromLTWH(-u * .018, -r * 1.25, u * .036, r * 1.45),
          const Color(0xFFBA8353),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0, r * .14),
            width: u * .09,
            height: u * .13,
          ),
          Paint()..color = const Color(0xFFAB744A),
        );
        c.restore();
      }
      return;
    }
    box(
      Rect.fromCenter(
        center: center + const Offset(0, 5),
        width: r * 2.7,
        height: r * 2.5,
      ),
      const Color(0xFFE8BC7E),
      u * .07,
    );
    if (stage == 'chop') {
      final cuts = cutCount < 0
          ? (progress.clamp(0.0, 1.0) * 10).floor()
          : cutCount.clamp(0, 10);
      final t = cutAnimation.clamp(0.0, 1.0);
      double falling(double time) {
        if (time < .2) return 0;
        if (time < .78) {
          final fall = (time - .2) / .58;
          return fall * fall;
        }
        return 1 - math.sin((time - .78) / .22 * math.pi) * .16;
      }

      double pieceTime(int index) => index == cuts - 1
          ? ((cuts == 5 || cuts == 10) ? (t / .55).clamp(0.0, 1.0) : t)
          : 1;
      final sausageBowl = Offset(s.width * .32, s.height * .86);
      final onionBowl = Offset(s.width * .68, s.height * .86);
      for (final bowl in [sausageBowl, onionBowl]) {
        c.drawOval(
          Rect.fromCenter(
            center: bowl + Offset(0, u * .024),
            width: u * .23,
            height: u * .11,
          ),
          Paint()..color = const Color(0x28704C32),
        );
        c.drawOval(
          Rect.fromCenter(center: bowl, width: u * .23, height: u * .16),
          Paint()..color = const Color(0xFFA7B8AC),
        );
        c.drawOval(
          Rect.fromCenter(
            center: bowl - Offset(0, u * .009),
            width: u * .20,
            height: u * .125,
          ),
          Paint()..color = const Color(0xFFE6EDDD),
        );
        c.drawOval(
          Rect.fromCenter(
            center: bowl - Offset(0, u * .009),
            width: u * .175,
            height: u * .105,
          ),
          Paint()..color = const Color(0xFF788F83),
        );
      }
      void ingredientGroup(Offset bowl, double transfer) {
        final move = Curves.easeInOutCubic.transform(transfer.clamp(0.0, 1.0));
        final target = Offset.lerp(center, bowl, move)!;
        c.translate(target.dx, target.dy);
        c.scale(1 - move * .64);
        c.translate(-center.dx, -center.dy);
      }

      final sausageCuts = math.min(cuts, 5);
      final onionCuts = math.max(0, cuts - 5);
      final sausageStored = cuts > 5 || (cuts == 5 && t >= .98);
      if (!sausageStored) {
        c.save();
        ingredientGroup(
          sausageBowl,
          cuts > 5
              ? 1
              : cuts == 5
              ? (t - .55) / .43
              : 0,
        );
        final sausage = Rect.fromCenter(
          center: center,
          width: r * 1.64,
          height: r * .35,
        );
        final remainingX = center.dx + r * (-.82 + sausageCuts * .27);
        // One continuous casing; the clip exposes only the uncut remainder.
        c.save();
        c.clipRect(
          Rect.fromLTRB(
            remainingX,
            sausage.top - r * .06,
            sausage.right + r * .08,
            sausage.bottom + r * .07,
          ),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            sausage.shift(Offset(0, r * .025)),
            Radius.circular(r * .175),
          ),
          Paint()..color = const Color(0x356B3926),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(sausage, Radius.circular(r * .175)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFC97B53), Color(0xFF9C4833), Color(0xFF743624)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(sausage),
        );
        c.drawArc(
          sausage.deflate(r * .055),
          math.pi * 1.08,
          math.pi * .82,
          false,
          Paint()
            ..color = const Color(0x55FFD3A1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .025,
        );
        c.restore();
        if (sausageCuts > 0) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(remainingX + r * .025, sausage.center.dy),
              width: r * .065,
              height: r * .30,
            ),
            Paint()..color = const Color(0xFFCA8763),
          );
        }
        // Only slices already cut leave the sausage and settle below it.
        for (var i = 0; i < sausageCuts; i++) {
          final time = pieceTime(i);
          final separation = (time / .3).clamp(0.0, 1.0);
          final drop = falling(time);
          final p =
              center +
              Offset(
                r * (-.82 + (i + .5) * .27 - .07 * separation),
                r * ((.29 + .045 * (i % 2)) * drop),
              );
          final piece = Rect.fromCenter(
            center: p,
            width: r * .20,
            height: r * .32,
          );
          c.drawOval(
            piece.shift(Offset(0, r * .018)),
            Paint()..color = const Color(0x356B3926),
          );
          c.drawOval(piece, Paint()..color = const Color(0xFF783526));
          c.drawOval(
            piece.deflate(r * .019),
            Paint()..color = const Color(0xFFC77C5C),
          );
          for (var j = 0; j < 6; j++) {
            final a = j * 2.399 + i;
            c.drawOval(
              Rect.fromCenter(
                center:
                    p + Offset(math.cos(a) * r * .055, math.sin(a) * r * .09),
                width: r * .026,
                height: r * .019,
              ),
              Paint()..color = const Color(0xFFFFD4A5),
            );
          }
        }
        c.restore();
      } else {
        c.save();
        c.translate(sausageBowl.dx - u * .125, sausageBowl.dy - u * .125);
        const PreparedIngredientBowl('calabresa')
            .paint(c, Size.square(u * .25));
        c.restore();
      }
      final onionVisible = cuts > 5 || (cuts == 5 && t >= .98);
      if (onionVisible && !(cuts == 10 && t >= .98)) {
        c.save();
        ingredientGroup(onionBowl, cuts == 10 ? (t - .55) / .43 : 0);
        final onion = center;
        final onionRect = Rect.fromCircle(center: onion, radius: r * .38);
        final onionEdge = onion.dx + r * (-.38 + onionCuts * .14);
        c.save();
        c.clipRect(
          Rect.fromLTRB(
            onionEdge,
            onionRect.top - r * .14,
            onionRect.right + r * .05,
            onionRect.bottom + r * .12,
          ),
        );
        dot(onion + Offset(0, r * .025), r * .38, const Color(0x30674538));
        c.drawOval(
          onionRect,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.35, -.4),
              colors: [Color(0xFFE2B7C4), Color(0xFFB77E9B), Color(0xFF8A536D)],
            ).createShader(onionRect),
        );
        for (var j = -2; j <= 2; j++) {
          final curve = Path()
            ..moveTo(onion.dx, onionRect.top)
            ..cubicTo(
              onion.dx + j * r * .15,
              onion.dy - r * .15,
              onion.dx + j * r * .13,
              onion.dy + r * .21,
              onion.dx,
              onionRect.bottom,
            );
          c.drawPath(
            curve,
            Paint()
              ..color = const Color(0x55F9DBD9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * .012,
          );
        }
        final stem = Path()
          ..moveTo(onion.dx - r * .05, onionRect.top + r * .015)
          ..lineTo(onion.dx - r * .028, onionRect.top - r * .10)
          ..lineTo(onion.dx + r * .025, onionRect.top - r * .12)
          ..lineTo(onion.dx + r * .05, onionRect.top + r * .02)
          ..close();
        c.drawPath(stem, Paint()..color = const Color(0xFFA78C58));
        for (var j = -1; j <= 1; j++) {
          c.drawLine(
            Offset(onion.dx + j * r * .02, onionRect.bottom - r * .01),
            Offset(onion.dx + j * r * .055, onionRect.bottom + r * .07),
            Paint()
              ..color = const Color(0xFF9C764F)
              ..strokeWidth = r * .009
              ..strokeCap = StrokeCap.round,
          );
        }
        c.restore();
        if (onionCuts > 0) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(onionEdge + r * .015, onion.dy),
              width: r * .055,
              height: r * .58,
            ),
            Paint()..color = const Color(0xFFF4DBE3),
          );
        }
        for (var i = 0; i < onionCuts; i++) {
          final time = pieceTime(i + 5);
          final separation = (time / .3).clamp(0.0, 1.0);
          final p =
              onion +
              Offset(
                r * (-.38 + (i + .5) * .14 - .12 * separation),
                r * (.29 + .03 * (i % 2)) * falling(time),
              );
          final piece = Rect.fromCenter(
            center: p,
            width: r * .12,
            height: r * (.48 + .08 * math.sin((i + 1) * math.pi / 6)),
          );
          c.drawOval(
            piece.shift(Offset(0, r * .012)),
            Paint()..color = const Color(0x25674538),
          );
          c.drawOval(piece, Paint()..color = const Color(0xFFF9E6EA));
          for (var j = 0; j < 3; j++) {
            c.drawOval(
              piece.deflate(r * (.007 + j * .014)),
              Paint()
                ..color = j.isEven
                    ? const Color(0xFFBA8AA6)
                    : const Color(0xFFEAC4D7)
                ..style = PaintingStyle.stroke
                ..strokeWidth = r * .009,
            );
          }
        }
        c.restore();
      }
      if (cuts == 10 && t >= .98) {
        c.save();
        c.translate(onionBowl.dx - u * .125, onionBowl.dy - u * .125);
        const PreparedIngredientBowl('cebola').paint(c, Size.square(u * .25));
        c.restore();
      }
      final transferring = (cuts == 5 && t >= .55 && t < .98) || cuts == 10;
      if (showTool && !transferring && cuts < 10) {
        c.save();
        c.translate(tool.dx, tool.dy);
        box(
          Rect.fromLTWH(-r * .04, -r * .42, r * .10, r * .65),
          const Color(0xFFD8E4E2),
          3,
        );
        c.drawLine(
          Offset(-r * .035, -r * .38),
          Offset(-r * .035, r * .20),
          Paint()
            ..color = const Color(0xFFFAFFFB)
            ..strokeWidth = r * .015,
        );
        box(
          Rect.fromLTWH(-r * .04, r * .23, r * .10, r * .36),
          const Color(0xFF655148),
          5,
        );
        c.restore();
      }
      return;
    }
    if (readyPizzaImage != null &&
        ['slice', 'serve', 'complete'].contains(stage)) {
      paintReadyPizza(
        c,
        readyPizzaImage!,
        Rect.fromCircle(center: center, radius: r),
      );
    } else {
      final doughR = stage == 'knead'
          ? r * (.6 + progress * .08)
          : stage == 'roll'
          ? r * (.68 + progress * .32)
          : r;
      dot(center + const Offset(0, 5), doughR, const Color(0x35613D26));
      dot(center, doughR, const Color(0xFFE9BB75));
      dot(
        center - Offset(0, doughR * .035),
        doughR * .92,
        const Color(0xFFF5D99C),
      );
      if (stage == 'knead' || stage == 'roll') {
        c.drawArc(
          Rect.fromCircle(center: center, radius: doughR * .65),
          .4,
          2.2,
          false,
          Paint()
            ..color = const Color(0x55BB8A50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        if (stage == 'roll' && showTool) {
          c.save();
          c.translate(tool.dx, tool.dy);
          box(
            Rect.fromLTWH(-r * 1.3, -u * .025, r * 2.6, u * .05),
            const Color(0xFF98613C),
            8,
          );
          box(
            Rect.fromLTWH(-r * .9, -u * .055, r * 1.8, u * .11),
            const Color(0xFFD4A36A),
            10,
          );
          c.restore();
        }
        return;
      }
      final sauce = sweet ? const Color(0xFF6C3828) : const Color(0xFFC85838);
      if (stage == 'sauce') {
        c.save();
        c.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: r * .82)),
        );
        for (final point in saucePoints) {
          dot(
            center + Offset((point.dx - .5) * u, (point.dy - .51) * u),
            u * .065,
            sauce,
          );
        }
        c.restore();
        if (showTool) {
          c.save();
          c.translate(tool.dx, tool.dy);
          box(
            Rect.fromLTWH(-u * .016, -u * .22, u * .032, u * .23),
            const Color(0xFFBA8353),
            8,
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: u * .09,
              height: u * .12,
            ),
            Paint()..color = const Color(0xFFAB744A),
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: u * .065,
              height: u * .085,
            ),
            Paint()..color = sauce,
          );
          c.restore();
        }
      } else {
        dot(center, r * .83, sauce);
        c.save();
        c.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: r * .83)),
        );
        const cheeses = {
          'queijo',
          'muçarela',
          'provolone',
          'gorgonzola',
          'parmesão',
        };
        final layers = List.generate(toppings.length, (i) => i)
          ..sort((a, b) {
            int layer(int i) =>
                i < toppingKinds.length && cheeses.contains(toppingKinds[i])
                ? 0
                : i < toppingKinds.length && toppingKinds[i] == 'cebola'
                ? 2
                : 1;
            return layer(a).compareTo(layer(b));
          });
        for (final i in layers) {
          final p =
              center +
              Offset((toppings[i].dx - .5) * u, (toppings[i].dy - .51) * u);
          if ((p - center).distance > r * .9) continue;
          final kind = i < toppingKinds.length
              ? toppingKinds[i]
              : sweet
              ? 'morango'
              : 'calabresa';
          ingredient(p, kind, i);
        }
        c.restore();
      }
    }
    if (stage == 'slice' && cuttingTrail.length > 1) {
      c.save();
      c.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: r * .96)),
      );
      final trail = Path();
      for (var i = 0; i < cuttingTrail.length; i++) {
        final point =
            center +
            Offset(
              (cuttingTrail[i].dx - .5) * u,
              (cuttingTrail[i].dy - .51) * u,
            );
        if (i == 0) {
          trail.moveTo(point.dx, point.dy);
        } else {
          trail.lineTo(point.dx, point.dy);
        }
      }
      c.drawPath(
        trail,
        Paint()
          ..color = const Color(0xFF9D693F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * .008
          ..strokeCap = StrokeCap.round,
      );
      c.restore();
    }
    if (stage == 'slice' && showTool) {
      c.save();
      c.translate(tool.dx, tool.dy);
      box(
        Rect.fromLTWH(-u * .018, -u * .20, u * .036, u * .17),
        const Color(0xFF655148),
        6,
      );
      dot(Offset.zero, u * .055, const Color(0xFFD8E4E2));
      c.drawCircle(
        Offset.zero,
        u * .044,
        Paint()
          ..color = const Color(0xFF8D9F9B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      dot(Offset.zero, u * .008, const Color(0xFF655148));
      c.restore();
    }
    if (stage == 'slice' || stage == 'serve' || stage == 'complete') {
      final lines = stage == 'slice' ? (progress * 4).floor() : 4;
      for (var i = 0; i < lines; i++) {
        final a = i * math.pi / 4;
        final delta = Offset(math.cos(a), math.sin(a)) * r * .96;
        c.drawLine(
          center - delta,
          center + delta,
          Paint()
            ..color = const Color(0xFF9D693F)
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant KitchenPainter oldDelegate) => true;
}
