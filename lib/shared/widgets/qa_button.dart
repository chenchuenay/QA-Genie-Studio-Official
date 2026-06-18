import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
// lib/shared/widgets/qa_button.dart

class QAButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final String text;

  final bool loading;

  final IconData? icon;

  final double height;

  final double borderRadius;

  const QAButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.loading = false,
    this.icon,
    this.height = 54,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,

      child: ElevatedButton(
        onPressed: loading ? null : onPressed,

        style: ElevatedButton.styleFrom(
          elevation: 0,

          padding: EdgeInsets.zero,

          backgroundColor: Colors.transparent,

          foregroundColor: Colors.black,

          disabledBackgroundColor: Colors.transparent,

          shadowColor: Colors.transparent,

          splashFactory: NoSplash.splashFactory,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),

        child: Ink(
          decoration: BoxDecoration(
            gradient: loading
                ? LinearGradient(colors: [AppColors.card, AppColors.surface])
                : LinearGradient(
                    colors: [AppColors.accent, AppColors.accentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

            borderRadius: BorderRadius.circular(borderRadius),

            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.16),
                blurRadius: 22,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                      ],

                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
