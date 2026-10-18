import 'dart:math' as math;

String formatCoins(int cents) =>
    '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';

enum KitchenStage {
  ingredients,
  mix,
  knead,
  roll,
  chop,
  sauce,
  toppings,
  oven,
  slice,
  serve,
  complete,
}

class PizzaRecipe {
  const PizzaRecipe(
    this.id,
    this.name,
    this.toppings, {
    this.price = 0,
    this.reward = 2929,
  });
  final int price, reward;
  final String id, name;
  final List<String> toppings;
  static const recipes = [
    PizzaRecipe('margherita', 'Marguerita', ['queijo', 'manjericão']),
    PizzaRecipe('calabresa', 'Calabresa', ['queijo', 'calabresa', 'cebola']),
    PizzaRecipe('chocolate', 'Chocolate com morango', [
      'chocolate',
      'morango',
      'confeitos',
    ]),
    PizzaRecipe('frango', 'Frango', ['queijo', 'frango'], price: 7990),
    PizzaRecipe('mista', 'Mista', [
      'queijo',
      'frango',
      'calabresa',
      'cebola',
    ], price: 7990),
    PizzaRecipe(
      'carne_de_sol',
      'Carne de sol com queijo',
      ['queijo', 'carne de sol'],
      price: 13990,
      reward: 4990,
    ),
    PizzaRecipe(
      'quatro_queijos',
      'Quatro queijos',
      ['muçarela', 'provolone', 'gorgonzola', 'parmesão'],
      price: 13990,
      reward: 4990,
    ),
    PizzaRecipe(
      'camarao',
      'Camarão',
      ['queijo', 'camarão'],
      price: 13990,
      reward: 4990,
    ),
    PizzaRecipe('frango_catupiri', 'Frango com catupiri', [
      'queijo',
      'frango',
      'catupiri',
    ], price: 7990),
  ];
}

class PizzaOrder {
  const PizzaOrder(this.index, this.recipe, this.customer, this.instruction);
  final int index;
  final PizzaRecipe recipe;
  final String customer, instruction;
  int get number => index + 1;
  int targetFor(String ingredient) {
    if (index == 3 && ingredient == 'manjericão') return 5;
    if (index == 4 && ingredient == 'cebola') return 5;
    if ((index == 5 && ingredient == 'morango') ||
        (index == 7 && ingredient == 'cebola')) {
      return 1;
    }
    return switch (ingredient) {
      'calabresa' => 18,
      'camarão' => 12,
      'catupiri' => 8,
      'morango' || 'tomate' => 8,
      'cebola' || 'manjericão' => 6,
      'confeitos' => 12,
      _ => 10,
    };
  }
}

class Cosmetic {
  const Cosmetic(this.id, this.name, this.price, {this.category = 'cloth'});
  final String category;
  final String id, name;
  final int price;
}

class OrderResult {
  const OrderResult(this.stars, this.coins, this.feedback);
  final int stars, coins;
  final String feedback;
}

/// All gameplay rules are independent of rendering and audio.
class GameState {
  GameState({math.Random? random}) : _random = random ?? math.Random();
  final math.Random _random;
  int get nextOrderIndex => randomOrderIndex();

  int randomOrderIndex({String? excludingFlavor}) {
    final candidates = PizzaRecipe.recipes
        .where(
          (r) =>
              ownsRecipe(r.id) &&
              r.id != excludingFlavor &&
              ((!hasSession && _result == null) || r.id != recipe.id),
        )
        .toList();
    var remaining = candidates
        .where((r) => _remainingOrderFlavors.contains(r.id))
        .toList();
    if (remaining.isEmpty) {
      _remainingOrderFlavors
        ..clear()
        ..addAll(
          PizzaRecipe.recipes.where((r) => ownsRecipe(r.id)).map((r) => r.id),
        );
      remaining = candidates;
    }
    final selected = remaining[_random.nextInt(remaining.length)];
    _remainingOrderFlavors.remove(selected.id);
    final templates = orders.where((o) => o.recipe.id == selected.id).toList();
    return templates[_random.nextInt(templates.length)].index;
  }

