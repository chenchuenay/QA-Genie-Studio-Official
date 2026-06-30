import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/theme/app_colors.dart';

const _qaTips = [
  'Think about edge cases — what happens when inputs are empty or invalid?',
  'Cover both positive and negative test paths for thorough validation.',
  'Include boundary values to catch off-by-one errors.',
  'Write clear, descriptive test names that explain the intent.',
  'Consider state transitions across different user journeys.',
  'Test for security vulnerabilities like SQL injection or XSS.',
  'Verify data integrity after create, update, and delete operations.',
  'Include time-based scenarios such as session expiry or rate limits.',
  'Test UI responsiveness across different screen sizes.',
  'Validate error messages are helpful and user-friendly.',
  'Check that concurrent operations don\'t produce race conditions.',
  'Include performance benchmarks for critical user paths.',
];

const _stageConfig = {
  'analyzing': {'label': 'Analyzing input', 'order': 0},
  'generating': {'label': 'Building test cases', 'order': 1},
  'validating': {'label': 'Validating results', 'order': 2},
  'polishing': {'label': 'Polishing output', 'order': 3},
};

class GenerationProgressDialog extends StatefulWidget {
  final Stream<String> stageStream;
  final VoidCallback onCancel;

  const GenerationProgressDialog({
    super.key,
    required this.stageStream,
    required this.onCancel,
  });

  @override
  State<GenerationProgressDialog> createState() => _GenerationProgressDialogState();
}

class _GenerationProgressDialogState extends State<GenerationProgressDialog> {
  String _currentStage = 'analyzing';
  Timer? _tipTimer;
  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentTipIndex = DateTime.now().millisecondsSinceEpoch % _qaTips.length;
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _qaTips.length;
      });
    });
    widget.stageStream.listen((stage) {
      if (!mounted) return;
      setState(() => _currentStage = stage);
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder = (_stageConfig[_currentStage]?['order'] as int?) ?? 0;
    final stages = _stageConfig.entries.toList()..sort((a, b) => (a.value['order'] as int).compareTo(b.value['order'] as int));

    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: min(MediaQuery.of(context).size.width * 0.85, 420.0),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accent, size: 36),
                const SizedBox(height: 20),
                const Text(
                  'Generating Test Cases',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                for (final entry in stages) ...[
                  _StageIndicator(
                    label: entry.value['label'] as String,
                    order: entry.value['order'] as int,
                    isActive: entry.key == _currentStage,
                    isCompleted: (entry.value['order'] as int) < activeOrder,
                  ),
                  if ((entry.value['order'] as int) < stages.length - 1)
                    Container(
                      width: 2,
                      height: 24,
                      margin: const EdgeInsets.only(left: 12),
                      color: (entry.value['order'] as int) < activeOrder
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.border.withValues(alpha: 0.3),
                    ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _qaTips[_currentTipIndex],
                            key: ValueKey(_currentTipIndex),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _StageIndicator extends StatelessWidget {
  final String label;
  final int order;
  final bool isActive;
  final bool isCompleted;

  const _StageIndicator({
    required this.label,
    required this.order,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Widget indicator;
    if (isCompleted) {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.black, size: 16),
      );
    } else if (isActive) {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    } else {
      indicator = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            '${order + 1}',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ),
      );
    }

    return Row(
      children: [
        indicator,
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive || isCompleted ? Colors.white : AppColors.textHint,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
