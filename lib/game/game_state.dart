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
  const PizzaRecipe(this.id, this.name, this.toppings);
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
    return 3;
  }
}

class Cosmetic {
  const Cosmetic(this.id, this.name, this.price);
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
  GameState();
  static const doughIngredients = ['farinha', 'água', 'fermento', 'sal'];
  static const cosmetics = [
    Cosmetic('sage', 'Toalha sálvia', 60),
    Cosmetic('rose', 'Toalha rosada', 90),
    Cosmetic('sunset', 'Toalha dourada', 120),
  ];
  static final orders = List<PizzaOrder>.unmodifiable(
    List.generate(
      9,
      (i) => PizzaOrder(
        i,
        PizzaRecipe.recipes[i % 3],
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
        ][i],
      ),
    ),
  );
  int _orderIndex = 0, _coins = 0, _actions = 0;
  KitchenStage _stage = KitchenStage.ingredients;
  bool _freeMode = false, hasSession = false;
  final Set<String> _selected = {};
  final Map<String, int> _toppings = {};
  final Map<int, int> _bestStars = {};
  final Set<String> _ownedCosmetics = {'cream'};
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
  int get unlockedOrders {
    var unlocked = 1;
    while (unlocked < orders.length && _bestStars.containsKey(unlocked - 1)) {
      unlocked++;
    }
    return unlocked;
  }

  Set<String> get selectedIngredients => Set.unmodifiable(_selected);
  Map<String, int> get toppingCounts => Map.unmodifiable(_toppings);
  Set<String> get ownedCosmetics => Set.unmodifiable(_ownedCosmetics);
  String get activeCosmetic => _activeCosmetic;
  OrderResult? get result => _result;
  int starsForOrder(int index) => _bestStars[index] ?? 0;
  bool get isComplete => _stage == KitchenStage.complete;
  bool get campaignComplete => _bestStars.length == orders.length;
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
        (!freeMode && index >= unlockedOrders)) {
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
      if ((_toppings[ingredient] ?? 0) >= 20 ||
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
    if (_stage == KitchenStage.chop && recipe.id != 'calabresa') {
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
    final reward = _freeMode ? 0 : 20 + earnedStars * 10;
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

  bool nextOrder() => isComplete && _orderIndex + 1 < orders.length
      ? startOrder(_orderIndex + 1, freeMode: _freeMode)
      : false;
  bool buyCosmetic(String id) {
    final matches = cosmetics.where((item) => item.id == id);
    if (matches.isEmpty || _ownedCosmetics.contains(id)) return false;
    final item = matches.first;
    if (_coins < item.price) return false;
    _coins -= item.price;
    _ownedCosmetics.add(id);
    _activeCosmetic = id;
    return true;
  }

  bool equipCosmetic(String id) {
    if (!_ownedCosmetics.contains(id)) return false;
    _activeCosmetic = id;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'coins': _coins,
    'bestStars': _bestStars.map((k, v) => MapEntry('$k', v)),
    'ownedCosmetics': _ownedCosmetics.toList(),
    'activeCosmetic': _activeCosmetic,
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
    if (coins is int && coins >= 0) game._coins = coins;
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
    final active = json['activeCosmetic'];
    if (active is String && game._ownedCosmetics.contains(active)) {
      game._activeCosmetic = active;
    }
    final index = json['orderIndex'];
    if (index is int &&
        index >= 0 &&
        index < orders.length &&
        (json['freeMode'] == true || index < game.unlockedOrders)) {
      game._orderIndex = index;
      game._freeMode = json['freeMode'] == true;
      game._stage =
          KitchenStage.values
              .where((s) => s.name == json['stage'])
              .firstOrNull ??
          KitchenStage.ingredients;
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
          if (n is int && n > 0) game._toppings[t] = n.clamp(0, 20);
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
          (result['coins'] as int).clamp(0, 50),
          result['feedback'] as String,
        );
      }
    }
    return game;
  }
}
