import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_game/game/game_state.dart';
import 'package:pizza_game/ui/kitchen_materials.dart';
import 'package:pizza_game/ui/natural_kitchen.dart';

Future<int> render(FoodSprite sprite) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.transparent, BlendMode.src);
  sprite.paint(canvas, const Size(100, 100));
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 100);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final hash = Object.hashAll(bytes.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return hash;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preparation uses distinct realistic salt materials and ingredient portions', () async {
    final beforeLoading = FoodSprite('sal');
    await KitchenMaterials.load();
    expect(
      FoodSprite('sal').shouldRepaint(beforeLoading),
      isTrue,
      reason: 'The first salt drawing must repaint after the detailed images finish loading',
    );
    for (final style in ['oven_default', 'oven_rose', 'oven_copper']) {
      final recorder = ui.PictureRecorder();
      expect(
        KitchenMaterials.paintOven(
          Canvas(recorder),
          const Rect.fromLTWH(0, 0, 100, 80),
          style,
        ),
        isTrue,
      );
      recorder.endRecording().dispose();
    }
    final saltDrawings = <int>{};
    for (final material in ['default', 'glass', 'wood', 'steel']) {
      expect(
        saltDrawings.add(
          await render(FoodSprite('sal', saltStyle: 'salt_$material')),
        ),
        isTrue,
        reason: material,
      );
    }
    final ingredients = PizzaRecipe.recipes
        .expand((recipe) => recipe.toppings)
        .toSet();
    for (final kind in ingredients) {
      final recorder = ui.PictureRecorder();
      expect(
        KitchenMaterials.paintFood(
          Canvas(recorder),
          const Rect.fromLTWH(0, 0, 100, 100),
          kind,
        ),
        isTrue,
        reason: kind,
      );
      recorder.endRecording().dispose();
    }
    expect(
      await render(FoodSprite('cebola', bowl: false)),
      isNot(await render(FoodSprite('morango', bowl: false))),
    );
  });
}
