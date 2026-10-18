import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'ready_pizza_photo.dart';
import 'ingredient_details.dart';
import 'prepared_ingredient_bowl.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/assisted_actions.dart';
import '../services/game_audio.dart';
import 'kitchen_painter.dart';
import 'pizza_box_scene.dart';
import 'celebration_overlay.dart';

/// The board is the control surface. Text is provided through semantics only.
class NaturalKitchen extends StatefulWidget {
  const NaturalKitchen({
    super.key,
    required this.game,
    required this.audio,
    required this.toppingPoints,
    required this.toppingKinds,
    required this.saucePoints,
    required this.sauceCells,
    required this.cutLines,
    required this.onChanged,
    required this.onAdvance,
    required this.onPause,
    required this.onSettings,
    required this.onHome,
    required this.onRestart,
    required this.onNext,
    required this.active,
    required this.ovenSeconds,
    this.animateHints = true,
  });
  final GameState game;
  final GameAudio audio;
  final List<Offset> toppingPoints, saucePoints;
  final List<String> toppingKinds;
  final Set<int> sauceCells, cutLines;
  final VoidCallback onChanged,
      onAdvance,
      onPause,
      onSettings,
      onHome,
      onRestart,
      onNext;
  final bool active, animateHints;
  final int ovenSeconds;
  @override
  State<NaturalKitchen> createState() => _NaturalKitchenState();
}

