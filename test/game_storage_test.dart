import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pizza_game/game/game_state.dart';
import 'package:pizza_game/services/game_storage.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  test(
    'SQLite reopens wallet, recipes and independently equipped scenery',
    () async {
      final directory = await Directory.systemTemp.createTemp('pizza-storage-');
      final location = '${directory.path}/game.db';
      var storage = await GameStorage.open(
        factory: databaseFactoryFfi,
        databasePath: location,
      );
      try {
        final game = GameState.fromJson({'coins': 100000, 'moneyVersion': 2});
        expect(game.buyRecipe('frango'), isTrue);
        expect(game.buyCosmetic('salt_rose'), isTrue);
        await storage.save(jsonEncode({'game': game.toJson()}));
        await storage.close();
        storage = await GameStorage.open(
          factory: databaseFactoryFfi,
          databasePath: location,
        );
        final restored = GameState.fromJson(
          (jsonDecode((await storage.load())!) as Map<String, dynamic>)['game']
              as Map<String, dynamic>,
        );
        expect(restored.coins, 72200);
        expect(restored.ownsRecipe('frango'), isTrue);
        expect(restored.equippedFor('salt'), 'salt_rose');
        expect((await storage.database.query('wallet')).single['cents'], 72200);
        expect(
          (await storage.database.query('purchased_recipes'))
              .single['recipe_id'],
          'frango',
        );
        final invalid = restored.toJson()..['coins'] = -1;
        await expectLater(
          storage.save(jsonEncode({'game': invalid})),
          throwsA(isA<DatabaseException>()),
        );
        expect((await storage.database.query('wallet')).single['cents'], 72200);
        final afterFailure =
            jsonDecode((await storage.load())!) as Map<String, dynamic>;
        expect((afterFailure['game'] as Map)['coins'], 72200);
      } finally {
        await storage.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