  static const doughIngredients = ['farinha', 'água', 'fermento', 'sal'];
  static const cosmetics = [
    Cosmetic('sage', 'Toalha sálvia', 6000),
    Cosmetic('rose', 'Toalha rosada', 9000),
    Cosmetic('sunset', 'Toalha dourada', 12000),
    Cosmetic('salt_rose', 'Saleiro de cerâmica rosada', 3990, category: 'salt'),
    Cosmetic('salt_gold', 'Saleiro dourado', 3990, category: 'salt'),
    Cosmetic('oven_rose', 'Forno rosado', 29900, category: 'oven'),
    Cosmetic('oven_copper', 'Forno de cobre', 39900, category: 'oven'),
    Cosmetic('plant_fern', 'Samambaia', 3990, category: 'plant'),
    Cosmetic('plant_flowers', 'Vaso de flores', 3990, category: 'plant'),
  ];
  static final orders = List<PizzaOrder>.unmodifiable(
    List.generate(
      PizzaRecipe.recipes.length + 6,
      (i) => PizzaOrder(
        i,
        PizzaRecipe.recipes[i < 9 ? i % 3 : i - 6],
        const [
          'Luna',
          'Theo',
          'Nina',
          'Bento',
          'Clara',
          'Noah',
          'Lia',
          'Otto',
          'Mia',
          'Alice',
          'Davi',
          'Sofia',
          'Miguel',
          'Iara',
          'Caio',
        ][i],
        const [
          'Uma marguerita bem gostosa!',
          'Calabresa com cebola, por favor.',
          'Uma pizza doce com morangos!',
          'Capriche no manjericão!',
          'Bastante cebola, por favor!',
          'Só um pouquinho de morango.',
          'Espalhe a cobertura por toda a pizza.',
          'Pouca cebola e calabresa bem distribuída.',
          'Morangos bem distribuídos e confeitos!',
          'Uma pizza de frango bem gostosa!',
          'Frango e calabresa juntos, por favor!',
          'Carne de sol com bastante queijo!',
          'Quero provar os quatro queijos!',
          'Uma pizza de camarão bem caprichada!',
          'Frango com catupiri cremoso, por favor!',
        ][i],
      ),
    ),
  );
  int _orderIndex = 0, _coins = 0, _actions = 0;
  KitchenStage _stage = KitchenStage.ingredients;
  bool _freeMode = false, hasSession = false;
  final Set<String> _purchasedRecipes = {};
  final Set<String> _remainingOrderFlavors = {};
  Set<String> get purchasedRecipes => Set.unmodifiable(_purchasedRecipes);
  bool ownsRecipe(String id) => PizzaRecipe.recipes.any(
    (r) => r.id == id && (r.price == 0 || _purchasedRecipes.contains(id)),
  );
  bool buyRecipe(String id) {
    final recipe = PizzaRecipe.recipes.where((r) => r.id == id).firstOrNull;
    if (recipe == null || ownsRecipe(id) || _coins < recipe.price) return false;
    if (_remainingOrderFlavors.isEmpty) {
      _remainingOrderFlavors.addAll(
        PizzaRecipe.recipes.where((r) => ownsRecipe(r.id)).map((r) => r.id),
      );
    }
    _coins -= recipe.price;
    _purchasedRecipes.add(id);
    _remainingOrderFlavors.add(id);
    return true;
  }

  final Set<String> _selected = {};
  final Map<String, int> _toppings = {};
  final Map<int, int> _bestStars = {};
  final Set<String> _ownedCosmetics = {
    'cream',
    'salt_default',
    'oven_default',
    'plant_default',
  };
  final Map<String, String> _equipment = {
    'salt': 'salt_default',
    'oven': 'oven_default',
    'plant': 'plant_default',
  };
  String equippedFor(String category) =>
      category == 'cloth' ? _activeCosmetic : _equipment[category] ?? '';
  bool isEquipped(Cosmetic item) => equippedFor(item.category) == item.id;
  String _activeCosmetic = 'cream';
  OrderResult? _result;
  double distribution = 0;

  PizzaOrder get order => orders[_orderIndex];
  PizzaRecipe get recipe => order.recipe;
  int get orderIndex => _orderIndex;
  KitchenStage get stage => _stage;
  int get coins => _coins;
  int get actions => _actions;
  bool get freeMode => _freeMode;
  int get stars => _bestStars.values.fold(0, (a, b) => a + b);
  Set<String> get selectedIngredients => Set.unmodifiable(_selected);
  Map<String, int> get toppingCounts => Map.unmodifiable(_toppings);
  Set<String> get ownedCosmetics => Set.unmodifiable(_ownedCosmetics);
  String get activeCosmetic => _activeCosmetic;
  OrderResult? get result => _result;
  int starsForOrder(int index) => _bestStars[index] ?? 0;
  bool get isComplete => _stage == KitchenStage.complete;
  List<String> get requiredIngredients => switch (_stage) {
    KitchenStage.ingredients => doughIngredients,
    KitchenStage.toppings => recipe.toppings,
    _ => const [],
  };
  int get requiredActions => switch (_stage) {
    KitchenStage.mix => 12,
    KitchenStage.knead => 10,
    KitchenStage.roll => 10,
    KitchenStage.chop => 10,
    KitchenStage.sauce => 20,
    KitchenStage.oven => 3,
    KitchenStage.slice => 4,
    _ => 0,
  };
  double get progress {
    if (_stage == KitchenStage.toppings) {
      final placed = recipe.toppings.fold<int>(
        0,
        (sum, t) => sum + (_toppings[t] ?? 0).clamp(0, order.targetFor(t)),
      );
      final total = recipe.toppings.fold<int>(
        0,
        (sum, t) => sum + order.targetFor(t),
      );
      return placed / total;
    }
    if (requiredIngredients.isNotEmpty) {
      return _selected.length / requiredIngredients.length;
    }
    if (requiredActions > 0) {
      return (_actions / requiredActions).clamp(0.0, 1.0);
    }
    return isComplete ? 1 : 0;
  }

