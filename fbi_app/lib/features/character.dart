class Character {
  final String name;
  final String imageAsset; // e.g., 'assets/images/heart.png'
  final double progress;   // 0.0..1.0
  final DateTime date;

  const Character({
    required this.name,
    required this.imageAsset,
    required this.progress,
    required this.date,
  });
}
