import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_game/game/game_state.dart';
import 'package:pizza_game/ui/kitchen_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every recipe has a decodable bundled photograph', () async {
    for (final recipe in PizzaRecipe.recipes) {
      final data = await rootBundle.load(
        'assets/images/recipes/${recipe.id}.png',
      );
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 64,
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 64, reason: recipe.id);
      frame.image.dispose();
      codec.dispose();
    }
  });
  test(
    'after baking the photograph replaces the illustrated toppings',
    () async {
      final source = ui.PictureRecorder();
      ui.Canvas(source).drawColor(const ui.Color(0xFFAA2244), ui.BlendMode.src);
      final sourcePicture = source.endRecording();
      final photo = await sourcePicture.toImage(64, 64);
      final recorder = ui.PictureRecorder();
      KitchenPainter(
        stage: 'slice',
        progress: 0,
        recipeId: 'calabresa',
        readyPizzaImage: photo,
        showTool: false,
        toppings: const [ui.Offset(.5, .51)],
        toppingKinds: const ['calabresa'],
      ).paint(ui.Canvas(recorder), const ui.Size(300, 300));
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 300);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final center = (153 * 300 + 150) * 4;
      expect(
        [
          data.getUint8(center),
          data.getUint8(center + 1),
          data.getUint8(center + 2),
        ],
        [170, 34, 68],
      );
      image.dispose();
      picture.dispose();
      photo.dispose();
      sourcePicture.dispose();
    },
  );
}
