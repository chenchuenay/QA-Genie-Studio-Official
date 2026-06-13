import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

class TierIcon extends StatelessWidget {
  final bool isPro;
  final double size;

  const TierIcon({super.key, required this.isPro, this.size = 60});

  @override
  Widget build(BuildContext context) {
    if (!isPro) {
      // Core: Black star inside blue circle
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        ),
        child: const Icon(
          Icons.star,
          color: Colors.black,
          size: 30,
        ),
      );
    } else {
      // Pro: Glassy blue star with glow
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withOpacity(0.3),
              AppColors.accent.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.star,
            color: AppColors.accent,
            size: 36,
          ),
        ),
      );
    }
  }
}
