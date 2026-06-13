import 'package:flutter/material.dart';

class AnimatedDots extends StatefulWidget {
  final String label;
  final TextStyle style;
  const AnimatedDots({super.key, required this.label, required this.style});

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anims = List.generate(3, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(i * 0.2, 0.4 + (i * 0.2), curve: Curves.easeInOut)),
    ));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: widget.style),
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Opacity(
              opacity: _anims[i].value,
              child: Text('.', style: widget.style),
            ),
          ),
      ],
    );
  }
}
