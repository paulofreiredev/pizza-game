import 'package:flutter/material.dart';

/// Isolates each transparent botanical illustration from the shared atlas.
class PlantArtwork extends StatelessWidget {
  const PlantArtwork(this.style, {super.key});
  final String style;

  @override
  Widget build(BuildContext context) {
    if (style != 'plant_fern' && style != 'plant_flowers') {
      return const SizedBox.shrink();
    }
    final fern = style == 'plant_fern';
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: fern ? 976 : 798,
        height: 874,
        child: ClipRect(
          child: OverflowBox(
            alignment: fern ? Alignment.topLeft : Alignment.topRight,
            minWidth: 1774,
            maxWidth: 1774,
            minHeight: 887,
            maxHeight: 887,
            child: Image.asset(
              'assets/images/plants.png',
              width: 1774,
              height: 887,
              fit: BoxFit.fill,
              semanticLabel: fern
                  ? 'Samambaia em vaso de terracota'
                  : 'Flores em vaso de cerâmica',
            ),
          ),
        ),
      ),
    );
  }
}
