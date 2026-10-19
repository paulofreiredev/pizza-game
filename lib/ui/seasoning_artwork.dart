import 'package:flutter/material.dart';

/// Each material uses the same illustration in the shop and on the shelf.
class SeasoningArtwork extends StatelessWidget {
  const SeasoningArtwork(this.style, {super.key});
  final String style;

  @override
  Widget build(BuildContext context) {
    final column = style.endsWith('_glass')
        ? 1
        : style.endsWith('_wood')
        ? 2
        : style.endsWith('_steel') || style == 'salt_gold'
        ? 3
        : 0;
    final spice = style.startsWith('spice_');
    Widget artwork = FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 384,
        height: 512,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment(-1 + column * 2 / 3, spice ? 1 : -1),
            minWidth: 1536,
            maxWidth: 1536,
            minHeight: 1024,
            maxHeight: 1024,
            child: Image.asset(
              'assets/images/seasonings.png',
              width: 1536,
              height: 1024,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
    // Existing purchases retain their ceramic/metal finishes.
    if (style == 'salt_rose' || style == 'salt_gold') {
      artwork = ColorFiltered(
        colorFilter: ColorFilter.mode(
          style == 'salt_rose'
              ? const Color(0xFFD6A1AB)
              : const Color(0xFFCCAA5C),
          BlendMode.modulate,
        ),
        child: artwork,
      );
    }
    return artwork;
  }
}
