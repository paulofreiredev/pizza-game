import 'package:pizza_game/ui/recipe_intro_dialog.dart';

import 'dart:convert';

import 'package:pizza_game/ui/shop_product_preview.dart';
import 'package:pizza_game/services/game_storage.dart';
import 'package:sqflite/sqflite.dart' show Database;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pizza_game/main.dart';
import 'package:pizza_game/game/game_state.dart';
import 'package:pizza_game/services/game_audio.dart';
import 'package:pizza_game/ui/kitchen_painter.dart';
import 'package:pizza_game/ui/natural_kitchen.dart';

class MemoryStorage implements GameStorage {
  String? snapshot;
  @override
  Database get database => throw UnimplementedError();
  @override
  Future<String?> load() async => snapshot;
  @override
  Future<void> save(String value) async {
    snapshot = value;
  }

  @override
  Future<void> close() async {}
}

class SilentAudio extends GameAudio {
  int celebrations = 0, doorClosings = 0;
  @override
  Future<void> ovenDoorClosed() async {
    doorClosings++;
  }

  @override
  Future<void> ovenReady() async {}
  @override
  Future<void> rub(bool active) async {}
  @override
  Future<void> cut() async {}
  @override
  Future<void> celebrate() async {
    celebrations++;
  }
}

class KitchenHarness extends StatefulWidget {
  const KitchenHarness(this.game, this.audio, {super.key});
  final GameState game;
  final SilentAudio audio;
  @override
  State<KitchenHarness> createState() => _KitchenHarnessState();
}

class _KitchenHarnessState extends State<KitchenHarness> {
  final List<Offset> toppings = [], sauce = [];
  final List<String> kinds = [];
  final Set<int> cells = {}, cuts = {};
  Timer? timer;
  int seconds = 6;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.game.stage == KitchenStage.oven && widget.game.actions == 2) {
        setState(() {
          if (seconds > 0) seconds--;
          if (seconds == 0) widget.game.performAction();
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: NaturalKitchen(
        game: widget.game,
        audio: widget.audio,
        toppingPoints: toppings,
        toppingKinds: kinds,
        saucePoints: sauce,
        sauceCells: cells,
        cutLines: cuts,
        active: true,
        ovenSeconds: seconds,
        animateHints: false,
        onChanged: () => setState(() {}),
        onAdvance: () {
          setState(() {
            widget.game.advance();
            cuts.clear();
          });
        },
        onPause: () {},
        onSettings: () {},
        onHome: () {},
        onRestart: () {},
        onNext: () {},
      ),
    ),
  );
}

void prepareUntil(GameState game, KitchenStage target) {
  while (game.stage != target) {
    for (final t in game.requiredIngredients) {
      for (
        var i = 0;
        i < (game.stage == KitchenStage.toppings ? game.order.targetFor(t) : 1);
        i++
      ) {
        game.selectIngredient(t);
      }
    }
    while (game.actions < game.requiredActions) {
      game.performAction();
    }
    game.distribution = 1;
    if (!game.advance()) throw StateError('fixture');
  }
}

