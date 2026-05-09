import 'package:flutter/material.dart';
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});
  @override State<ShimmerLoading> createState() => _ShimmerLoadingState();
}
class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation;
  @override void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = ColorTween(begin: Colors.white.withOpacity(0.3), end: Colors.white.withOpacity(0.8)).animate(_controller);
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(height: 24, width: 100, decoration: BoxDecoration(color: _animation.value, borderRadius: BorderRadius.circular(12))),
    );
  }
}
