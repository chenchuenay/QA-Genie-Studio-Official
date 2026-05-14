import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/constants.dart';
import 'package:qa_genie/features/beta/logic/beta_manager.dart';
import 'package:qa_genie/features/beta/ui/beta_expired_screen.dart';
import 'package:qa_genie/presentation/navigation/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override void initState() {
    super.initState();
    // Fade/scale for the whole column
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _fadeController.forward();

    // Pulse animation for the logo only
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _checkAccess();
  }

  Future<void> _checkAccess() async {
    await BetaManager.recordInstallIfNew();
    final expired = await BetaManager.isExpired();
    final update = await BetaManager.isUpdateRequired();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (expired || update) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BetaExpiredScreen(isUpdateRequired: update)));
      return;
    }
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  @override void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF080808), Color(0xFF16161A)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing logo
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Image.asset(
                      'assets/logo.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withOpacity(0.08),
                            boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 40, spreadRadius: 6)],
                          ),
                          child: const Icon(Icons.auto_awesome, size: 60, color: AppColors.accent),
                        ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              const Text("QA Genie", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 3, decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
    );
  }
}
