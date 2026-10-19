import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_game/game/game_state.dart';

void finishOrder(GameState game) {
  var steps = 0;
  while (!game.isComplete && steps++ < 20) {
    for (final ingredient in game.requiredIngredients) {
      final count = game.stage == KitchenStage.toppings
          ? game.order.targetFor(ingredient)
          : 1;
      for (var i = 0; i < count; i++) {
        game.selectIngredient(ingredient);
      }
    }
    while (game.actions < game.requiredActions) {
      game.performAction();
    }
    game.distribution = 1;
    expect(game.advance(), isTrue);
  }
  expect(game.isComplete, isTrue);
}

void main() {
  test('shelf materials must be purchased and survive restoring', () {
    final game = GameState.fromJson({'coins': 100000, 'moneyVersion': 2});
    for (final id in [
      'salt_glass',
      'salt_wood',
      'salt_steel',
      'spice_default',
      'spice_glass',
      'spice_wood',
      'spice_steel',
    ]) {
      expect(game.equipCosmetic(id), isFalse);
      final item = GameState.cosmetics.singleWhere((item) => item.id == id);
      expect(item.canDisplayOnShelf, isTrue);
      final before = game.coins;
      expect(game.buyCosmetic(id), isTrue);
      expect(game.coins, before - item.price);
      expect(game.buyCosmetic(id), isFalse);
      expect(GameState.fromJson(game.toJson()).ownedCosmetics, contains(id));
    }
    final restored = GameState.fromJson(game.toJson());
    expect(restored.equippedFor('spice'), 'spice_steel');
    expect(
      GameState.cosmetics
          .where((item) => item.category == 'cloth' || item.category == 'oven')
          .every((item) => !item.canDisplayOnShelf),
      isTrue,
    );
  });
  test('every strawberry and onion order allows several portions', () {
    for (final order in GameState.orders) {
      if (order.recipe.toppings.contains('morango')) {
        expect(order.targetFor('morango'), 8, reason: 'order ${order.index}');
      }
      if (order.recipe.toppings.contains('cebola')) {
        expect(
          order.targetFor('cebola'),
          greaterThanOrEqualTo(5),
          reason: 'order ${order.index}',
        );
      }
    }
  });
  test('ingredients and actions cannot be skipped or counted twice', () {
    final game = GameState();
    expect(game.advance(), isFalse);
    expect(game.selectIngredient('farinha'), isTrue);
    expect(game.selectIngredient('farinha'), isFalse);
    for (final item in ['água', 'fermento', 'sal']) {
      game.selectIngredient(item);
    }
    expect(game.advance(), isTrue);
    expect(game.stage, KitchenStage.mix);
    expect(game.advance(), isFalse);
    for (var i = 0; i < game.requiredActions; i++) {
      game.performAction();
    }
    expect(game.performAction(), isFalse);
    expect(game.advance(), isTrue);
  });
  test('delivery pays once but a new replay earns another reward', () {
    var game = GameState();
    expect(game.startOrder(0), isTrue);
    finishOrder(game);
    expect(game.result!.stars, 3);
    expect(game.coins, 2929);
    game.serve();
    expect(game.coins, 2929);
    game = GameState.fromJson(game.toJson());
    game.serve();
    expect(game.coins, 2929);
    game.startOrder(0);
    finishOrder(game);
    expect(game.coins, 5858);
    expect(game.stars, 3);
  });
  test('free play never changes ratings or balance', () {
    final game = GameState();
    expect(game.startOrder(2, freeMode: true), isTrue);
    finishOrder(game);
    expect(game.result!.stars, 0);
    expect(game.coins, 0);
  });
  test(
    'all recipes can be served and purchases persist without double charge',
    () {
      final game = GameState.fromJson({'coins': 200000, 'moneyVersion': 2});
      var expected = game.coins;
      for (final recipe in PizzaRecipe.recipes.where((r) => r.price > 0)) {
        expect(game.buyRecipe(recipe.id), isTrue);
        expected -= recipe.price;
      }
      for (var i = 0; i < GameState.orders.length; i++) {
        expect(game.startOrder(i), isTrue);
        finishOrder(game);
        expected += game.recipe.reward;
      }
      expect(game.stars, GameState.orders.length * 3);
      expect(game.nextOrder(), isTrue);
      expect(game.coins, expected);
      expect(game.buyCosmetic('sage'), isTrue);
      expect(game.coins, expected - 6000);
      expect(game.buyCosmetic('sage'), isFalse);
      final restored = GameState.fromJson(game.toJson());
      expect(restored.activeCosmetic, 'sage');
      expect(restored.coins, expected - 6000);
      expect(restored.equipCosmetic('unknown'), isFalse);
    },
  );
  test(
    'session restores ingredient progress and rejects malformed save values',
    () {
      final game = GameState();
      game.startOrder(0);
      game.selectIngredient('farinha');
      final restored = GameState.fromJson(game.toJson());
      expect(restored.hasSession, isTrue);
      expect(restored.selectedIngredients, {'farinha'});
      final invalid = GameState.fromJson({
        'coins': -1,
        'orderIndex': 100,
        'stage': 'bad',
        'bestStars': {'7': 3, '0': 100},
      });
      expect(invalid.coins, 0);
      expect(invalid.stage, KitchenStage.ingredients);
    },
  );
  test('three recipes start owned and paid recipes cannot be played before purchase', () {
    final game = GameState();
    expect(PizzaRecipe.recipes.where((r) => game.ownsRecipe(r.id)).length, 3);
    expect(game.startOrder(9, freeMode: true), isFalse);
    expect(game.buyRecipe('frango'), isFalse);
    expect(game.buyRecipe('unknown'), isFalse);
    final funded = GameState.fromJson({'coins': 7990, 'moneyVersion': 2});
    expect(funded.buyRecipe('frango'), isTrue);
    expect(funded.coins, 0);
    expect(funded.buyRecipe('frango'), isFalse);
    final restored = GameState.fromJson(funded.toJson());
    expect(restored.startOrder(9, freeMode: true), isTrue);
    expect(restored.ownsRecipe('mista'), isFalse);
    expect(formatCoins(2929), '29,29');
    expect(formatCoins(4990), '49,90');
  });
  test(
    'cosmetics equip independently and preserve purchases after restore',
    () {
      final game = GameState.fromJson({'coins': 100000, 'moneyVersion': 2});
      for (final id in ['sage', 'salt_gold', 'oven_copper', 'plant_fern']) {
        expect(game.buyCosmetic(id), isTrue);
        expect(game.buyCosmetic(id), isFalse);
      }
      final restored = GameState.fromJson(game.toJson());
      expect(restored.activeCosmetic, 'sage');
      expect(restored.equippedFor('salt'), 'salt_gold');
      expect(restored.equippedFor('oven'), 'oven_copper');
      expect(restored.equippedFor('plant'), 'plant_fern');
      expect(restored.equipCosmetic('salt_default'), isTrue);
      expect(restored.equippedFor('oven'), 'oven_copper');
      expect(restored.coins, 46120);
    },
  );
  test('toppings stop at a generous recipe-specific limit', () {
    final game = GameState()..startOrder(1, freeMode: true);
    while (game.stage != KitchenStage.toppings) {
      for (final ingredient in game.requiredIngredients) {
        game.selectIngredient(ingredient);
      }
      while (game.actions < game.requiredActions) {
        game.performAction();
      }
      expect(game.advance(), isTrue);
    }
    for (final ingredient in game.recipe.toppings) {
      final target = game.order.targetFor(ingredient);
      for (var i = 0; i < target; i++) {
        expect(game.selectIngredient(ingredient), isTrue);
      }
      expect(game.selectIngredient(ingredient), isFalse);
      expect(game.toppingCounts[ingredient], target);
    }
  });
  test(
    'random next orders use owned flavors and never repeat consecutively',
    () {
      final game = GameState();
      final seen = <String>{};
      String? previous;
      for (var delivery = 0; delivery < 12; delivery++) {
        final index = game.nextOrderIndex;
        expect(game.ownsRecipe(GameState.orders[index].recipe.id), isTrue);
        expect(GameState.orders[index].recipe.id, isNot(previous));
        expect(game.startOrder(index), isTrue);
        seen.add(game.recipe.id);
        previous = game.recipe.id;
        finishOrder(game);
      }
      expect(seen.length, greaterThan(1));
      final restored = GameState.fromJson(game.toJson());
      expect(
        GameState.orders[restored.nextOrderIndex].recipe.id,
        isNot(previous),
      );
    },
  );
  test('every purchased flavor is offered after buying and reopening', () {
    for (final recipe in PizzaRecipe.recipes.where((r) => r.price > 0)) {
      var game = GameState.fromJson({'coins': recipe.price, 'moneyVersion': 2});
      expect(game.buyRecipe(recipe.id), isTrue);
      game = GameState.fromJson(game.toJson());
      final offered = List.generate(
        4,
        (_) => GameState.orders[game.nextOrderIndex].recipe.id,
      );
      expect(offered, contains(recipe.id));
      expect(offered.toSet().length, 4);
      for (final id in offered) {
        expect(game.ownsRecipe(id), isTrue);
      }
    }
  });
  test('order rotation covers all owned recipes and survives reopening', () {
    var game = GameState.fromJson({'coins': 200000, 'moneyVersion': 2});
    for (final recipe in PizzaRecipe.recipes.where((r) => r.price > 0)) {
      expect(game.buyRecipe(recipe.id), isTrue);
    }
    final offered = <String>{};
    for (var i = 0; i < PizzaRecipe.recipes.length; i++) {
      final index = game.nextOrderIndex;
      expect(offered.add(GameState.orders[index].recipe.id), isTrue);
      expect(game.startOrder(index), isTrue);
      finishOrder(game);
      game = GameState.fromJson(game.toJson());
    }
    expect(offered, PizzaRecipe.recipes.map((r) => r.id).toSet());
  });
  test('mixing advances directly to rolling and legacy kneading resumes at rolling', () {
    final game = GameState.fromJson({
      'orderIndex': 0,
      'stage': 'mix',
      'hasSession': true,
    });
    while (game.actions < game.requiredActions) {
      game.performAction();
    }
    expect(game.advance(), isTrue);
    expect(game.stage, KitchenStage.roll);
    final restored = GameState.fromJson({
      'orderIndex': 0,
      'stage': 'knead',
      'hasSession': true,
    });
    expect(restored.stage, KitchenStage.roll);
  });
  test(
    'shrimp and chicken with catupiri can be bought, cooked and rewarded',
    () {
      for (final id in ['camarao', 'frango_catupiri']) {
        final recipe = PizzaRecipe.recipes.firstWhere((r) => r.id == id);
        final game = GameState.fromJson({
          'coins': recipe.price,
          'moneyVersion': 2,
        });
        final order = GameState.orders.firstWhere((o) => o.recipe.id == id);
        expect(game.startOrder(order.index), isFalse);
        expect(game.buyRecipe(id), isTrue);
        expect(game.coins, 0);
        expect(game.startOrder(order.index), isTrue);
        finishOrder(game);
        expect(game.result!.coins, recipe.reward);
        expect(game.coins, id == 'camarao' ? 4990 : 2929);
        final restored = GameState.fromJson(game.toJson());
        expect(restored.ownsRecipe(id), isTrue);
      }
    },
  );
  test('legacy whole coins migrate to cents once', () {
    final game = GameState.fromJson({'coins': 50});
    expect(game.coins, 5000);
    expect(GameState.fromJson(game.toJson()).coins, 5000);
  });
  test('calabresa includes cutting while other recipes skip it', () {
    for (var i = 0; i < 3; i++) {
      final game = GameState();
      game.startOrder(i, freeMode: true);
      while (game.stage != KitchenStage.roll) {
        for (final item in game.requiredIngredients) {
          game.selectIngredient(item);
        }
        while (game.actions < game.requiredActions) {
          game.performAction();
        }
        expect(game.advance(), isTrue);
      }
      while (game.actions < game.requiredActions) {
        game.performAction();
      }
      game.advance();
      expect(game.stage, i == 1 ? KitchenStage.chop : KitchenStage.sauce);
    }
  });
}
