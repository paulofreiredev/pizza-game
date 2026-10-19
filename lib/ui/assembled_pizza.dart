import 'package:flutter/material.dart';

import '../game/assisted_actions.dart';
import '../game/game_state.dart';
import 'kitchen_painter.dart';

/// The assembled pizza retains its ingredients when scaled for the oven tray.
class AssembledPizza extends CustomPainter {
  const AssembledPizza({
    required this.recipeId,
    required this.toppings,
    required this.toppingKinds,
  });

  factory AssembledPizza.recipe(String id) {
    final recipe = PizzaRecipe.recipes.firstWhere((recipe) => recipe.id == id);
    final order = PizzaOrder(0, recipe, '', '');
    final points = <Offset>[];
    final kinds = <String>[];
    for (
      var ingredient = 0;
      ingredient < recipe.toppings.length;
      ingredient++
    ) {
      final kind = recipe.toppings[ingredient];
      for (var portion = 0; portion < order.targetFor(kind); portion++) {
        points.add(assistedToppingPosition(portion, ingredient));
        kinds.add(kind);
      }
    }
    return AssembledPizza(recipeId: id, toppings: points, toppingKinds: kinds);
  }

  final String recipeId;
  final List<Offset> toppings;
  final List<String> toppingKinds;

  @override
  void paint(Canvas canvas, Size size) {
    const sourceCenter = Offset(200, 204);
    final scale = size.shortestSide / 260;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-sourceCenter.dx, -sourceCenter.dy);
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: sourceCenter, radius: 125)),
    );
    KitchenPainter(
      stage: 'toppings',
      progress: 1,
      recipeId: recipeId,
      toppings: toppings,
      toppingKinds: toppingKinds,
      pizzaOnly: true,
      showTool: false,
    ).paint(canvas, const Size(400, 400));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AssembledPizza oldDelegate) =>
      recipeId != oldDelegate.recipeId ||
      toppings != oldDelegate.toppings ||
      toppingKinds != oldDelegate.toppingKinds;
}
