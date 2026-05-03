import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AnimatedEqualizer extends StatefulWidget {
  final Color color;
  final double size;

  const AnimatedEqualizer({
    super.key,
    this.color = AppColors.primary,
    this.size = 26,
  });

  @override
  State<AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<AnimatedEqualizer>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  static const _durations = [350, 500, 420];
  static const _delays = [0, 120, 60];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: Duration(milliseconds: _durations[i]),
        vsync: this,
      ),
    );

    _anims = _controllers
        .map(
          (c) => Tween<double>(begin: 0.25, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = widget.size / 6;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _anims[i],
            builder: (_, _) => Container(
              width: barWidth,
              height: widget.size * _anims[i].value,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(barWidth / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
