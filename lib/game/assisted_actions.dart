import 'dart:math' as math;
import 'dart:ui';

/// Deterministic scattered positions with room between portions.
Offset assistedToppingPosition(
  int portion,
  int ingredient, {
  List<Offset> occupied = const [],
}) {
  final random = math.Random(491 + ingredient * 7919);
  final placed = <Offset>[];
  for (var i = 0; i <= portion; i++) {
    var best = const Offset(.5, .51);
    var bestDistance = -1.0;
    for (var candidate = 0; candidate < 350; candidate++) {
      final sector = (i * 3 + ingredient) % 4;
      final angle = (sector + random.nextDouble()) * math.pi / 2;
      final radius = math.sqrt(random.nextDouble()) * .225;
      final point = Offset(
        .5 + math.cos(angle) * radius,
        .51 + math.sin(angle) * radius,
      );
      var clearance = 1.0;
      for (final other in [...placed, ...occupied]) {
        clearance = math.min(clearance, (point - other).distanceSquared);
      }
      if (clearance > bestDistance) {
        best = point;
        bestDistance = clearance;
      }
      if (clearance >= .082 * .082) break;
    }
    placed.add(best);
  }
  return placed.last;
}

/// A straight diameter at one of the four supported orientations.
(Offset, Offset) assistedPizzaCut(int cut) {
  final direction =
      Offset(math.cos(cut * math.pi / 4), math.sin(cut * math.pi / 4)) * .295;
  return (const Offset(.5, .51) + direction, const Offset(.5, .51) - direction);
}

/// The next cutting plane always lies inside the remaining whole ingredient.
(Offset, Offset) assistedIngredientCut(int cut) {
  final onion = cut >= 5;
  final part = cut % 5;
  final x =
      .5 + .31 * (onion ? -.38 + (part + 1) * .14 : -.82 + (part + 1) * .27);
  return (Offset(x, .51 - .31 * .4), Offset(x, .51 + .31 * .3));
}

/// Snap a completed stroke to its nearest diameter, independent of cut order.
/// Short movements and strokes away from the pizza center are ignored.
int? nearestPizzaCut(Offset from, Offset to) {
  const center = Offset(.5, .51);
  final delta = to - from;
  if (delta.distance < .20) return null;
  final projection =
      (((center - from).dx * delta.dx + (center - from).dy * delta.dy) /
              delta.distanceSquared)
          .clamp(0.0, 1.0);
  if ((from + delta * projection - center).distance > .09) return null;
  final angle = math.atan2(delta.dy, delta.dx);
  return (angle / (math.pi / 4)).round() % 4;
}
