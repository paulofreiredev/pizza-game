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
    // Crop to the vessel itself so its base meets the shelf.
    final crop = Rect.fromLTRB(
      column * 384 + (spice ? 62 : 72),
      spice ? 520 : 58,
      column * 384 + (spice ? 337 : 331),
      spice ? 938 : 456,
    );
    Widget artwork = FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: crop.width,
        height: crop.height,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 1536,
            maxWidth: 1536,
            minHeight: 1024,
            maxHeight: 1024,
            child: Transform.translate(
              offset: Offset(-crop.left, -crop.top),
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
