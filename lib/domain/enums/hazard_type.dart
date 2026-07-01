enum HazardType {
  pothole('Pothole', 'LUBAK'),
  flooding('Flooding', 'BAHA'),
  floodAnkle('Ankle-Deep Flood', 'BAHA BABAW'),
  floodKnee('Knee-Deep Flood', 'BAHA TUHOD'),
  floodImpassable('Impassable Flood', 'BAHA LUBOG'),
  checkpoint('Checkpoint', 'CHECKPOINT'),
  accident('Accident', 'AKSIDENTE'),
  roadClosure('Road Closure', 'SARADO'),
  construction('Construction', 'GAWA');

  final String english;
  final String tagalog;
  const HazardType(this.english, this.tagalog);

  bool get isFlood =>
      this == flooding ||
      this == floodAnkle ||
      this == floodKnee ||
      this == floodImpassable;

  bool get isSevere =>
      this == roadClosure ||
      this == floodImpassable ||
      this == accident;

  int get floodSeverity => switch (this) {
        floodAnkle => 1,
        flooding => 2,
        floodKnee => 2,
        floodImpassable => 3,
        _ => 0,
      };
}
