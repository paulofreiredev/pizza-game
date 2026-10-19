import 'package:flutter/material.dart';

/// The blade slides under the pizza before carrying it out of the oven.
class PizzaPeel extends StatelessWidget {
  const PizzaPeel({super.key, required this.progress, required this.pizza});
  final double progress;
  final Widget pizza;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final insertion = Curves.easeOut.transform(
        (progress / .25).clamp(0.0, 1.0),
      );
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, bounds.maxHeight * .8 * (1 - insertion)),
              child: CustomPaint(painter: _PeelPainter()),
            ),
          ),
          Positioned.fill(child: pizza),
        ],
      );
    },
  );
}

class _PeelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final handle = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .45,
        size.height * .65,
        size.width * .10,
        size.height * 1.25,
      ),
      Radius.circular(size.width * .04),
    );
    canvas.drawRRect(
      handle,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF85502E), Color(0xFFD9AC72), Color(0xFF986039)],
        ).createShader(handle.outerRect),
    );
    final blade = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -size.width * .08,
        -size.height * .04,
        size.width * 1.16,
        size.height * 1.12,
      ),
      Radius.circular(size.width * .23),
    );
    canvas.drawRRect(
      blade.shift(Offset(0, size.height * .025)),
      Paint()..color = const Color(0x55534536),
    );
    canvas.drawRRect(
      blade,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F1E9), Color(0xFF9EAEB0), Color(0xFFDCE3DE)],
        ).createShader(blade.outerRect),
    );
    canvas.drawRRect(
      blade,
      Paint()
        ..color = const Color(0xFF77898B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PeelPainter oldDelegate) => false;
}