void main() {
  testWidgets(
    'shop previews are free to inspect and purchases require confirmation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = MemoryStorage()
        ..snapshot = jsonEncode({
          'game': GameState.fromJson({'coins': 50000, 'moneyVersion': 2})
              .toJson(),
        });
      await tester.pumpWidget(PizzaGameApp(storage: storage));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Minha cozinha ·'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Saleiro dourado'), 300);
      await tester.tap(find.text('Saleiro dourado'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopPreviewDialog), findsOneWidget);
      expect(find.text('Comprar por 129,00 moedas'), findsOneWidget);
      expect((jsonDecode(storage.snapshot!)['game'] as Map)['coins'], 50000);
      await tester.tap(find.byTooltip('Fechar prévia'));
      await tester.pumpAndSettle();
      expect((jsonDecode(storage.snapshot!)['game'] as Map)['coins'], 50000);
      await tester.tap(find.text('Saleiro dourado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comprar por 129,00 moedas'));
      await tester.pumpAndSettle();
      final saved = GameState.fromJson(
        jsonDecode(storage.snapshot!)['game'] as Map<String, dynamic>,
      );
      expect(saved.coins, 37100);
      expect(saved.equippedFor('salt'), 'salt_gold');
      await tester.scrollUntilVisible(
        find.text('Carne de sol com queijo'),
        -400,
      );
      await tester.tap(find.text('Carne de sol com queijo'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopPreviewDialog), findsOneWidget);
      expect(find.text('Faltam 28,00 moedas.'), findsOneWidget);
      final buy = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Comprar por 399,00 moedas'),
      );
      expect(buy.onPressed, isNull);
      await tester.tap(find.byTooltip('Fechar prévia'));
      await tester.pumpAndSettle();
      expect((jsonDecode(storage.snapshot!)['game'] as Map)['coins'], 37100);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'declining a request offers a different owned recipe without starting or charging',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = MemoryStorage();
      await tester.pumpWidget(PizzaGameApp(storage: storage));
      await tester.pumpAndSettle();
      final before = storage.snapshot;
      await tester.tap(find.text('Jogar'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        final previous = tester
            .widget<RecipeIntroDialog>(find.byType(RecipeIntroDialog))
            .recipe
            .id;
        await tester.ensureVisible(
          find.byKey(const Key('recipe-intro-decline')),
        );
        await tester.tap(find.byKey(const Key('recipe-intro-decline')));
        await tester.pumpAndSettle();
        final next = tester
            .widget<RecipeIntroDialog>(find.byType(RecipeIntroDialog))
            .recipe
            .id;
        expect(next, isNot(previous));
        expect(PizzaRecipe.recipes.take(3).any((r) => r.id == next), isTrue);
        expect(find.byKey(const Key('natural-board')), findsNothing);
        expect(storage.snapshot, before);
      }
      await tester.tap(find.byKey(const Key('recipe-intro-start')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('natural-board')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'menu and illustrated board work on phone and desktop without cooking buttons',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(PizzaGameApp(storage: MemoryStorage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jogar'));
      await tester.pumpAndSettle();
      expect(find.text('Vamos preparar!'), findsOneWidget);
      expect(find.byKey(const Key('natural-board')), findsNothing);
      expect(find.text('Pedidos chegando'), findsNothing);
      expect(find.text('Vamos preparar!'), findsOneWidget);
      await tester.tap(find.byKey(const Key('recipe-intro-start')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('natural-board')), findsOneWidget);
      expect(find.text('Próxima etapa'), findsNothing);
      expect(find.text('Toque guiado'), findsNothing);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'direct gestures prepare calabresa, operate oven and pack pizza',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = GameState()..startOrder(1, freeMode: true);
      final audio = SilentAudio();
      await tester.pumpWidget(KitchenHarness(game, audio));
      await tester.pump();
      Rect board() => tester.getRect(find.byKey(const Key('natural-board')));
      double unit() => math.min(board().width, board().height);
      Offset center() =>
          board().topLeft + Offset(board().width * .5, board().height * .51);
      Offset tool() {
        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<KitchenPainter>()
            .single;
        final p = painter.toolPosition!;
        return center() + Offset((p.dx - .5) * unit(), (p.dy - .51) * unit());
      }

      Future<void> drag(Offset from, Offset to) async {
        await tester.dragFrom(from, to - from);
        await tester.pump(const Duration(milliseconds: 50));
      }

      Future<void> toolStroke(List<Offset> positions) async {
        final g = await tester.startGesture(tool());
        await g.moveBy(const Offset(0, 20));
        await tester.pump();
        for (final target in positions) {
          await g.moveBy(target - tool());
          await tester.pump(const Duration(milliseconds: 40));
        }
        await g.up();
        await tester.pump(
          Duration(
            milliseconds:
                game.stage == KitchenStage.chop && game.actions % 5 == 0
                ? 1200
                : 600,
          ),
        );
      }

      for (var i = 0; i < 4; i++) {
        final spacing = math.min(
          (unit() * .19).clamp(56, 86) + 12,
          (board().width - 28) / 4,
        );
        await drag(
          board().topLeft +
              Offset(
                board().width * .5 + (i - 1.5) * spacing,
                board().height * .86,
              ),
          center(),
        );
      }
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(game.stage, KitchenStage.mix);
      for (final stage in [KitchenStage.mix, KitchenStage.roll]) {
        expect(game.stage, stage);
        if (stage == KitchenStage.knead) {
          final g = await tester.startGesture(center());
          await g.moveBy(const Offset(0, 20));
          for (var i = 0; i < 16; i++) {
            await g.moveTo(
              center() + Offset(i.isEven ? -unit() * .18 : unit() * .18, 0),
            );
            await tester.pump(const Duration(milliseconds: 30));
          }
          await g.up();
        } else {
          await toolStroke(
            List.generate(
              18,
              (i) =>
                  center() + Offset(i.isEven ? -unit() * .18 : unit() * .18, 0),
            ),
          );
        }
        await tester.pump(const Duration(seconds: 1));
      }
      expect(game.stage, KitchenStage.chop);
      final r = unit() * .31;
      for (var i = 0; i < 10; i++) {
        final x = center().dx - r * .72 + (i % 5) * r * .35,
            y = center().dy + (i < 5 ? -r * .34 : r * .48);
        await toolStroke([Offset(x, y - r * .4), Offset(x, y + r * .1)]);
      }
      await tester.pump(const Duration(seconds: 1));
      expect(game.stage, KitchenStage.sauce);
      final cells = <int, Offset>{};
      for (var x = -25; x <= 25; x++) {
        for (var y = -25; y <= 25; y++) {
          final p = Offset(x / 30 * r, y / 30 * r);
          if (p.distance < r * .80) {
            final key =
                ((p.dx + r) / (r * 2) * 6).floor() +
                6 * ((p.dy + r) / (r * 2) * 6).floor();
            cells.putIfAbsent(key, () => center() + p);
          }
        }
      }
      await toolStroke(cells.values.toList());
      await tester.pump(const Duration(seconds: 1));
      expect(game.stage, KitchenStage.toppings);
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          final spacing = math.min(
            (unit() * .19).clamp(56, 86) + 12,
            (board().width - 28) / 3,
          );
          final drop = center() + Offset((j - 1) * r * .45, (i - 1) * r * .4);
          await drag(
            board().topLeft +
                Offset(
                  board().width * .5 + (i - 1) * spacing,
                  board().height * .86,
                ),
            drop,
          );
        }
      }
      await tester.pump(const Duration(seconds: 1));
      expect(game.stage, KitchenStage.toppings);
      expect(
        game.toppingCounts.values.fold<int>(0, (a, b) => a + b),
        greaterThanOrEqualTo(9),
      );
      await drag(
        center(),
        board().topLeft + Offset(board().width * .86, board().height * .18),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(game.stage, KitchenStage.oven);
      await tester.pump(const Duration(milliseconds: 800));
      Offset tray() => board().width > board().height * 1.05
          ? board().topLeft + Offset(board().width * .14, board().height * .72)
          : board().topLeft + Offset(board().width * .5, board().height * .87);
      await drag(tray(), center());
      await tester.pump(const Duration(milliseconds: 800));
      expect(game.actions, 1);
      await tester.tapAt(center() + Offset(0, unit() * .41));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(game.actions, 2);
      expect(audio.doorClosings, 1);
      await tester.pump(const Duration(seconds: 7));
      await tester.pump();
      expect(game.actions, 3);
      await tester.tapAt(center() + Offset(0, unit() * .35));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await drag(center(), tray());
      await tester.pump(const Duration(milliseconds: 900));
      expect(game.stage, KitchenStage.slice);
      for (var i = 0; i < 4; i++) {
        final d =
            Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4)) *
            r *
            .9;
        await toolStroke([center() + d, center(), center() - d]);
      }
      await tester.pump(const Duration(seconds: 1));
      expect(game.stage, KitchenStage.serve);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(game.isComplete, isTrue);
      expect(audio.celebrations, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets('boxing awards once and displays confetti with actual coins', (
    tester,
  ) async {
    final game = GameState()..startOrder(0);
    prepareUntil(game, KitchenStage.serve);
    final audio = SilentAudio();
    await tester.pumpWidget(KitchenHarness(game, audio));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(game.isComplete, isTrue);
    expect(find.text('+29,29 Moedas'), findsOneWidget);
    expect(audio.celebrations, 1);
    await tester.pump(const Duration(seconds: 4));
    expect(game.coins, 2929);
    expect(audio.celebrations, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
    'dropping topping outside crust still spreads it safely on pizza',
    (tester) async {
      final game = GameState()..startOrder(0, freeMode: true);
      prepareUntil(game, KitchenStage.toppings);
      final audio = SilentAudio();
      await tester.pumpWidget(KitchenHarness(game, audio));
      await tester.pump();
      final rect = tester.getRect(find.byKey(const Key('natural-board'))),
          u = math.min(
            tester.getSize(find.byKey(const Key('natural-board'))).width,
            tester.getSize(find.byKey(const Key('natural-board'))).height,
          );
      final center = rect.topLeft + Offset(rect.width * .5, rect.height * .51);
      final spacing = math.min(
        (u * .19).clamp(56, 86) + 12,
        (rect.width - 28) / 2,
      );
      final pot =
          rect.topLeft +
          Offset(rect.width * .5 - spacing / 2, rect.height * .86);
      for (var n = 0; n < 4; n++) {
        final outside = center + Offset(u * .31 * 1.2, 0);
        await tester.dragFrom(pot, outside - pot);
        await tester.pump(const Duration(milliseconds: 50));
      }
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<KitchenPainter>()
          .single;
      expect(painter.toppings.length, greaterThanOrEqualTo(4));
      expect(
        painter.toppings.every(
          (p) => (p - const Offset(.5, .51)).distance < .31 * .82,
        ),
        isTrue,
      );
      expect(
        painter.toppings
            .map((p) => (p.dx >= .5 ? 1 : 0) + (p.dy >= .51 ? 2 : 0))
            .toSet()
            .length,
        greaterThanOrEqualTo(3),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets('a crooked short gesture animates one clean straight cut', (
    tester,
  ) async {
    final game = GameState()..startOrder(0, freeMode: true);
    prepareUntil(game, KitchenStage.slice);
    await tester.pumpWidget(KitchenHarness(game, SilentAudio()));
    await tester.pump();
    final rect = tester.getRect(find.byKey(const Key('natural-board'))),
        u = math.min(
          tester.getSize(find.byKey(const Key('natural-board'))).width,
          tester.getSize(find.byKey(const Key('natural-board'))).height,
        );
    final center = rect.topLeft + Offset(rect.width * .5, rect.height * .51);
    final gesture = await tester.startGesture(
      center + Offset(-u * .1, u * .08),
    );
    await gesture.moveBy(const Offset(20, 10));
    await tester.pump();
    await gesture.moveBy(Offset(u * .15, -u * .12));
    await tester.pump();
    KitchenPainter currentPainter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<KitchenPainter>()
        .single;
    final beforeMove = currentPainter().toolPosition!;
    await tester.pump(const Duration(milliseconds: 100));
    expect(currentPainter().toolPosition, beforeMove);
    await gesture.moveBy(Offset(-u * .1, u * .16));
    await tester.pump();
    final moved = currentPainter().toolPosition! - beforeMove;
    expect(moved.dx, closeTo(-.1, .001));
    expect(moved.dy, closeTo(.16, .001));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 250));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<KitchenPainter>()
        .single;
    expect(painter.cuttingTrail.length, 2);
    expect(
      painter.cuttingTrail.every((p) => (p.dy - .51).abs() < 1e-10),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(game.actions, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
    'recipe photo can be dismissed without starting a free-play session',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(PizzaGameApp(storage: MemoryStorage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modo livre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calabresa'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Pizza Calabresa pronta'), findsOneWidget);
      expect(find.byKey(const Key('natural-board')), findsNothing);
      await tester.tap(find.byTooltip('Escolher outra pizza'));
      await tester.pumpAndSettle();
      expect(find.text('Hoje a receita é sua'), findsOneWidget);
      expect(find.byKey(const Key('natural-board')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
