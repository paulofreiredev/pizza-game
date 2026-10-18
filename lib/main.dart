import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/game_state.dart';
import 'services/game_audio.dart';
import 'services/game_storage.dart';
import 'ui/natural_kitchen.dart';
import 'ui/recipe_intro_dialog.dart';
import 'ui/shop_product_preview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PizzaGameApp());
}

const ink = Color(0xFF563D31),
    cream = Color(0xFFFFF6E5),
    terra = Color(0xFFB75B42),
    sage = Color(0xFF647F59);

class PizzaGameApp extends StatelessWidget {
  const PizzaGameApp({super.key, this.storage});
  final GameStorage? storage;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pizza Game',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: terra, surface: cream),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: terra,
          foregroundColor: cream,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    home: PizzaHome(storage: storage),
  );
}

class PizzaHome extends StatefulWidget {
  const PizzaHome({super.key, this.storage});
  final GameStorage? storage;
  @override
  State<PizzaHome> createState() => _PizzaHomeState();
}

class _PizzaHomeState extends State<PizzaHome> with WidgetsBindingObserver {
  GameState game = GameState();
  final audio = GameAudio();
  GameStorage? storage;
  bool buyingRecipe = false;
  String page = 'home';
  bool ready = false, paused = false, appActive = true;
  List<Offset> toppingPoints = [], saucePoints = [];
  List<String> toppingKinds = [];
  final Set<int> sauceCells = {}, cutLines = {};
  int ovenSeconds = 6;
  Timer? ovenTimer, saveTimer;
  Future<void> saveQueue = Future.value();
  String? persistenceError;
  bool showingRecipeIntro = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      storage = widget.storage ?? await GameStorage.open();
      var raw = await storage!.load();
      if (raw == null) {
        try {
          final legacy = await SharedPreferences.getInstance();
          raw = legacy.getString('pizza_game_v1');
        } catch (_) {
          // Legacy preferences must not disable SQLite or new purchases.
        }
      }
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        game = GameState.fromJson(
          Map<String, dynamic>.from(data['game'] as Map),
        );
        List<Offset> points(dynamic v) => v is List
            ? v
                  .whereType<List>()
                  .where(
                    (p) =>
                        p.length == 2 &&
                        p[0] is num &&
                        p[1] is num &&
                        (p[0] as num).isFinite &&
                        (p[1] as num).isFinite,
                  )
                  .map(
                    (p) => Offset(
                      (p[0] as num).toDouble().clamp(0, 1),
                      (p[1] as num).toDouble().clamp(0, 1),
                    ),
                  )
                  .take(2000)
                  .toList()
            : [];
        toppingPoints = points(data['toppingPoints']);
        saucePoints = points(data['saucePoints']);
        toppingKinds =
            (data['toppingKinds'] as List?)
                ?.whereType<String>()
                .take(toppingPoints.length)
                .toList() ??
            [];
        if (data['sauceCells'] is List) {
          sauceCells.addAll((data['sauceCells'] as List).whereType<int>());
        }
        if (data['cutLines'] is List) {
          cutLines.addAll((data['cutLines'] as List).whereType<int>());
        }
        final sec = data['ovenSeconds'];
        if (sec is int) ovenSeconds = sec.clamp(0, 6);
        audio.musicEnabled = data['musicEnabled'] != false;
        final m = data['music'], e = data['effects'];
        if (m is num && m.isFinite) {
          audio.musicVolume = m.toDouble().clamp(0, 1);
        }
        if (e is num && e.isFinite) {
          audio.effectsVolume = e.toDouble().clamp(0, 1);
        }
      }
      await storage!.save(_snapshot());
    } catch (_) {
      storage = null;
      persistenceError = 'Não foi possível restaurar o preparo anterior.';
    }
    if (!mounted) return;
    setState(() => ready = true);
    ovenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted ||
          paused ||
          !appActive ||
          page != 'kitchen' ||
          game.stage != KitchenStage.oven ||
          game.actions != 2) {
        return;
      }
      setState(() {
        if (ovenSeconds > 0) ovenSeconds--;
        if (ovenSeconds == 0 && game.performAction()) audio.ovenReady();
      });
      _save();
    });
    await audio.start();
    await audio.volumes(audio.musicVolume, audio.effectsVolume);
    if (mounted) setState(() {});
  }

  String _snapshot() => jsonEncode({
    'game': game.toJson(),
    'toppingPoints': toppingPoints.map((p) => [p.dx, p.dy]).toList(),
    'toppingKinds': toppingKinds,
    'saucePoints': saucePoints.map((p) => [p.dx, p.dy]).toList(),
    'sauceCells': sauceCells.toList(),
    'cutLines': cutLines.toList(),
    'ovenSeconds': ovenSeconds,
    'music': audio.musicVolume,
    'musicEnabled': audio.musicEnabled,
    'effects': audio.effectsVolume,
  });

  Future<void> _save() {
    if (buyingRecipe) return saveQueue;
    final snapshot = _snapshot();
    saveQueue = saveQueue.then((_) async {
      try {
        if (storage != null) await storage!.save(snapshot);
      } catch (_) {
        if (mounted) {
          setState(
            () => persistenceError =
                'Não foi possível salvar. Mantenha esta sessão aberta.',
          );
        }
      }
    });
    return saveQueue;
  }

  void _scheduleSave() {
    saveTimer?.cancel();
    saveTimer = Timer(const Duration(milliseconds: 200), _save);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) setState(() => appActive = state == AppLifecycleState.resumed);
    audio.suspend(!appActive || paused);
    _save();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ovenTimer?.cancel();
    saveTimer?.cancel();
    audio.dispose();
    super.dispose();
  }

  Future<void> _start(int i, {bool free = false}) async {
    if (showingRecipeIntro || i < 0 || i >= GameState.orders.length) return;
    showingRecipeIntro = true;
    RecipeIntroAction? action;
    try {
      while (mounted) {
        action = await showDialog<RecipeIntroAction>(
          context: context,
          builder: (_) => RecipeIntroDialog(
            recipe: GameState.orders[i].recipe,
            allowDecline: !free,
          ),
        );
        if (!mounted || action != RecipeIntroAction.decline) break;
        i = game.randomOrderIndex(
          excludingFlavor: GameState.orders[i].recipe.id,
        );
      }
    } finally {
      showingRecipeIntro = false;
    }
    if (!mounted || action != RecipeIntroAction.start) return;
    if (!game.startOrder(i, freeMode: free)) return;
    toppingPoints = [];
    toppingKinds = [];
    saucePoints = [];
    sauceCells.clear();
    cutLines.clear();
    ovenSeconds = 6;
    setState(() => page = 'kitchen');
    _save();
  }

  void _advance() {
    audio.rub(false);
    if (!game.advance()) return;
    cutLines.clear();
    setState(() {});
    _save();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: page == 'home',
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        if (page == 'kitchen') {
          _pause();
        } else {
          setState(() => page = 'home');
        }
      }
    },
    child: Scaffold(
      body: !ready
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/branding/calabresa-mark.png',
                    width: 180,
                    height: 180,
                    semanticLabel: 'Pizza de calabresa',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pizza Game',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  if (persistenceError != null)
                    MaterialBanner(
                      content: Text(persistenceError!),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              setState(() => persistenceError = null),
                          child: const Text('Entendi'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: switch (page) {
                      'free' => _free(),
                      'shop' => _shop(),
                      'kitchen' => _kitchen(),
                      _ => _home(),
                    },
                  ),
                ],
              ),
            ),
    ),
  );
  Widget _home() => LayoutBuilder(
    builder: (context, b) {
      final small = b.maxWidth < 650;
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/kitchen-menu.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cream.withValues(alpha: .96),
                  cream.withValues(alpha: small ? .85 : .05),
                ],
                stops: const [.05, 1],
              ),
            ),
          ),
          Align(
            alignment: small ? Alignment.center : Alignment.centerLeft,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(small ? 24 : 56),
              child: SizedBox(
                width: 390,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'UM POUCO DE FARINHA, MUITO CARINHO',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: sage,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pizza\nGame',
                      style: TextStyle(
                        fontSize: 76,
                        height: .95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -4,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sua cozinha. Seu ritmo.\nReceitas gostosas, feitas com calma.',
                      style: TextStyle(fontSize: 18, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _start(game.nextOrderIndex),
                        icon: const Icon(Icons.play_arrow_rounded, size: 52),
                        label: const Text(
                          'Jogar',
                          style: TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (game.hasSession)
                      _menuButton(
                        'Continuar preparo',
                        Icons.play_arrow_rounded,
                        () {
                          setState(() => page = 'kitchen');
                        },
                      ),
                    _menuButton(
                      'Modo livre',
                      Icons.spa_outlined,
                      () => setState(() => page = 'free'),
                      secondary: true,
                    ),
                    _menuButton(
                      'Minha cozinha · ${formatCoins(game.coins)} moedas',
                      Icons.chair_outlined,
                      () => setState(() => page = 'shop'),
                      secondary: true,
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: _settings,
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Configurações'),
                        ),
                        TextButton(
                          onPressed: _credits,
                          child: const Text('Créditos'),
                        ),
                        if (Platform.isLinux ||
                            Platform.isWindows ||
                            Platform.isMacOS)
                          TextButton(
                            onPressed: () async {
                              await _save();
                              exit(0);
                            },
                            child: const Text('Sair'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'FEITO PARA DESACELERAR',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: sage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  Widget _menuButton(
    String label,
    IconData icon,
    VoidCallback action, {
    bool secondary = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(
      width: double.infinity,
      child: secondary
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: cream.withValues(alpha: .8),
                foregroundColor: ink,
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Color(0xFFCBBBA3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: action,
              icon: Icon(icon),
              label: Text(label),
            )
          : FilledButton.icon(
              onPressed: action,
              icon: Icon(icon),
              label: Text(label),
            ),
    ),
  );
  Widget _header(String eyebrow, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
    child: Row(
      children: [
        IconButton(
          onPressed: () => setState(() => page = 'home'),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: sage,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Chip(
          avatar: const Icon(Icons.monetization_on_outlined, size: 18),
          label: Text(formatCoins(game.coins)),
        ),
      ],
    ),
  );
  Future<void> _previewRecipe(PizzaRecipe recipe) async {
    if (buyingRecipe) return;
    final buy = await showDialog<bool>(
      context: context,
      builder: (_) => ShopPreviewDialog(
        name: recipe.name,
        preview: ShopProductPreview(recipe: recipe),
        price: recipe.price,
        balance: game.coins,
        owned: game.ownsRecipe(recipe.id),
        equipped: false,
        reward: recipe.reward,
      ),
    );
    if (buy == true && mounted) await _purchaseRecipe(recipe);
  }

  Future<void> _previewCosmetic(Cosmetic item) async {
    if (buyingRecipe) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ShopPreviewDialog(
        name: item.name,
        preview: ShopProductPreview(cosmetic: item),
        price: item.price,
        balance: game.coins,
        owned: game.ownedCosmetics.contains(item.id),
        equipped: game.isEquipped(item),
      ),
    );
    if (confirm == true && mounted) {
      await _purchaseCosmetic(
        item,
        owned: game.ownedCosmetics.contains(item.id),
      );
    }
  }

  Future<void> _purchaseRecipe(PizzaRecipe recipe) async {
    if (buyingRecipe || game.ownsRecipe(recipe.id)) return;
    if (game.coins < recipe.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Faltam ${formatCoins(recipe.price - game.coins)} moedas para ${recipe.name}.',
          ),
        ),
      );
      return;
    }
    if (storage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O salvamento precisa estar disponível para comprar receitas.',
          ),
        ),
      );
      return;
    }
    await _commitPurchase(() => game.buyRecipe(recipe.id));
  }

  Future<void> _purchaseCosmetic(Cosmetic item, {required bool owned}) async {
    if (buyingRecipe) return;
    await _commitPurchase(
      () => owned ? game.equipCosmetic(item.id) : game.buyCosmetic(item.id),
    );
  }

  Future<void> _commitPurchase(bool Function() change) async {
    if (storage == null || buyingRecipe) return;
    setState(() => buyingRecipe = true);
    saveTimer?.cancel();
    await saveQueue;
    final before = game.toJson();
    if (change()) {
      final write = storage!.save(_snapshot());
      saveQueue = write.catchError((Object _) {});
      try {
        await write;
      } catch (_) {
        game = GameState.fromJson(before);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A compra não foi salva. Suas moedas foram mantidas.',
              ),
            ),
          );
        }
      }
    }
    if (mounted) setState(() => buyingRecipe = false);
  }

  Future<void> _confirmStart(int i, {bool free = false}) async {
    if (game.hasSession) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Começar outra pizza?'),
          content: const Text(
            'O preparo em andamento será substituído. Suas moedas e conquistas continuam salvas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Manter preparo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Começar'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    _start(i, free: free);
  }

  Widget _free() => Column(
    children: [
      _header(
        'Receitas · ${formatCoins(game.coins)} moedas',
        'Hoje a receita é sua',
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: List.generate(
            PizzaRecipe.recipes.length,
            (i) => Card(
              color: const Color(0xFFF0E4CC),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/recipes/${PizzaRecipe.recipes[i].id}.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  PizzaRecipe.recipes[i].name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  game.ownsRecipe(PizzaRecipe.recipes[i].id)
                      ? 'Pedido rende ${formatCoins(PizzaRecipe.recipes[i].reward)} moedas.'
                      : 'Comprar por ${formatCoins(PizzaRecipe.recipes[i].price)} moedas',
                ),
                trailing: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: sage,
                  size: 44,
                ),
                onTap: buyingRecipe
                    ? null
                    : () => game.ownsRecipe(PizzaRecipe.recipes[i].id)
                          ? _confirmStart(
                              GameState.orders
                                  .firstWhere(
                                    (o) =>
                                        o.recipe.id ==
                                        PizzaRecipe.recipes[i].id,
                                  )
                                  .index,
                              free: true,
                            )
                          : _previewRecipe(PizzaRecipe.recipes[i]),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  Widget _shop() => Column(
    children: [
      _header(
        '${formatCoins(game.coins)} moedas para novas receitas e detalhes',
        'Minha cozinha',
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Personalize sua cozinha com toalhas, saleiros, fornos e plantas. Cada categoria pode ser usada junto com as outras.',
            ),
            const SizedBox(height: 16),
            ...PizzaRecipe.recipes
                .where((r) => r.price > 0)
                .map(
                  (recipe) => Card(
                    child: ListTile(
                      onTap: () => _previewRecipe(recipe),
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: ShopProductPreview(recipe: recipe),
                      ),
                      title: Text(recipe.name),
                      subtitle: Text(
                        'Entrega: ${formatCoins(recipe.reward)} moedas',
                      ),
                      trailing: OutlinedButton(
                        onPressed: buyingRecipe
                            ? null
                            : () => _previewRecipe(recipe),
                        child: const Text('Ver'),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            ...[
              const Cosmetic('cream', 'Toalha azul original', 0),
              const Cosmetic(
                'salt_default',
                'Saleiro azul original',
                0,
                category: 'salt',
              ),
              const Cosmetic(
                'oven_default',
                'Forno original',
                0,
                category: 'oven',
              ),
              const Cosmetic(
                'plant_default',
                'Sem plantas',
                0,
                category: 'plant',
              ),
              ...GameState.cosmetics,
            ].map((item) {
              return Card(
                color: const Color(0xFFF0E4CC),
                child: InkWell(
                  onTap: () => _previewCosmetic(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: ShopProductPreview(cosmetic: item),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name),
                              Text(
                                game.isEquipped(item)
                                    ? 'Em uso'
                                    : game.ownedCosmetics.contains(item.id)
                                    ? 'Comprado'
                                    : '${formatCoins(item.price)} moedas',
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: buyingRecipe
                              ? null
                              : () => _previewCosmetic(item),
                          child: const Text('Ver'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ],
  );
  Widget _kitchen() => NaturalKitchen(
    game: game,
    audio: audio,
    toppingPoints: toppingPoints,
    toppingKinds: toppingKinds,
    saucePoints: saucePoints,
    sauceCells: sauceCells,
    cutLines: cutLines,
    active: !paused && appActive,
    ovenSeconds: ovenSeconds,
    onChanged: () {
      setState(() {});
      _scheduleSave();
    },
    onAdvance: _advance,
    onPause: _pause,
    onSettings: _settings,
    onHome: () => setState(() => page = 'home'),
    onRestart: () => _start(game.orderIndex, free: game.freeMode),
    onNext: () => _start(game.nextOrderIndex),
  );

  Future<void> _pause() async {
    if (paused) return;
    setState(() => paused = true);
    await audio.suspend(true);
    await _save();
    if (!mounted) return;
    final a = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uma pausa para respirar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'resume'),
              child: const Text('Retomar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'restart'),
              child: const Text('Recomeçar receita'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'settings'),
              child: const Text('Configurações'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'home'),
              child: const Text('Voltar ao menu'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (a == 'restart') _start(game.orderIndex, free: game.freeMode);
    if (a == 'home') setState(() => page = 'home');
    if (a == 'settings') await _settings();
    paused = false;
    await audio.suspend(!appActive);
    if (mounted) setState(() {});
  }

  Future<void> _settings() async {
    final wasPaused = paused;
    setState(() => paused = true);
    await audio.rub(false);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Do seu jeitinho'),
          content: SizedBox(
            width: 330,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Música de fundo'),
                  secondary: Icon(
                    audio.musicEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                  ),
                  value: audio.musicEnabled,
                  onChanged: (enabled) {
                    update(() => audio.musicEnabled = enabled);
                    audio.volumes(audio.musicVolume, audio.effectsVolume);
                    _scheduleSave();
                  },
                ),
                Slider(
                  value: audio.musicVolume,
                  onChanged: (v) {
                    update(() => audio.musicVolume = v);
                    audio.volumes(v, audio.effectsVolume);
                    _scheduleSave();
                  },
                ),
                const Text('Sons do preparo'),
                Slider(
                  value: audio.effectsVolume,
                  onChanged: (v) {
                    update(() => audio.effectsVolume = v);
                    audio.volumes(audio.musicVolume, v);
                    _scheduleSave();
                  },
                ),
                if (!audio.available)
                  const Text(
                    'Não foi possível iniciar o áudio. Confira a saída de som.',
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Pronto'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => paused = wasPaused);
    await audio.suspend(!appActive || paused);
    _save();
  }

  void _credits() => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Feito com carinho'),
      content: const SingleChildScrollView(
        child: Text(
          'Pizza Game\nArte da bancada desenhada em Flutter.\nIlustração do menu criada com geração de imagem.\n\nSons fornecidos pelo jogador:\nMarvelous Gift — BloodPixelHero\nCutting Fabric — manuelaurreaf\nSand in a Bag — Snap2\nCrowd Cheer — FoolBoy Media (trecho de 3 s)\n\nCréditos e arquivos originais em ASSETS.md.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Voltar'),
        ),
      ],
    ),
  );
}