class _NaturalKitchenState extends State<NaturalKitchen>
    with TickerProviderStateMixin {
  late final AnimationController hint;
  late final AnimationController cutMotion;
  late final AnimationController pourMotion;
  String? pouringIngredient;
  Offset? pouringFrom;
  double mixPhase = 0;
  ui.Image? readyPizzaImage;
  String? requestedPhoto;
  late final AnimationController doorMotion, transferMotion, boxMotion;
  Offset? flightFrom, flightTo, lastSprinkle;
  VoidCallback? afterFlight;
  bool flightOut = false, crossedCenter = false;
  final List<Offset> cuttingTrail = [];
  int sprinkled = 0;
  Offset? strokeOrigin;
  Offset? guidedFrom, guidedTo;
  KitchenStage? guidedStage;
  bool cutThisGesture = false;
  Timer? transition, friction;
  late KitchenStage observed;
  String? dragging;
  Offset? pointer, previous, tool;
  Size boardSize = Size.zero;
  double distance = 0;
  bool ovenOpen = true, gestureEnded = true;
  DateTime lastAction = DateTime(2000);
  GameState get game => widget.game;
  double get u => math.min(boardSize.width, boardSize.height);
  Offset get center => Offset(boardSize.width * .5, boardSize.height * .51);
  double get r => u * .31;
  Offset _normal(Offset p) =>
      Offset(.5 + (p.dx - center.dx) / u, .51 + (p.dy - center.dy) / u);
  Offset _screen(Offset p) =>
      center + Offset((p.dx - .5) * u, (p.dy - .51) * u);
  bool _inside(Offset p, [double scale = 1]) =>
      (p - center).distance < r * scale;
  Offset get restPizza => boardSize.width > boardSize.height * 1.05
      ? Offset(boardSize.width * .14, boardSize.height * .72)
      : Offset(boardSize.width * .5, boardSize.height * .87);
  List<String> get pots => switch (game.stage) {
    KitchenStage.ingredients => GameState.doughIngredients,
    KitchenStage.toppings => game.recipe.toppings,
    KitchenStage.sauce => [
      game.recipe.id == 'chocolate' ? 'creme de chocolate' : 'molho',
    ],
    _ => [],
  };
  double get potSize => (u * .19).clamp(56, 86);
  Offset _potPosition(int index) {
    final count = pots.length;
    final spacing = math.min(
      potSize + 12,
      (boardSize.width - 28) / math.max(1, count),
    );
    return Offset(
      boardSize.width * .5 + (index - (count - 1) / 2) * spacing,
      boardSize.height * .86,
    );
  }

  Offset get toolPoint => tool == null
      ? switch (game.stage) {
          KitchenStage.roll => center + Offset(0, r * .5),
          KitchenStage.chop => center + Offset(r * 1.03, 0),
          KitchenStage.slice => center + Offset(r * .9, -r * .7),
          _ => center + Offset(r * .75, -r * .15),
        }
      : _screen(tool!);

  Future<void> _loadRecipePhoto() async {
    final id = game.recipe.id;
    requestedPhoto = id;
    final data = await rootBundle.load('assets/images/recipes/$id.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 768,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted || game.recipe.id != id) {
      frame.image.dispose();
      return;
    }
    final previousPhoto = readyPizzaImage;
    setState(() => readyPizzaImage = frame.image);
    previousPhoto?.dispose();
  }

  Widget _pizzaSprite({bool cooked = false}) => CustomPaint(
    painter: cooked && readyPizzaImage != null
        ? ReadyPizzaPhoto(readyPizzaImage!)
        : FoodSprite('pizza-${game.recipe.id}', bowl: false),
  );

  @override
  void initState() {
    super.initState();
    _loadRecipePhoto();
    observed = game.stage;
    ovenOpen = game.actions < 2;
    hint = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    pourMotion =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 700),
            value: 1,
          )
          ..addListener(_frame)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _queueNext();
          });
    cutMotion =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 550),
            value: 1,
          )
          ..addListener(() {
            if (guidedFrom != null && guidedTo != null) {
              final cutPoint = Offset.lerp(
                guidedFrom!,
                guidedTo!,
                Curves.easeInOut.transform(cutMotion.value),
              );
              if (guidedStage == KitchenStage.slice) {
                cuttingTrail.clear();
                cuttingTrail.addAll([guidedFrom!, cutPoint!]);
              }
            }
            if (mounted) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && guidedStage != null) {
              final stage = guidedStage;
              guidedStage = null;
              guidedFrom = null;
              guidedTo = null;
              if (mounted && game.stage == stage) {
                if (stage == KitchenStage.slice) {
                  widget.cutLines.add(game.actions);
                  game.performAction();
                }
                _changed();
              }
            }
          });
    doorMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: ovenOpen ? 1 : 0,
    )..addListener(_frame);
    transferMotion =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 650),
          )
          ..addListener(_frame)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              final done = afterFlight;
              afterFlight = null;
              flightFrom = null;
              flightTo = null;
              done?.call();
            }
          });
    boxMotion =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2400),
          )
          ..addListener(_frame)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed &&
                mounted &&
                widget.active &&
                game.stage == KitchenStage.serve) {
              widget.onAdvance();
              widget.audio.celebrate();
            }
          });
    if (game.stage == KitchenStage.serve) boxMotion.forward();
    if (game.stage == KitchenStage.oven && game.actions == 0) {
      doorMotion.forward(from: 0);
    }
    if (widget.animateHints) hint.repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _queueNext());
  }

  @override
  void didUpdateWidget(covariant NaturalKitchen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (requestedPhoto != game.recipe.id) _loadRecipePhoto();
    if (observed != game.stage) {
      observed = game.stage;
      cuttingTrail.clear();
      crossedCenter = false;
      if (game.stage == KitchenStage.serve) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) boxMotion.forward(from: 0);
        });
      }
      transition?.cancel();
      transition = null;
      dragging = null;
      pointer = null;
      previous = null;
      tool = null;
      distance = 0;
      gestureEnded = true;
      ovenOpen = game.stage == KitchenStage.oven && game.actions < 2;
      lastAction = DateTime.now();
      doorMotion.value = ovenOpen ? 1 : 0;
      if (game.stage == KitchenStage.oven && game.actions == 0) {
        doorMotion.forward(from: 0);
      }
    }
    if (!widget.active) {
      transition?.cancel();
      transition = null;
      dragging = null;
      pointer = null;
      gestureEnded = true;
      widget.audio.rub(false);
    }
    if (widget.active &&
        game.stage == KitchenStage.serve &&
        boxMotion.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active && game.stage == KitchenStage.serve) {
          widget.onAdvance();
          widget.audio.celebrate();
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _queueNext());
  }

  void _frame() {
    if (mounted) setState(() {});
  }

  Offset get miniOven => Offset(boardSize.width * .86, boardSize.height * .18);
  void _fly(Offset from, Offset to, VoidCallback done, {bool out = false}) {
    flightFrom = _normal(from);
    flightTo = _normal(to);
    flightOut = out;
    afterFlight = done;
    transferMotion.forward(from: 0);
  }

  void _sprinkle(Offset p, String kind) {
    if (!_inside(p, 1.55) ||
        (lastSprinkle != null && (p - lastSprinkle!).distance < r * .25)) {
      return;
    }
    if (game.selectIngredient(kind)) {
      lastSprinkle = p;
      sprinkled++;
      final index = (game.toppingCounts[kind] ?? 1) - 1;
      widget.toppingPoints.add(
        assistedToppingPosition(index, game.recipe.toppings.indexOf(kind)),
      );
      widget.toppingKinds.add(kind);
      final quadrants = widget.toppingPoints
          .map((v) => (v.dx >= .5 ? 1 : 0) + (v.dy >= .51 ? 2 : 0))
          .toSet();
      game.distribution = quadrants.length / 4;
    }
  }

  @override
  void dispose() {
    transition?.cancel();
    friction?.cancel();
    hint.dispose();
    doorMotion.dispose();
    transferMotion.dispose();
    boxMotion.dispose();
    cutMotion.dispose();
    pourMotion.dispose();
    readyPizzaImage?.dispose();
    super.dispose();
  }

  bool get _autoReady =>
      game.canAdvance &&
      ![
        KitchenStage.toppings,
        KitchenStage.oven,
        KitchenStage.serve,
        KitchenStage.complete,
      ].contains(game.stage) &&
      (game.stage != KitchenStage.toppings || game.progress >= 1);
  void _queueNext() {
    if (!mounted ||
        !widget.active ||
        !gestureEnded ||
        !_autoReady ||
        cutMotion.isAnimating ||
        pourMotion.isAnimating ||
        transition != null) {
      return;
    }
    final stage = game.stage;
    transition = Timer(const Duration(milliseconds: 850), () {
      transition = null;
      if (mounted &&
          widget.active &&
          gestureEnded &&
          game.stage == stage &&
          _autoReady) {
        widget.audio.rub(false);
        widget.onAdvance();
      }
    });
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
    _queueNext();
  }

  void _rub() {
    widget.audio.rub(true);
    friction?.cancel();
    friction = Timer(
      const Duration(milliseconds: 180),
      () => widget.audio.rub(false),
    );
  }

  bool _toolHit(Offset p) {
    final t = toolPoint;
    return switch (game.stage) {
      KitchenStage.roll => Rect.fromCenter(
        center: t,
        width: r * 2.6,
        height: math.max(54, u * .18),
      ).contains(p),
      KitchenStage.chop || KitchenStage.slice => Rect.fromCenter(
        center: t,
        width: math.max(60, u * .17),
        height: u * .55,
      ).contains(p),
      _ => Rect.fromLTRB(
        t.dx - 32,
        t.dy - r * 1.3,
        t.dx + 32,
        t.dy + r * .38,
      ).contains(p),
    };
  }

  void _start(Offset p) {
    if (!widget.active ||
        game.isComplete ||
        transition != null ||
        transferMotion.isAnimating ||
        doorMotion.isAnimating ||
        cutMotion.isAnimating) {
      return;
    }
    lastAction = DateTime.now();
    previous = p;
    strokeOrigin = p;
    pointer = p;
    distance = 0;
    gestureEnded = false;
    dragging = null;
    lastSprinkle = null;
    sprinkled = 0;
    crossedCenter = false;
    cutThisGesture = false;
    cuttingTrail.clear();
    for (var i = 0; i < pots.length; i++) {
      if ((p - _potPosition(i)).distance < potSize * .62) {
        final item = pots[i];
        if (game.stage == KitchenStage.ingredients &&
            game.selectedIngredients.contains(item)) {
          break;
        }
        dragging = item;
        break;
      }
    }
    if (dragging == null) {
      switch (game.stage) {
        case KitchenStage.knead:
          if (_inside(p, .85)) dragging = 'dough';
        case KitchenStage.mix ||
            KitchenStage.roll ||
            KitchenStage.sauce ||
            KitchenStage.chop ||
            KitchenStage.slice:
          if (_toolHit(p) ||
              ([KitchenStage.slice, KitchenStage.chop].contains(game.stage) &&
                  _inside(p, 1.3))) {
            dragging = 'tool';
            tool = _normal(toolPoint);
          }
        case KitchenStage.toppings:
          if (_inside(p) && game.toppingCounts.isNotEmpty) {
            dragging = 'pizza-to-oven';
          }
        case KitchenStage.oven:
          if (game.actions == 0 && (p - restPizza).distance < u * .17) {
            dragging = 'pizza-in';
          } else if (game.actions == 3 && ovenOpen && _inside(p, .8)) {
            dragging = 'pizza-out';
          }
        case KitchenStage.serve:
          if (_inside(p)) {
            dragging = 'serve';
          }
        default:
          break;
      }
    }
    setState(() {});
  }

  void _move(Offset p) {
    if (!widget.active || dragging == null || previous == null) return;
    final delta = p - previous!;
    previous = p;
    pointer = p;
    lastAction = DateTime.now();
    if (dragging == 'tool' || dragging == 'dough') {
      if (dragging == 'tool') {
        final moved = toolPoint + delta;
        tool = _normal(
          Offset(
            moved.dx.clamp(16, boardSize.width - 16),
            moved.dy.clamp(16, boardSize.height - 16),
          ),
        );
      }
      final tip = dragging == 'dough' ? p : toolPoint;
      if ([KitchenStage.slice, KitchenStage.chop].contains(game.stage)) {
        distance += delta.distance;
        if (!cutThisGesture &&
            !cutMotion.isAnimating &&
            distance >= u * .08 &&
            (_inside(p, 1.5) || _inside(toolPoint, 1.5)) &&
            !game.canAdvance) {
          cutThisGesture = true;
          guidedStage = game.stage;
          if (game.stage == KitchenStage.slice) {
            cutMotion.duration = const Duration(milliseconds: 550);
            final guide = assistedPizzaCut(game.actions);
            guidedFrom = guide.$1;
            guidedTo = guide.$2;
          } else {
            final guide = assistedIngredientCut(game.actions);
            guidedFrom = guide.$1;
            guidedTo = guide.$2;
            cutMotion.duration = Duration(
              milliseconds: (game.actions + 1) % 5 == 0 ? 1100 : 550,
            );
            widget.cutLines.add(game.actions);
            game.performAction();
          }
          if ((tool! - guidedTo!).distance < (tool! - guidedFrom!).distance) {
            final start = guidedFrom;
            guidedFrom = guidedTo;
            guidedTo = start;
          }
          widget.audio.cut();
          cutMotion.forward(from: 0);
        }
        _changed();
        return;
      }
      if (game.stage == KitchenStage.slice &&
          !crossedCenter &&
          (tip - center).distance >= r * .75) {
        strokeOrigin = tip;
      }
      if (_inside(tip, 1.05)) {
        distance += delta.distance;
        if (game.stage == KitchenStage.mix) mixPhase += delta.distance / u * 8;
        if ([
          KitchenStage.mix,
          KitchenStage.knead,
          KitchenStage.roll,
        ].contains(game.stage)) {
          if (distance > u * .12) {
            game.performAction();
            distance = 0;
          }
          _rub();
        } else if (game.stage == KitchenStage.sauce && _inside(tip, .82)) {
          final x = ((tip.dx - center.dx + r) / (r * 2) * 6).floor(),
              y = ((tip.dy - center.dy + r) / (r * 2) * 6).floor();
          if (widget.sauceCells.add(x + y * 6)) game.performAction();
          if (widget.saucePoints.isEmpty ||
              (_screen(widget.saucePoints.last) - tip).distance > u * .018) {
            widget.saucePoints.add(_normal(tip));
          }
          _rub();
        }
      } else {
        distance = 0;
        widget.audio.rub(false);
      }
    }
    if (game.stage == KitchenStage.toppings &&
        game.recipe.toppings.contains(dragging)) {
      _sprinkle(p, dragging!);
    }
    _changed();
  }

  void _end() {
    final p = pointer, kind = dragging;
    gestureEnded = true;
    dragging = null;
    pointer = null;
    previous = null;
    widget.audio.rub(false);
    if (p != null && kind != null) {
      if (game.stage == KitchenStage.ingredients && _inside(p, 1)) {
        if (game.selectIngredient(kind)) {
          pouringIngredient = kind;
          pouringFrom = _normal(p);
          pourMotion.forward(from: 0);
        }
      } else if (game.stage == KitchenStage.toppings &&
          _inside(p, 1.55) &&
          game.recipe.toppings.contains(kind)) {
        if (sprinkled == 0) _sprinkle(p, kind);
      } else if (game.stage == KitchenStage.sauce &&
          pots.contains(kind) &&
          _inside(p, .82)) {
        tool = _normal(p);
        if (widget.sauceCells.add(18)) {
          game.performAction();
        }
        widget.saucePoints.add(_normal(p));
      } else if (game.stage == KitchenStage.toppings &&
          kind == 'pizza-to-oven' &&
          (p - miniOven).distance < u * .20) {
        _fly(p, miniOven, widget.onAdvance);
      } else if (game.stage == KitchenStage.oven &&
          kind == 'pizza-in' &&
          ovenOpen &&
          _inside(p, .85)) {
        _fly(p, center, () {
          game.performAction();
          _changed();
        });
      } else if (game.stage == KitchenStage.oven &&
          kind == 'pizza-out' &&
          (p - restPizza).distance < u * .23) {
        _fly(p, restPizza, widget.onAdvance, out: true);
      } else if (game.stage == KitchenStage.serve &&
          kind == 'serve' &&
          p.dy < boardSize.height * .22) {
        widget.onAdvance();
      }
    }
    _changed();
  }

  void _cancel() {
    gestureEnded = true;
    dragging = null;
    pointer = null;
    previous = null;
    widget.audio.rub(false);
    _changed();
  }

  void _tap(Offset p) {
    if (!widget.active ||
        game.stage != KitchenStage.oven ||
        doorMotion.isAnimating ||
        transferMotion.isAnimating) {
      return;
    }
    final handle = Offset(center.dx, center.dy + (ovenOpen ? .41 : .35) * u);
    if ((p - handle).distance < u * .23 || _inside(p, .9)) {
      if (game.actions == 1 && ovenOpen) {
        ovenOpen = false;
        doorMotion.reverse().whenComplete(() {
          if (mounted && game.stage == KitchenStage.oven && game.actions == 1) {
            widget.audio.ovenDoorClosed();
            game.performAction();
            _changed();
          }
        });
      } else if (game.actions == 3) {
        ovenOpen = !ovenOpen;
        if (ovenOpen) {
          doorMotion.forward();
        } else {
          doorMotion.reverse().whenComplete(() {
            if (mounted && !ovenOpen) widget.audio.ovenDoorClosed();
          });
        }
      }
      _changed();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 60,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Pausar',
              onPressed: widget.onPause,
              icon: const Icon(Icons.pause_circle_filled_rounded, size: 34),
            ),
            Expanded(
              child: game.freeMode
                  ? const Icon(Icons.spa_rounded, color: Color(0xFF647F59))
                  : _orderPictures(),
            ),
            IconButton(
              tooltip: 'Som',
              onPressed: widget.onSettings,
              icon: const Icon(Icons.volume_up_rounded, size: 30),
            ),
          ],
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: LayoutBuilder(
              builder: (context, b) {
                boardSize = Size(b.maxWidth, b.maxHeight);
                return Semantics(
                  label: 'Bancada de preparo',
                  child: GestureDetector(
                    key: const Key('natural-board'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _start(d.localPosition),
                    onPanUpdate: (d) => _move(d.localPosition),
                    onPanEnd: (_) => _end(),
                    onPanCancel: _cancel,
                    onTapUp: (d) => _tap(d.localPosition),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: KitchenPainter(
                            stage: game.stage.name,
                            progress: game.progress,
                            recipeId: game.recipe.id,
                            toppings: widget.toppingPoints,
                            toppingKinds: widget.toppingKinds,
                            saucePoints: widget.saucePoints,
                            readyPizzaImage: readyPizzaImage,
                            doughIngredients: game.selectedIngredients,
                            pourIngredient: pouringIngredient,
                            pourProgress: pourMotion.value,
                            pourFrom: pouringFrom,
                            mixPhase: mixPhase,
                            cosmetic: game.activeCosmetic,
                            ovenStyle: game.equippedFor('oven'),
                            plantStyle: game.equippedFor('plant'),
                            toolPosition: _normal(toolPoint),
                            showTool: !game.isComplete,
                            ovenOpen: ovenOpen,
                            ovenActions: game.actions,
                            ovenDoorProgress: doorMotion.value,
                            cuttingTrail: cuttingTrail,
                            boardOnly:
                                game.stage == KitchenStage.serve ||
                                game.stage == KitchenStage.complete,
                            cutAnimation: cutMotion.value,
                            cutCount: game.actions,
                          ),
                        ),
                        if (game.stage == KitchenStage.serve ||
                            game.stage == KitchenStage.complete)
                          IgnorePointer(
                            child: PizzaBoxScene(
                              progress: game.isComplete ? 1 : boxMotion.value,
                              recipeId: game.recipe.id,
                              readyPizzaImage: readyPizzaImage,
                            ),
                          ),
                        if (game.stage == KitchenStage.toppings &&
                            game.toppingCounts.isNotEmpty)
                          _at(
                            miniOven,
                            Size(u * .18, u * .18),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF647F59),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.microwave_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                        if (flightFrom != null && flightTo != null)
                          _at(
                            Offset.lerp(
                              _screen(flightFrom!),
                              _screen(flightTo!),
                              Curves.easeInOutCubic.transform(
                                transferMotion.value,
                              ),
                            )!,
                            Size(u * .32, u * .32),
                            _pizzaSprite(cooked: flightOut),
                          ),
                        if (!game.isComplete)
                          Positioned(
                            top: 14,
                            left: 16,
                            right: 16,
                            child: _pictureSteps(),
                          ),
                        for (var i = 0; i < pots.length; i++) _pot(i),
                        if (game.stage == KitchenStage.oven) ...[
                          if (game.actions == 0 || game.actions == 3)
                            _at(
                              restPizza,
                              Size(u * .30, u * .27),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAE8D8),
                                  borderRadius: BorderRadius.circular(70),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: game.actions == 0
                                    ? CustomPaint(
                                        painter: FoodSprite(
                                          'pizza-${game.recipe.id}',
                                          bowl: false,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.south_rounded,
                                          color: Color(0xFF647F59),
                                          size: 34,
                                        ),
                                      ),
                              ),
                            ),
                          if (game.actions == 2)
                            _at(
                              center + Offset(0, -u * .31),
                              const Size(60, 60),
                              CircularProgressIndicator(
                                value: (6 - widget.ovenSeconds) / 6,
                                color: const Color(0xFFFFCF69),
                                strokeWidth: 7,
                              ),
                            ),
                        ],
                        if (dragging != null &&
                            pointer != null &&
                            dragging != 'tool' &&
                            dragging != 'dough')
                          _at(
                            pointer!,
                            Size(potSize * 1.18, potSize * 1.18),
                            Transform.rotate(
                              angle: -.23,
                              child:
                                  (dragging == 'pizza-out' ||
                                      dragging == 'serve')
                                  ? _pizzaSprite(cooked: true)
                                  : CustomPaint(
                                      painter: FoodSprite(
                                        dragging!.startsWith('pizza') ||
                                                dragging == 'serve'
                                            ? 'pizza-${game.recipe.id}'
                                            : dragging!,
                                        bowl:
                                            !dragging!.startsWith('pizza') &&
                                            dragging != 'serve',
                                      ),
                                    ),
                            ),
                          ),
                        if (!game.isComplete)
                          IgnorePointer(
                            child: AnimatedBuilder(
                              animation: hint,
                              builder: (context, _) => _hintPicture(),
                            ),
                          ),
                        if (game.isComplete) _result(),
                        if (game.isComplete && !game.freeMode)
                          IgnorePointer(
                            child: CelebrationOverlay(
                              coins: game.result?.coins ?? 0,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ],
  );
  Widget _at(Offset p, Size size, Widget child) => Positioned(
    left: p.dx - size.width / 2,
    top: p.dy - size.height / 2,
    width: size.width,
    height: size.height,
    child: IgnorePointer(child: child),
  );
  Widget _pot(int i) {
    final item = pots[i], p = _potPosition(i);
    final done = game.stage == KitchenStage.ingredients
        ? game.selectedIngredients.contains(item)
        : game.stage == KitchenStage.toppings &&
              (game.toppingCounts[item] ?? 0) >= game.order.targetFor(item);
    return Positioned(
      left: p.dx - potSize / 2,
      top: p.dy - potSize / 2,
      width: potSize,
      height: potSize,
      child: Semantics(
        label: 'Pote de $item',
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: dragging == item
                  ? .3
                  : done
                  ? .55
                  : 1,
              child: CustomPaint(
                painter: FoodSprite(item, saltStyle: game.equippedFor('salt')),
              ),
            ),
            if (done)
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF647F59),
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _orderPictures() => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF647F59),
          child: Icon(Icons.face_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
        ...game.recipe.toppings.map(
          (t) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 30,
                  child: CustomPaint(painter: FoodSprite(t, bowl: false)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    game.order.targetFor(t),
                    (i) => Container(
                      margin: const EdgeInsets.all(1),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < (game.toppingCounts[t] ?? 0)
                            ? const Color(0xFF647F59)
                            : const Color(0xFFCDB894),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _pictureSteps() {
    const stages = [
      KitchenStage.ingredients,
      KitchenStage.mix,
      KitchenStage.roll,
      KitchenStage.chop,
      KitchenStage.sauce,
      KitchenStage.toppings,
      KitchenStage.oven,
      KitchenStage.slice,
      KitchenStage.serve,
    ];
    const icons = [
      Icons.grain_rounded,
      Icons.soup_kitchen_rounded,
      Icons.horizontal_rule_rounded,
      Icons.content_cut_rounded,
      Icons.water_drop_rounded,
      Icons.local_pizza_rounded,
      Icons.local_fire_department_rounded,
      Icons.content_cut_rounded,
      Icons.face_rounded,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < stages.length; i++)
          if (stages[i] != KitchenStage.chop ||
              game.recipe.toppings.contains('calabresa'))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                stages[i].index < game.stage.index
                    ? Icons.check_circle_rounded
                    : icons[i],
                size: game.stage == stages[i] ? 24 : 16,
                color: game.stage == stages[i]
                    ? const Color(0xFFB75B42)
                    : stages[i].index < game.stage.index
                    ? const Color(0xFF647F59)
                    : const Color(0x997F6248),
              ),
            ),
      ],
    );
  }

  Widget _hintPicture() {
    if (dragging != null ||
        !widget.active ||
        transition != null ||
        DateTime.now().difference(lastAction).inMilliseconds < 1600) {
      return const SizedBox.shrink();
    }
    Offset from, to;
    Offset? cutStart;
    final t = (hint.value / .70).clamp(0.0, 1.0),
        fade = hint.value > .85 ? (1 - hint.value) / .15 : 1.0;
    if (game.stage == KitchenStage.toppings && game.progress >= 1) {
      from = center;
      to = miniOven;
    } else if (pots.isNotEmpty &&
        !(game.stage == KitchenStage.sauce && game.actions > 0)) {
      var i = 0;
      if (game.stage == KitchenStage.ingredients) {
        i = pots.indexWhere((v) => !game.selectedIngredients.contains(v));
      } else if (game.stage == KitchenStage.toppings) {
        i = pots.indexWhere(
          (v) => (game.toppingCounts[v] ?? 0) < game.order.targetFor(v),
        );
      }
      if (i < 0) return const SizedBox.shrink();
      from = _potPosition(i);
      to = center + Offset(r * .25, -r * .15);
    } else if (game.stage == KitchenStage.oven) {
      if (game.actions == 0) {
        from = restPizza;
        to = center;
      } else if (game.actions == 1 || game.actions == 3 && !ovenOpen) {
        from = center + Offset(0, (ovenOpen ? .41 : .35) * u);
        to = from + const Offset(0, 12);
      } else if (game.actions == 3) {
        from = center;
        to = restPizza;
      } else {
        return const SizedBox.shrink();
      }
    } else if (game.stage == KitchenStage.chop) {
      final guide = assistedIngredientCut(game.actions.clamp(0, 9));
      from = toolPoint;
      cutStart = _screen(guide.$1);
      to = _screen(guide.$2);
    } else if (game.stage == KitchenStage.slice) {
      final line = List.generate(
        4,
        (i) => i,
      ).firstWhere((i) => !widget.cutLines.contains(i), orElse: () => 0);
      final angle = line * math.pi / 4;
      from = toolPoint;
      final direction = Offset(math.cos(angle), math.sin(angle)) * r * .9;
      cutStart = center + direction;
      to = center - direction;
    } else if (game.stage == KitchenStage.serve) {
      from = center;
      to = Offset(boardSize.width * .5, boardSize.height * .13);
    } else {
      from = game.stage == KitchenStage.knead ? center : toolPoint;
      to =
          from +
          Offset(
            game.stage == KitchenStage.chop ? 0 : -r * .7,
            game.stage == KitchenStage.chop ? r * .6 : r * .45,
          );
    }
    final p = cutStart == null
        ? Offset.lerp(from, to, Curves.easeInOut.transform(t))!
        : hint.value < .3
        ? from
        : hint.value < .55
        ? Offset.lerp(
            from,
            cutStart,
            Curves.easeInOut.transform((hint.value - .3) / .25),
          )!
        : Offset.lerp(
            cutStart,
            to,
            Curves.easeInOut.transform(((hint.value - .55) / .25).clamp(0, 1)),
          )!;
    return Stack(
      children: [
        CustomPaint(size: boardSize, painter: _GuideLine(cutStart ?? from, to)),
        Positioned(
          left: p.dx - 20,
          top: p.dy - 10,
          child: Opacity(
            opacity: fade,
            child: const Icon(
              Icons.touch_app_rounded,
              size: 48,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color(0x88563D31),
                  blurRadius: 5,
                  offset: Offset(1, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _result() => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!game.freeMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Icon(
                  i < (game.result?.stars ?? 0)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFDCAC43),
                  size: 48,
                ),
              ),
            )
          else
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFB75B42),
              size: 48,
            ),
          if (!game.freeMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: Color(0xFFDCAC43),
                ),
                Text(
                  ' +${formatCoins(game.result?.coins ?? 0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Menu',
                onPressed: widget.onHome,
                icon: const Icon(Icons.home_rounded, size: 30),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Repetir receita',
                onPressed: widget.onRestart,
                icon: const Icon(Icons.replay_rounded, size: 30),
              ),
              if (!game.freeMode) ...[
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: 'Próximo pedido',
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 30),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class _GuideLine extends CustomPainter {
  _GuideLine(this.from, this.to);
  final Offset from, to;
  @override
  void paint(Canvas c, Size s) {
    final d = (to - from).distance;
    final paint = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0.0; i < d; i += 15) {
      c.drawLine(
        Offset.lerp(from, to, i / d)!,
        Offset.lerp(from, to, math.min(1, (i + 6) / d))!,
        paint,
      );
    }
    c.drawCircle(to, 18, Paint()..color = const Color(0x55FFFFFF));
  }

  @override
  bool shouldRepaint(covariant _GuideLine old) =>
      old.from != from || old.to != to;
}

/// Recognizable ingredients rather than written labels or emoji glyphs.
class FoodSprite extends CustomPainter {
  FoodSprite(this.kind, {this.bowl = true, this.saltStyle = 'salt_default'});
  final String saltStyle;
  final String kind;
  final bool bowl;
  @override
  void paint(Canvas c, Size s) {
    if (bowl && preparedIngredients.contains(kind)) {
      PreparedIngredientBowl(kind).paint(c, s);
      return;
    }
    final m = math.min(s.width, s.height),
        o = Offset(s.width / 2, s.height / 2),
        r = m * .39;
    void dot(Offset p, double radius, Color color) =>
        c.drawCircle(p, radius, Paint()..color = color);
    void rect(Rect rect, Color color, [double round = 3]) => c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(round)),
      Paint()..color = color,
    );
    void strawberry(Offset center, double size, {bool sliced = false}) {
      final fruit = Path()
        ..moveTo(center.dx, center.dy + size)
        ..cubicTo(
          center.dx - size * 1.5,
          center.dy - size * .55,
          center.dx - size * .65,
          center.dy - size * 1.2,
          center.dx,
          center.dy - size * .65,
        )
        ..cubicTo(
          center.dx + size * .65,
          center.dy - size * 1.2,
          center.dx + size * 1.5,
          center.dy - size * .55,
          center.dx,
          center.dy + size,
        );
      c.drawPath(fruit, Paint()..color = const Color(0xFFC6383C));
      if (sliced) {
        c.save();
        c.translate(center.dx, center.dy);
        c.scale(.7, .78);
        c.translate(-center.dx, -center.dy);
        c.drawPath(fruit, Paint()..color = const Color(0xFFFFA297));
        c.restore();
        c.drawLine(
          center - Offset(0, size * .35),
          center + Offset(0, size * .58),
          Paint()
            ..color = const Color(0xFFFFD3B9)
            ..strokeWidth = size * .13,
        );
      }
      for (var seed = 0; seed < 7; seed++) {
        final row = seed ~/ 3;
        final position =
            center +
            Offset(
              (seed % 3 - 1) * size * (.47 - row * .1),
              -size * .3 + row * size * .4,
            );
        c.drawOval(
          Rect.fromCenter(
            center: position,
            width: size * .1,
            height: size * .17,
          ),
          Paint()..color = const Color(0xFFFFE6A1),
        );
      }
      for (var leaf = -1; leaf <= 1; leaf++) {
        final top = center - Offset(0, size * .65);
        final path = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            top.dx + leaf * size * .7 - size * .2,
            top.dy - size * .7,
            top.dx + leaf * size * .7,
            top.dy - size * .3,
          )
          ..quadraticBezierTo(
            top.dx + size * .2,
            top.dy + size * .12,
            top.dx,
            top.dy,
          );
        c.drawPath(path, Paint()..color = const Color(0xFF4E7A3B));
      }
    }

    if (bowl) {
      c.drawOval(
        Rect.fromCenter(
          center: o + Offset(0, m * .085),
          width: m * .93,
          height: m * .86,
        ),
        Paint()
          ..color = const Color(0x38563D31)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, m * .025),
      );
      c.drawCircle(
        o,
        m * .46,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFE0CEAE)],
          ).createShader(Rect.fromCircle(center: o, radius: m * .46)),
      );
      dot(o, m * .38, const Color(0xFFC5B89D));
      dot(o + Offset(0, m * .015), m * .355, const Color(0xFFE7DDC9));
      c.drawArc(
        Rect.fromCircle(center: o, radius: m * .42),
        math.pi,
        math.pi * .8,
        false,
        Paint()
          ..color = const Color(0xCCFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = m * .018,
      );
    }
    if (kind.startsWith('pizza-')) {
      dot(o + Offset(0, r * .06), r, const Color(0xFFB57B3C));
      dot(o, r, const Color(0xFFE8B76D));
      dot(
        o,
        r * .87,
        kind.contains('chocolate')
            ? const Color(0xFF673927)
            : const Color(0xFFC65435),
      );
      for (var i = 0; i < 7; i++) {
        final p = o + Offset(math.cos(i * 2.4), math.sin(i * 2.4)) * r * .58;
        if (kind.contains('chocolate')) {
          strawberry(p, r * .19, sliced: true);
        } else if (kind.contains('frango') ||
            (kind.contains('mista') && i.isEven)) {
          for (var j = 0; j < 4; j++) {
            final q = p + Offset((j % 2) * r * .10, (j ~/ 2) * r * .09);
            c.drawLine(
              q,
              q + Offset(r * .18, -r * .07),
              Paint()
                ..color = const Color(0xFFFFDEA7)
                ..strokeWidth = r * .07
                ..strokeCap = StrokeCap.round,
            );
          }
        } else if (kind.contains('calabresa') || kind.contains('mista')) {
          dot(p, r * .21, const Color(0xFF743C2D));
          dot(p, r * .175, const Color(0xFFBA7054));
          dot(p + Offset(r * .05, -r * .05), r * .035, const Color(0xFFF1C7A4));
          c.drawCircle(
            p + Offset(r * .12, r * .1),
            r * .19,
            Paint()
              ..color = const Color(0xFFC390B3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * .035,
          );
        } else {
          dot(p, r * .16, const Color(0xFFD66B49));
          c.save();
          c.translate(p.dx, p.dy);
          c.rotate(i * 1.2);
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: r * .42,
              height: r * .19,
            ),
            Paint()..color = const Color(0xFF4F803C),
          );
          c.drawLine(
            Offset(-r * .16, 0),
            Offset(r * .16, 0),
            Paint()
              ..color = const Color(0xFF9BBB6B)
              ..strokeWidth = r * .02,
          );
          c.restore();
        }
      }
      return;
    }
    if (kind == 'água') {
      rect(
        Rect.fromCenter(center: o, width: r * 1.35, height: r * 1.65),
        const Color(0xFF8FCBDA),
        r * .2,
      );
      rect(
        Rect.fromCenter(
          center: o + Offset(0, r * .25),
          width: r * 1.13,
          height: r * .9,
        ),
        const Color(0xFF4D9AB5),
        r * .15,
      );
      c.drawArc(
        Rect.fromCenter(
          center: o + Offset(r * .75, 0),
          width: r * .65,
          height: r,
        ),
        -math.pi / 2,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFFD3F1F2)
          ..strokeWidth = r * .17,
      );
      return;
    }
    if (kind == 'sal') {
      rect(
        Rect.fromCenter(
          center: o + Offset(0, r * .1),
          width: r,
          height: r * 1.3,
        ),
        const Color(0xFFF7F5ED),
        r * .15,
      );
      rect(
        Rect.fromCenter(
          center: o - Offset(0, r * .65),
          width: r * 1.15,
          height: r * .4,
        ),
        saltStyle == 'salt_gold'
            ? const Color(0xFFDAAF4D)
            : saltStyle == 'salt_rose'
            ? const Color(0xFFD092A0)
            : const Color(0xFF79A4B5),
        r * .1,
      );
      for (var i = 0; i < 3; i++) {
        dot(
          o + Offset((i - 1) * r * .23, -r * .68),
          r * .055,
          const Color(0xFF3E6577),
        );
      }
      return;
    }
    if (kind == 'farinha') {
      rect(
        Rect.fromCenter(center: o, width: r * 1.4, height: r * 1.6),
        const Color(0xFFE4C392),
        r * .12,
      );
      c.drawLine(
        o + Offset(0, r * .5),
        o - Offset(0, r * .5),
        Paint()
          ..color = const Color(0xFFA57938)
          ..strokeWidth = 3,
      );
      for (var i = 0; i < 3; i++) {
        for (final side in [-1, 1]) {
          c.drawOval(
            Rect.fromCenter(
              center: o + Offset(side * r * .18, -r * .35 + i * r * .25),
              width: r * .35,
              height: r * .17,
            ),
            Paint()..color = const Color(0xFFA57938),
          );
        }
      }
      return;
    }
    if (kind == 'molho' || kind == 'creme de chocolate') {
      dot(
        o,
        r * .85,
        kind == 'molho' ? const Color(0xFFC85132) : const Color(0xFF673927),
      );
      c.drawArc(
        Rect.fromCircle(center: o, radius: r * .5),
        0,
        4,
        false,
        Paint()
          ..color = const Color(0x66FFF1C5)
          ..strokeWidth = 3,
      );
      return;
    }
    for (var i = 0; i < 7; i++) {
      final p =
          o +
          Offset(math.cos(i * 2.4), math.sin(i * 2.4)) *
              r *
              math.sqrt(i / 7) *
              .7;
      switch (kind) {
        case 'camarão':
          paintShrimp(c, p, r * .26);
        case 'catupiri':
          paintCatupiri(c, p, r * .28);
        case 'carne de sol':
        case 'frango':
          for (var strand = 0; strand < 6; strand++) {
            final q =
                p + Offset((strand % 3 - 1) * r * .14, (strand ~/ 3) * r * .13);
            c.drawLine(
              q,
              q + Offset(r * .22, -r * .12),
              Paint()
                ..color = strand.isEven
                    ? const Color(0xFFE6BC7C)
                    : const Color(0xFFFFDEA7)
                ..strokeWidth = r * .09
                ..strokeCap = StrokeCap.round,
            );
          }
        case 'muçarela':
        case 'provolone':
        case 'gorgonzola':
        case 'parmesão':
        case 'queijo':
          for (var strand = 0; strand < 9; strand++) {
            final angle = strand * 2.3 + i;
            final q = p + Offset(math.cos(angle), math.sin(angle)) * r * .22;
            c.drawLine(
              q,
              q + Offset(math.cos(angle + .6), math.sin(angle + .6)) * r * .35,
              Paint()
                ..color = strand.isEven
                    ? const Color(0xFFFFE8A5)
                    : const Color(0xFFEFC264)
                ..strokeWidth = r * .045
                ..strokeCap = StrokeCap.round,
            );
          }
        case 'chocolate':
          rect(
            Rect.fromCenter(center: p, width: r * .57, height: r * .43),
            const Color(0xFF6F3C2B),
          );
          rect(
            Rect.fromCenter(
              center: p - Offset(r * .03, r * .05),
              width: r * .4,
              height: r * .22,
            ),
            const Color(0xFF925640),
          );
          for (final axis in [0, 1]) {
            c.drawLine(
              p - Offset(axis == 0 ? r * .22 : 0, axis == 1 ? r * .16 : 0),
              p + Offset(axis == 0 ? r * .22 : 0, axis == 1 ? r * .16 : 0),
              Paint()
                ..color = const Color(0xFF502B22)
                ..strokeWidth = r * .025,
            );
          }
        case 'calabresa':
          dot(p + Offset(0, r * .025), r * .28, const Color(0xFF713D2B));
          dot(p, r * .25, const Color(0xFFB2694D));
          dot(p, r * .21, const Color(0xFFBE795D));
          for (var j = 0; j < 3; j++) {
            dot(
              p + Offset(math.cos(j * 2) * r * .13, math.sin(j * 2) * r * .13),
              r * .04,
              const Color(0xFFFFCEAB),
            );
          }
        case 'cebola':
          c.drawCircle(
            p,
            r * .25,
            Paint()
              ..color = const Color(0xFFB47CA3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * .08,
          );
          c.drawCircle(
            p,
            r * .14,
            Paint()
              ..color = const Color(0xFFF6E1ED)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * .05,
          );
        case 'manjericão':
          c.save();
          c.translate(p.dx, p.dy);
          c.rotate(i * 1.7);
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: r * .6,
              height: r * .28,
            ),
            Paint()..color = const Color(0xFF5E8747),
          );
          c.drawLine(
            Offset(-r * .25, 0),
            Offset(r * .25, 0),
            Paint()
              ..color = const Color(0xFF9DBB6B)
              ..strokeWidth = 1.5,
          );
          c.restore();
        case 'morango':
          strawberry(p, r * .29, sliced: i.isOdd);
        case 'confeitos':
          c.drawLine(
            p - Offset(r * .11, 0),
            p + Offset(r * .11, r * .1),
            Paint()
              ..color = [
                Colors.pink,
                Colors.lightBlue,
                Colors.amber,
                Colors.green,
              ][i % 4]
              ..strokeWidth = r * .12
              ..strokeCap = StrokeCap.round,
          );
        default:
          dot(p, r * .12, const Color(0xFFD8B276));
      }
    }
  }

  @override
  bool shouldRepaint(covariant FoodSprite old) =>
      old.kind != kind || old.bowl != bowl || old.saltStyle != saltStyle;
}
