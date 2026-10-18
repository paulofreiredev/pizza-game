import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_game/ui/kitchen_painter.dart';

void main() {
  test(
    'sauce remains visible in the middle before and after pizza assembly',
    () async {
      for (final stage in ['toppings', 'slice']) {
        final recorder = ui.PictureRecorder();
        KitchenPainter(
          stage: stage,
          progress: 0,
          recipeId: 'margherita',
          showTool: false,
        ).paint(ui.Canvas(recorder), const ui.Size(400, 400));
        final picture = recorder.endRecording();
        final image = await picture.toImage(400, 400);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final offset = (204 * 400 + 200) * 4;
        expect(
          [
            data.getUint8(offset),
            data.getUint8(offset + 1),
            data.getUint8(offset + 2),
          ],
          [0xC8, 0x58, 0x38],
        );
        image.dispose();
        picture.dispose();
      }
    },
  );
}
