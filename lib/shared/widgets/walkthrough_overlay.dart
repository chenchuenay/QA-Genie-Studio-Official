import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

class WalkthroughStep {
  final GlobalKey key;
  final IconData icon;
  final String title;
  final String description;

  const WalkthroughStep({
    required this.key,
    required this.icon,
    required this.title,
    required this.description,
  });
}

class WalkthroughOverlay extends StatefulWidget {
  final List<WalkthroughStep> steps;

  const WalkthroughOverlay({super.key, required this.steps});

  static Future<void> show({
    required BuildContext context,
    required List<WalkthroughStep> steps,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => WalkthroughOverlay(steps: steps),
      ),
    );
  }

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    final ctx = widget.steps[_currentStep].key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 300),
      );
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() {});
    });
  }

  void _next() {
    if (_currentStep >= widget.steps.length - 1) return;
    _animCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentStep++);
      _scrollToCurrent();
      _animCtrl.forward();
    });
  }

  void _dismiss() => Navigator.of(context).pop();

  Rect? _getTargetRect() {
    final ctx = widget.steps[_currentStep].key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      box.size.width,
      box.size.height,
    ).inflate(8);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final isLast = _currentStep == widget.steps.length - 1;
    final padBottom = MediaQuery.of(context).padding.bottom;
    final padTop = MediaQuery.of(context).padding.top;
    final targetRect = _getTargetRect();

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            if (targetRect != null)
              ClipPath(
                clipper: _HoleClipper(targetRect),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              )
            else
              Container(color: Colors.black.withOpacity(0.65)),

            if (targetRect != null)
              Positioned(
                left: targetRect.left - 1,
                top: targetRect.top - 1,
                width: targetRect.width + 2,
                height: targetRect.height + 2,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.8),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              top: padTop + 8,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.25),
                  ),
                ),
                child: TextButton(
                  onPressed: _dismiss,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Skip  →',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: padBottom + 24,
              child: _buildTooltip(step, isLast),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(WalkthroughStep step, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(step.icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                step.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            step.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            ...List.generate(widget.steps.length, (i) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentStep
                      ? AppColors.accent
                      : AppColors.border,
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              height: 42,
              child: isLast
                  ? ElevatedButton(
                      onPressed: _dismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _HoleClipper extends CustomClipper<Path> {
  final Rect holeRect;

  _HoleClipper(this.holeRect);

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        holeRect,
        const Radius.circular(14),
      ));
    return path..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(_HoleClipper old) => old.holeRect != holeRect;
}
