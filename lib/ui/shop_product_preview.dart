import 'decorative_plant.dart';

import 'package:flutter/material.dart';

import '../game/assisted_actions.dart';
import '../game/game_state.dart';
import 'kitchen_painter.dart';
import 'natural_kitchen.dart' show FoodSprite;

/// Uses the kitchen's actual drawings so the preview matches equipped items.
class ShopProductPreview extends StatelessWidget {
  const ShopProductPreview({super.key, this.cosmetic, this.recipe})
    : assert((cosmetic == null) != (recipe == null));
  final Cosmetic? cosmetic;
  final PizzaRecipe? recipe;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ColoredBox(
      color: const Color(0xFFFFF6E5),
      child: recipe != null
          ? Image.asset(
              'assets/images/recipes/${recipe!.id}.png',
              fit: BoxFit.cover,
              semanticLabel: 'Pizza ${recipe!.name} pronta',
            )
          : CustomPaint(
              painter: _ProductPainter(cosmetic: cosmetic, recipe: recipe),
              child: const SizedBox.expand(),
            ),
    ),
  );
}

class _ProductPainter extends CustomPainter {
  const _ProductPainter({this.cosmetic, this.recipe});
  final Cosmetic? cosmetic;
  final PizzaRecipe? recipe;

  @override
  void paint(Canvas canvas, Size size) {
    if (cosmetic?.category == 'plant') {
      DecorativePlant(cosmetic!.id).paint(canvas, size);
      return;
    }
    if (cosmetic?.category == 'salt') {
      FoodSprite(
        'sal',
        bowl: false,
        saltStyle: cosmetic!.id,
      ).paint(canvas, size);
      return;
    }
    final item = cosmetic;
    final pizza = recipe;
    final focus = pizza != null
        ? const Rect.fromLTWH(65, 65, 270, 275)
        : switch (item!.category) {
            'cloth' => const Rect.fromLTWH(0, 290, 185, 110),
            'plant' =>
              item.id == 'plant_default'
                  ? const Rect.fromLTWH(5, 5, 85, 105)
                  : const Rect.fromLTWH(320, 0, 80, 115),
            _ => const Rect.fromLTWH(10, 40, 380, 335),
          };
    final fitted = applyBoxFit(BoxFit.contain, focus.size, size);
    final target = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(target.left, target.top);
    canvas.scale(target.width / focus.width, target.height / focus.height);
    canvas.translate(-focus.left, -focus.top);
    final points = <Offset>[];
    final kinds = <String>[];
    if (pizza != null) {
      for (
        var ingredient = 0;
        ingredient < pizza.toppings.length;
        ingredient++
      ) {
        for (
          var portion = 0;
          portion <
              PizzaOrder(
                0,
                pizza,
                '',
                '',
              ).targetFor(pizza.toppings[ingredient]);
          portion++
        ) {
          points.add(assistedToppingPosition(portion, ingredient));
          kinds.add(pizza.toppings[ingredient]);
        }
      }
    }
    KitchenPainter(
      stage: pizza != null
          ? 'toppings'
          : item!.category == 'oven'
          ? 'oven'
          : 'ingredients',
      progress: 0,
      recipeId: pizza?.id ?? 'margherita',
      cosmetic: item?.category == 'cloth' ? item!.id : 'cream',
      ovenStyle: item?.category == 'oven' ? item!.id : 'oven_default',
      plantStyle: item?.category == 'plant' ? item!.id : 'plant_default',
      boardOnly: pizza == null && item!.category != 'oven',
      ovenOpen: false,
      showTool: false,
      toppings: points,
      toppingKinds: kinds,
    ).paint(canvas, const Size(400, 400));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProductPainter old) =>
      old.cosmetic != cosmetic || old.recipe != recipe;
}

class ShopPreviewDialog extends StatelessWidget {
  const ShopPreviewDialog({
    super.key,
    required this.name,
    required this.preview,
    required this.price,
    required this.balance,
    required this.owned,
    required this.equipped,
    this.reward,
  });
  final String name;
  final Widget preview;
  final int price, balance;
  final bool owned, equipped;
  final int? reward;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFFFFF6E5),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 440,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Fechar prévia',
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AspectRatio(aspectRatio: 1.2, child: preview),
            const SizedBox(height: 16),
            if (!owned)
              Text(
                '${formatCoins(price)} moedas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (reward != null)
              Text('Cada entrega rende ${formatCoins(reward!)} moedas.'),
            if (!owned && balance < price)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Faltam ${formatCoins(price - balance)} moedas.'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  equipped ||
                      (!owned && balance < price) ||
                      (owned && reward != null)
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(
                equipped
                    ? 'Em uso'
                    : owned
                    ? reward == null
                          ? 'Usar'
                          : 'Comprada'
                    : 'Comprar por ${formatCoins(price)} moedas',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
