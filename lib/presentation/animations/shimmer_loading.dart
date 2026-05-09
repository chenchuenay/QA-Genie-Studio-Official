import 'package:flutter/material.dart';
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});
  @override State<ShimmerLoading> createState() => _ShimmerLoadingState();
}
class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); _animation = ColorTween(begin: Colors.white.withOpacity(0.3), end: Colors.white.withOpacity(0.8)).animate(_controller); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _animation, builder: (context, child) => Container(height: 24, width: 100, decoration: BoxDecoration(color: _animation.value, borderRadius: BorderRadius.circular(12))));
}
class GenerateButtonLoading extends StatefulWidget {
  const GenerateButtonLoading({super.key});
  @override State<GenerateButtonLoading> createState() => _GenerateButtonLoadingState();
}
class _GenerateButtonLoadingState extends State<GenerateButtonLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true); _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: Container(
          width: double.infinity, height: 56,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8E4EC6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.6), blurRadius: 15, offset: const Offset(0, 8))]),
          child: const Center(child: Text("Generating...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
      ),
    );
  }
}
