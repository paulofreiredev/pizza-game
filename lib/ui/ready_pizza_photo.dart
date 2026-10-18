import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void paintReadyPizza(Canvas canvas, ui.Image image, Rect bounds) {
  final side = image.width < image.height
      ? image.width.toDouble()
      : image.height.toDouble();
  // Remove most of the table/plate border while keeping the baked crust.
  final source = Rect.fromCenter(
    center: Offset(image.width / 2, image.height / 2),
    width: side * .94,
    height: side * .94,
  );
  canvas.save();
  canvas.clipPath(Path()..addOval(bounds));
  canvas.drawImageRect(
    image,
    source,
    bounds,
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
}

class ReadyPizzaPhoto extends CustomPainter {
  const ReadyPizzaPhoto(this.image);
  final ui.Image image;
  @override
  void paint(Canvas canvas, Size size) =>
      paintReadyPizza(canvas, image, Offset.zero & size);
  @override
  bool shouldRepaint(ReadyPizzaPhoto oldDelegate) => oldDelegate.image != image;
}
