import 'package:flutter/material.dart';

class ProBadge extends StatelessWidget {
  final bool isPro;
  const ProBadge({super.key, required this.isPro});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPro
            ? const Color.fromARGB(255, 0, 191, 255)
            : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPro ? 'PRO' : 'FREE',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
