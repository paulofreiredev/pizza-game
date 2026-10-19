import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared source images keep ingredients consistent on the counter and in flight.
class KitchenMaterials {
  static ui.Image? _food, _seasonings, _bases, _ovens;
  static Future<void>? _loading;
  static int _revision = 0;
  static int get revision => _revision;
  static const portions = <String, int>{
    'queijo': 0,
    'muçarela': 0,
    'calabresa': 1,
    'cebola': 2,
    'morango': 3,
    'frango': 4,
    'carne de sol': 5,
    'camarão': 6,
    'manjericão': 7,
    'tomate': 8,
    'catupiri': 9,
    'provolone': 10,
    'gorgonzola': 11,
    'parmesão': 12,
    'chocolate': 13,
    'confeitos': 14,
    'massa': 15,
  };
  static const preparation = <String, int>{
    'farinha': 16,
    'água': 17,
    'fermento': 18,
    'molho': 19,
    'creme de chocolate': 20,
  };

  static Future<void> load() => _loading ??= _load();

  static Future<void> _load() async {
    final images = await Future.wait([
      _decode('assets/images/pizza-materials.png'),
      _decode('assets/images/seasonings.png'),
      _decode('assets/images/pizza-bases.png'),
      _decode('assets/images/ovens.png'),
    ]);
    _food = images[0];
    _seasonings = images[1];
    _bases = images[2];
    _ovens = images[3];
    _revision++;
  }

  static Future<ui.Image> _decode(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static bool paintFood(
    Canvas canvas,
    Rect target,
    String kind, {
    bool prepared = false,
  }) {
    final cell = prepared
        ? preparation[kind] ?? portions[kind]
        : portions[kind];
    if (cell == null || _food == null) return false;
    _paintCell(canvas, _food!, cell, 4, 6, target, trim: cell < 15 ? .08 : 0);
    return true;
  }

  static bool paintOven(Canvas canvas, Rect target, String style) {
    final image = _ovens;
    if (image == null) return false;
    final column = style == 'oven_copper'
        ? 2
        : style == 'oven_rose'
        ? 1
        : 0;
    final cellWidth = image.width / 3;
    final source = Rect.fromLTWH(
      cellWidth * (column + .02),
      image.height * .16,
      cellWidth * .96,
      image.height * .68,
    );
    canvas.drawImageRect(
      image,
      source,
      target,
      Paint()..filterQuality = FilterQuality.high,
    );
    return true;
  }

  static bool paintBase(Canvas canvas, Rect target, String kind) {
    if (_bases == null) return false;
    final cell = kind == 'massa'
        ? 0
        : kind == 'chocolate'
        ? 2
        : 1;
    canvas.save();
    canvas.clipPath(Path()..addOval(target));
    final expanded = Rect.fromCenter(
      center: target.center,
      width: target.width * 1.08,
      height: target.height * 1.08,
    );
    _paintCell(canvas, _bases!, cell, 3, 1, expanded);
    canvas.restore();
    return true;
  }

  static bool paintSalt(Canvas canvas, Rect target, String style) {
    if (_seasonings == null) return false;
    final column = style.endsWith('_glass')
        ? 1
        : style.endsWith('_wood')
        ? 2
        : style.endsWith('_steel') || style == 'salt_gold'
        ? 3
        : 0;
    final color = style == 'salt_rose'
        ? const Color(0xFFD6A1AB)
        : style == 'salt_gold'
        ? const Color(0xFFCCAA5C)
        : null;
    _paintCell(canvas, _seasonings!, column, 4, 2, target, tint: color);
    return true;
  }

  static void _paintCell(
    Canvas canvas,
    ui.Image image,
    int cell,
    int columns,
    int rows,
    Rect target, {
    Color? tint,
    double trim = 0,
  }) {
    final cellWidth = image.width / columns, cellHeight = image.height / rows;
    var source = Rect.fromLTWH(
      (cell % columns) * cellWidth,
      (cell ~/ columns) * cellHeight,
      cellWidth,
      cellHeight,
    );
    if (identical(image, _food) && cell >= 16) {
      const bounds = <int, Rect>{
        16: Rect.fromLTRB(.005, .650, .255, .799),
        17: Rect.fromLTRB(.270, .645, .512, .799),
        18: Rect.fromLTRB(.525, .667, .750, .800),
        19: Rect.fromLTRB(.755, .652, .995, .800),
        20: Rect.fromLTRB(.005, .802, .255, .961),
        21: Rect.fromLTRB(.260, .805, .502, .954),
        22: Rect.fromLTRB(.515, .792, .758, .965),
        23: Rect.fromLTRB(.760, .802, .995, .961),
      };
      final area = bounds[cell]!;
      source = Rect.fromLTRB(
        area.left * image.width,
        area.top * image.height,
        area.right * image.width,
        area.bottom * image.height,
      );
    }
    if (trim > 0) {
      source = source.deflate(cellWidth * trim);
      target = target.deflate(target.shortestSide * trim);
    }
    final fitted = applyBoxFit(BoxFit.contain, source.size, target.size);
    final destination = Alignment.center.inscribe(fitted.destination, target);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (tint != null) {
      paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    }
    canvas.drawImageRect(image, source, destination, paint);
  }
}
