import 'package:flutter/material.dart';
import '../features/character.dart';
import 'progress_ring.dart';

class CharacterRow extends StatelessWidget {
  final Character c;
  const CharacterRow({super.key, required this.c});

  String _date(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "$mm/$dd/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures even spacing
      children: [
        SizedBox(
          width: 52, height: 52,
          child: Image.asset(c.imageAsset, fit: BoxFit.contain),
        ),
        Column(
          children: [
            ProgressRing(value: c.progress), // Progress ring in middle
            const SizedBox(height: 4),
            Text(
              'Level: ${c.averageLevel}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Text(
          _date(c.date),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
  }
}
