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
  return Container(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Colors.brown.shade300,
          width: 1,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character name
          Expanded(
            flex: 3,
            child: Center(child: _CharacterLabel(name: c.name)),
          ),
          // Level indicator
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProgressRing(value: c.progress),
                const SizedBox(height: 4),
                Text(
                  'Level: ${c.averageLevel}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpecialElite',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              _date(c.date),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'SpecialElite',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _CharacterLabel extends StatelessWidget {
  final String name;
  const _CharacterLabel({required this.name});

  @override
  Widget build(BuildContext context) {
    final badgeColor = Colors.brown.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor, width: 2),
        boxShadow: [
          BoxShadow(
            offset: const Offset(2, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      ),
      child: Text(
        name.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'SpecialElite',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}
