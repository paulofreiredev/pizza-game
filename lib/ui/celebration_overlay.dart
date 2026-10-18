import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A finite celebration that leaves the earned reward visible after settling.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.coins});

  final int coins;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final entrance = Curves.easeOutBack.transform(
          (_controller.value * 5).clamp(0.0, 1.0),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_controller.value < 1)
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _ConfettiPainter(_controller.value),
                  ),
                ),
              ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 22,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, -72 * (1 - entrance)),
                  child: Opacity(
                    opacity: entrance.clamp(0.0, 1.0),
                    child: Semantics(
                      liveRegion: true,
                      label: 'Você ganhou ${widget.coins} moedas',
                      child: ExcludeSemantics(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7DC),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFF0CB6A),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x305F3A23),
                                blurRadius: 20,
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFD89B26),
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  '+${widget.coins} Moedas',
                                  style: const TextStyle(
                                    color: Color(0xFF725027),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.progress);

  final double progress;
  static const _colors = [
    Color(0xFFE78D83),
    Color(0xFFEEC75E),
    Color(0xFF86AD8D),
    Color(0xFF90BDCF),
    Color(0xFFB99BCB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final opacity = ((1 - progress) * 5).clamp(0.0, 1.0);
    final count = (size.width / 7).round().clamp(48, 160);
    for (var index = 0; index < count; index++) {
      final origin = random.nextDouble() * size.width;
      final delay = random.nextDouble() * .22;
      final age = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      final speed = .65 + random.nextDouble() * .65;
      final sway = random.nextDouble() * math.pi * 2;
      final width = 5 + random.nextDouble() * 6;
      final angle = random.nextDouble() * math.pi * 2;
      if (age == 0) continue;
      final x = origin + math.sin(age * 9 + sway) * (18 + age * 25);
      final y = -25 + age * (size.height + 90) * speed;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + age * (index.isEven ? 8 : -8));
      canvas.scale(1, .35 + math.sin(age * 14 + sway).abs() * .65);
      final paint = Paint()
        ..color = _colors[index % _colors.length].withValues(alpha: opacity);
      if (index % 4 == 0) {
        canvas.drawCircle(Offset.zero, width * .45, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: width * .55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
