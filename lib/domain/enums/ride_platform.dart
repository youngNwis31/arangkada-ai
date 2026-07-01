enum RidePlatform {
  grab('Grab', '🟢', 0xFF00B14F),
  foodPanda('FoodPanda', '🩷', 0xFFD70F64),
  lalamove('Lalamove', '🟠', 0xFFF26722),
  angkas('Angkas', '🔵', 0xFF1A73E8),
  joyRide('JoyRide', '🟡', 0xFFFFB800),
  moveIt('MoveIt', '🟣', 0xFF7B2D8E),
  other('Other', '⚪', 0xFF888888);

  final String label;
  final String emoji;
  final int brandColorValue;
  const RidePlatform(this.label, this.emoji, this.brandColorValue);
}
