import 'package:flutter/material.dart';
import 'package:carebridge/core/app_theme.dart';

class CaretakerRatingDialog extends StatefulWidget {
  final String caretakerName;

  const CaretakerRatingDialog({super.key, required this.caretakerName});

  @override
  State<CaretakerRatingDialog> createState() => _CaretakerRatingDialogState();
}

class _CaretakerRatingDialogState extends State<CaretakerRatingDialog> {
  double _rating = 5.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        children: [
          const Icon(Icons.stars_rounded, color: AppTheme.verifyGold, size: 48),
          const SizedBox(height: 16),
          Text(
            'Rate ${widget.caretakerName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How was your pet\'s experience with this caretaker?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final double starValue = index + 1.0;
              return IconButton(
                icon: Icon(
                  starValue <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppTheme.verifyGold,
                  size: 36,
                ),
                onPressed: () {
                  setState(() => _rating = starValue);
                  debugPrint("⭐️ ARCHITECT: User selected $starValue stars");
                },
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Maybe Later',
              style: TextStyle(color: Colors.black45)),
        ),
        ElevatedButton(
          onPressed: () {
            debugPrint(
                "🚀 ARCHITECT: Submitting rating of $_rating to home screen...");
            // Use rootNavigator: true to ensure we pop the dialog specifically
            Navigator.of(context, rootNavigator: true).pop(_rating);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.safetyTeal,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Submit Review',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
