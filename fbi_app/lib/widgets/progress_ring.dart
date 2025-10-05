import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double value;      // 0.0..1.0
  final double size;       // diameter
  final double stroke;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 36,
    this.stroke = 4,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: v,
            strokeWidth: stroke,
          ),
          Container(
            height: size - stroke * 2,
            width: size - stroke * 2,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                  color: Colors.black.withOpacity(0.06),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
