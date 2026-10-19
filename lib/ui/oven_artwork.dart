import 'package:flutter/material.dart';

class OvenArtwork extends StatelessWidget {
  const OvenArtwork(this.style, {super.key});
  final String style;

  @override
  Widget build(BuildContext context) {
    final column = style == 'oven_copper'
        ? 2
        : style == 'oven_rose'
        ? 1
        : 0;
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 656,
        height: 464,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment(-1 + column.toDouble(), 0),
            minWidth: 2048,
            maxWidth: 2048,
            minHeight: 683,
            maxHeight: 683,
            child: Image.asset(
              'assets/images/ovens.png',
              width: 2048,
              height: 683,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
