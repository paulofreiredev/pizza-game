import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_game/game/assisted_actions.dart';

void main() {
  test('repeated drops produce balanced positions within pizza regardless of pointer', () {
    for (var ingredient = 0; ingredient < 3; ingredient++) {
      final points = List.generate(
        20,
        (i) => assistedToppingPosition(i, ingredient),
      );
      expect(
        points.every((p) => (p - const Offset(.5, .51)).distance < .31 * .82),
        isTrue,
      );
      expect(
        points
            .take(8)
            .map((p) => (p.dx >= .5 ? 1 : 0) + (p.dy >= .51 ? 2 : 0))
            .toSet()
            .length,
        4,
      );
      expect(points.toSet().length, 20);
    }
  });
  test('all assisted cuts are straight diameters through center', () {
    final directions = <Offset>{};
    for (var i = 0; i < 4; i++) {
      final (from, to) = assistedPizzaCut(i);
      expect(
        ((from + to) / 2 - const Offset(.5, .51)).distance,
        lessThan(1e-10),
      );
      expect((from - to).distance, closeTo(.59, 1e-10));
      directions.add(from);
    }
    expect(directions.length, 4);
  });
  test('each cut advances along the remaining whole ingredient', () {
    for (final start in [0, 5]) {
      var previous = start == 0 ? -.82 : -.38;
      for (var i = 0; i < 5; i++) {
        final (from, to) = assistedIngredientCut(start + i);
        final plane = (from.dx - .5) / .31;
        expect(plane, greaterThan(previous));
        expect(plane, lessThan(start == 0 ? .82 : .38));
        expect(from.dx, to.dx);
        previous = plane;
      }
    }
  });
}