  bool get canAdvance =>
      !isComplete &&
      (_stage == KitchenStage.serve ||
          (_stage == KitchenStage.toppings
              ? _toppings.isNotEmpty
              : (requiredIngredients.isNotEmpty
                    ? requiredIngredients.every(_selected.contains)
                    : _actions >= requiredActions)));

  bool startOrder(int index, {bool freeMode = false}) {
    if (index < 0 ||
        index >= orders.length ||
        !ownsRecipe(orders[index].recipe.id)) {
      return false;
    }
    _orderIndex = index;
    _freeMode = freeMode;
    _stage = KitchenStage.ingredients;
    _actions = 0;
    _selected.clear();
    _toppings.clear();
    _result = null;
    distribution = 0;
    hasSession = true;
    return true;
  }

  bool selectIngredient(String ingredient) {
    if (!requiredIngredients.contains(ingredient)) return false;
    if (_stage == KitchenStage.toppings) {
      if ((_toppings[ingredient] ?? 0) >= order.targetFor(ingredient) ||
          _toppings.values.fold(0, (a, b) => a + b) >= 80) {
        return false;
      }
      _toppings.update(ingredient, (n) => n + 1, ifAbsent: () => 1);
      return true;
    }
    return _selected.add(ingredient);
  }

  bool removeTopping(String ingredient) {
    if (_stage != KitchenStage.toppings || (_toppings[ingredient] ?? 0) == 0) {
      return false;
    }
    if (_toppings[ingredient] == 1) {
      _toppings.remove(ingredient);
    } else {
      _toppings[ingredient] = _toppings[ingredient]! - 1;
    }
    return true;
  }

  bool performAction() {
    if (requiredActions == 0 || _actions >= requiredActions) return false;
    _actions++;
    return true;
  }

  bool advance() {
    if (!canAdvance) return false;
    if (_stage == KitchenStage.serve) {
      serve();
      return true;
    }
    _stage = KitchenStage.values[_stage.index + 1];
    if (_stage == KitchenStage.knead) _stage = KitchenStage.roll;
    if (_stage == KitchenStage.chop && !recipe.toppings.contains('calabresa')) {
      _stage = KitchenStage.sauce;
    }
    _selected.clear();
    _actions = 0;
    return true;
  }

  bool completeStage() => advance();
  OrderResult? serve() {
    if (_stage != KitchenStage.serve) return _result;
    final matched = recipe.toppings.where((t) {
      final count = _toppings[t] ?? 0, target = order.targetFor(t);
      return target == 1 ? count == 1 : count >= target - 1;
    }).length;
    final earnedStars = _freeMode
        ? 0
        : 1 +
              (matched == recipe.toppings.length ? 1 : 0) +
              (distribution >= .6 ? 1 : 0);
    final reward = _freeMode ? 0 : recipe.reward;
    _coins += reward;
    if (!_freeMode && earnedStars > (_bestStars[_orderIndex] ?? 0)) {
      _bestStars[_orderIndex] = earnedStars;
    }
    final feedback = _freeMode
        ? 'Sua criação está pronta. Que delícia!'
        : matched != recipe.toppings.length
        ? 'Ficou gostosa! Na próxima, confira as quantidades do pedido.'
        : distribution < .6
        ? 'Pedido certinho! Espalhe os ingredientes por mais áreas para ganhar outra estrela.'
        : 'Tudo no capricho: pedido, cobertura e forno. Uma delícia!';
    _result = OrderResult(earnedStars, reward, feedback);
    _stage = KitchenStage.complete;
    hasSession = false;
    return _result;
  }

  bool nextOrder() =>
      isComplete && startOrder(nextOrderIndex, freeMode: _freeMode);
  bool buyCosmetic(String id) {
    final matches = cosmetics.where((item) => item.id == id);
    if (matches.isEmpty || _ownedCosmetics.contains(id)) return false;
    final item = matches.first;
    if (_coins < item.price) return false;
    _coins -= item.price;
    _ownedCosmetics.add(id);
    equipCosmetic(id);
    return true;
  }

