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
    expect(game.startOrder(1), isFalse);
    finishOrder(game);
    expect(game.result!.stars, 3);
    expect(game.coins, 50);
    expect(game.unlockedOrders, 2);
    game.serve();
    expect(game.coins, 50);
    game = GameState.fromJson(game.toJson());
    game.serve();
    expect(game.coins, 50);
    game.startOrder(0);
    finishOrder(game);
    expect(game.coins, 100);
    expect(game.stars, 3);
  });
  test('free play never changes ratings or balance', () {
    final game = GameState();
    expect(game.startOrder(2, freeMode: true), isTrue);
    finishOrder(game);
    expect(game.result!.stars, 0);
    expect(game.coins, 0);
    expect(game.unlockedOrders, 1);
  });
  test(
    'nine orders complete campaign and purchases persist without double charge',
    () {
      final game = GameState();
      expect(game.buyCosmetic('sage'), isFalse);
      for (var i = 0; i < 9; i++) {
        expect(game.orderIndex, i);
        finishOrder(game);
        if (i < 8) expect(game.nextOrder(), isTrue);
      }
      expect(game.campaignComplete, isTrue);
      expect(game.stars, 27);
      expect(game.nextOrder(), isFalse);
      expect(game.coins, 450);
      expect(game.buyCosmetic('sage'), isTrue);
      expect(game.coins, 390);
      expect(game.buyCosmetic('sage'), isFalse);
      final restored = GameState.fromJson(game.toJson());
      expect(restored.activeCosmetic, 'sage');
      expect(restored.coins, 390);
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
      expect(invalid.unlockedOrders, 1);
      expect(invalid.stage, KitchenStage.ingredients);
    },
  );
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
