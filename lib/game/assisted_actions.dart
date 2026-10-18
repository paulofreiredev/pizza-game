import 'dart:math' as math;
import 'dart:ui';

/// Board-normalized positions, independent of the child's drop accuracy.
Offset assistedToppingPosition(int portion, int ingredient) {
  final angle = (portion % 8) * math.pi / 4 + math.pi / 4 + ingredient * .29;
  final radius = .17 + (portion ~/ 8) * .025;
  return Offset(.5 + math.cos(angle) * radius, .51 + math.sin(angle) * radius);
}

/// Each intention to cut finishes the next straight, centered diameter.
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
