class Character {
  final String name;
  final String imageAsset; // e.g., 'assets/images/heart.png'
  final double progress;   // 0.0..1.0
  final DateTime date;
  final int averageLevel;  // Average feeling level (0-10)

  const Character({
    required this.name,
    required this.imageAsset,
    required this.progress,
    required this.date,
    this.averageLevel = 0,
  });
}