  bool equipCosmetic(String id) {
    if (!_ownedCosmetics.contains(id)) return false;
    final category =
        cosmetics.where((c) => c.id == id).firstOrNull?.category ??
        (id.startsWith('salt_')
            ? 'salt'
            : id.startsWith('oven_')
            ? 'oven'
            : id.startsWith('plant_')
            ? 'plant'
            : 'cloth');
    if (category == 'cloth') {
      _activeCosmetic = id;
    } else {
      _equipment[category] = id;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'moneyVersion': 2,
    'purchasedRecipes': _purchasedRecipes.toList(),
    'remainingOrderFlavors': _remainingOrderFlavors.toList(),
    'coins': _coins,
    'bestStars': _bestStars.map((k, v) => MapEntry('$k', v)),
    'ownedCosmetics': _ownedCosmetics.toList(),
    'activeCosmetic': _activeCosmetic,
    'equipment': Map<String, String>.from(_equipment),
    'orderIndex': _orderIndex,
    'freeMode': _freeMode,
    'stage': _stage.name,
    'actions': _actions,
    'selected': _selected.toList(),
    'toppings': _toppings,
    'distribution': distribution,
    'hasSession': hasSession,
    'result': _result == null
        ? null
        : {
            'stars': _result!.stars,
            'coins': _result!.coins,
            'feedback': _result!.feedback,
          },
  };
  factory GameState.fromJson(Map<String, dynamic> json) {
    final game = GameState();
    final coins = json['coins'];
    if (coins is int && coins >= 0) {
      game._coins = coins * (json['moneyVersion'] == 2 ? 1 : 100);
    }
    final purchased = json['purchasedRecipes'];
    if (purchased is List) {
      game._purchasedRecipes.addAll(
        purchased.whereType<String>().where(
          (id) => PizzaRecipe.recipes.any((r) => r.id == id && r.price > 0),
        ),
      );
    }
    final remaining = json['remainingOrderFlavors'];
    if (remaining is List) {
      game._remainingOrderFlavors.addAll(
        remaining.whereType<String>().where(game.ownsRecipe),
      );
    }
    final ratings = json['bestStars'];
    if (ratings is Map) {
      for (final entry in ratings.entries) {
        final index = int.tryParse(entry.key.toString());
        if (index != null &&
            index >= 0 &&
            index < orders.length &&
            entry.value is int &&
            entry.value >= 1 &&
            entry.value <= 3) {
          game._bestStars[index] = entry.value as int;
        }
      }
    }
    final owned = json['ownedCosmetics'];
    if (owned is List) {
      game._ownedCosmetics.addAll(
        owned.whereType<String>().where(
          (id) => cosmetics.any((c) => c.id == id),
        ),
      );
    }
    final equipment = json['equipment'];
    if (equipment is Map) {
      for (final category in ['salt', 'oven', 'plant']) {
        final id = equipment[category];
        if (id is String &&
            game._ownedCosmetics.contains(id) &&
            (cosmetics.any((c) => c.id == id && c.category == category) ||
                id == '${category}_default')) {
          game._equipment[category] = id;
        }
      }
    }
    final active = json['activeCosmetic'];
    if (active is String &&
        game._ownedCosmetics.contains(active) &&
        (active == 'cream' ||
            cosmetics.any((c) => c.id == active && c.category == 'cloth'))) {
      game._activeCosmetic = active;
    }
    final index = json['orderIndex'];
    if (index is int &&
        index >= 0 &&
        index < orders.length &&
        game.ownsRecipe(orders[index].recipe.id)) {
      game._orderIndex = index;
      game._freeMode = json['freeMode'] == true;
      game._stage =
          KitchenStage.values
              .where((s) => s.name == json['stage'])
              .firstOrNull ??
          KitchenStage.ingredients;
      if (game._stage == KitchenStage.knead) game._stage = KitchenStage.roll;
      final actions = json['actions'];
      if (actions is int) {
        game._actions = actions.clamp(0, game.requiredActions);
      }
      final selected = json['selected'];
      if (selected is List) {
        game._selected.addAll(
          selected.whereType<String>().where(game.requiredIngredients.contains),
        );
      }
      final toppings = json['toppings'];
      if (toppings is Map) {
        for (final t in game.recipe.toppings) {
          final n = toppings[t];
          if (n is int && n > 0) {
            game._toppings[t] = n.clamp(0, game.order.targetFor(t));
          }
        }
      }
      final d = json['distribution'];
      if (d is num && d.isFinite) game.distribution = d.toDouble().clamp(0, 1);
      game.hasSession = json['hasSession'] == true && !game.isComplete;
      final result = json['result'];
      if (game.isComplete &&
          result is Map &&
          result['stars'] is int &&
          result['coins'] is int &&
          result['feedback'] is String) {
        game._result = OrderResult(
          (result['stars'] as int).clamp(0, 3),
          ((result['coins'] as int) * (json['moneyVersion'] == 2 ? 1 : 100))
              .clamp(0, 5000),
          result['feedback'] as String,
        );
      }
    }
    return game;
  }
}
