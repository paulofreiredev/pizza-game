import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_game/ui/dough_mixture.dart';

Future<List<int>> render(DoughMixturePainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const ui.Size(240, 240));
  final picture = recorder.endRecording();
  final image = await picture.toImage(240, 240);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = bytes!.buffer.asUint8List().toList();
  image.dispose();
  picture.dispose();
  return result;
}

void main() {
  test(
    'mixture visibly responds to stirring before another action is counted',
    () async {
      final before = await render(
        const DoughMixturePainter(
          ingredients: {},
          mixing: true,
          progress: .4,
          phase: 0,
        ),
      );
      final stirred = await render(
        const DoughMixturePainter(
          ingredients: {},
          mixing: true,
          progress: .4,
          phase: 1,
        ),
      );
      expect(stirred, isNot(orderedEquals(before)));
      final finished = await render(
        const DoughMixturePainter(
          ingredients: {},
          mixing: true,
          progress: 1,
          phase: 1,
        ),
      );
      expect(finished, isNot(orderedEquals(stirred)));
    },
  );
  test('water, flour and pouring have distinct visual feedback', () async {
    final water = await render(
      const DoughMixturePainter(
        ingredients: {'água'},
        mixing: false,
        progress: .25,
        phase: 0,
      ),
    );
    final flour = await render(
      const DoughMixturePainter(
        ingredients: {'farinha'},
        mixing: false,
        progress: .25,
        phase: 0,
      ),
    );
    final pouring = await render(
      const DoughMixturePainter(
        ingredients: {'farinha'},
        mixing: false,
        progress: .25,
        phase: 0,
        pouring: 'farinha',
        pourProgress: .4,
      ),
    );
    expect(water, isNot(orderedEquals(flour)));
    expect(pouring, isNot(orderedEquals(flour)));
  });
}
