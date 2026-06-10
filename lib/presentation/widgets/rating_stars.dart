// lib/presentation/widgets/rating_stars.dart
import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  const RatingStars({super.key, required this.rating, this.count = 0, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: const Color(0xFFF4C430)),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: size - 2, fontWeight: FontWeight.w600)),
        if (count > 0) ...[
          const SizedBox(width: 2),
          Text('($count)', style: TextStyle(fontSize: size - 4, color: Colors.black54)),
        ],
      ],
    );
  }
}

/// Interactive 1-5 star selector.
class RatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const RatingInput({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(filled ? Icons.star : Icons.star_border,
              size: 40, color: const Color(0xFFF4C430)),
        );
      }),
    );
  }
}
