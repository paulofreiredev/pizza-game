import 'package:flutter/material.dart';

/// Keeps the wall above the work area on both portrait and landscape screens.
class KitchenScene extends StatelessWidget {
  const KitchenScene({super.key, this.wallFraction = .28});
  final double wallFraction;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, bounds) {
        Widget section(
          double fraction,
          double sourceFraction,
          Alignment alignment,
        ) {
          final height = bounds.maxHeight * fraction / sourceFraction;
          return ClipRect(
            child: OverflowBox(
              alignment: alignment,
              minHeight: height,
              maxHeight: height,
              child: Image.asset(
                'assets/images/kitchen-scene-v2.png',
                width: bounds.maxWidth,
                height: height,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              flex: (wallFraction * 100).round(),
              child: section(wallFraction, .405, Alignment.topCenter),
            ),
            Expanded(
              flex: ((1 - wallFraction) * 100).round(),
              child: section(1 - wallFraction, .595, Alignment.bottomCenter),
            ),
          ],
        );
      },
    ),
  );
}
