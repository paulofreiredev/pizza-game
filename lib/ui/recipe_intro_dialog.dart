import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_state.dart';

enum RecipeIntroAction { start, decline }

class RecipeIntroDialog extends StatelessWidget {
  const RecipeIntroDialog({
    super.key,
    required this.recipe,
    this.allowDecline = false,
  });
  final bool allowDecline;
  final PizzaRecipe recipe;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFFFFF6E5),
    insetPadding: const EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 440,
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Escolher outra pizza',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Text(
                recipe.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF563D31),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox.square(
                  dimension: math.min(
                    340,
                    math.min(
                      MediaQuery.sizeOf(context).width - 84,
                      MediaQuery.sizeOf(context).height * .38,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/recipes/${recipe.id}.png',
                    fit: BoxFit.cover,
                    semanticLabel: 'Pizza ${recipe.name} pronta',
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('recipe-intro-start'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 60),
                  ),
                  onPressed: () =>
                      Navigator.pop(context, RecipeIntroAction.start),
                  icon: const Icon(Icons.play_arrow_rounded, size: 36),
                  label: const Text(
                    'Vamos preparar!',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              if (allowDecline) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    key: const Key('recipe-intro-decline'),
                    onPressed: () =>
                        Navigator.pop(context, RecipeIntroAction.decline),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Recusar pedido'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
