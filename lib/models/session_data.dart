class DailyIntake {
  final String dayName;
  final double grams;
  final bool isWeekend;

  DailyIntake({
    required this.dayName,
    required this.grams,
    this.isWeekend = false,
  });
}

class PatternInsight {
  final String title;
  final String description;
  final String tag;
  final String metric;

  PatternInsight({
    required this.title,
    required this.description,
    required this.tag,
    required this.metric,
  });
}

class BrandSource {
  final String name;
  final String location;
  final int stashCount;
  final String badge;
  final double rating;

  BrandSource({
    required this.name,
    required this.location,
    required this.stashCount,
    required this.badge,
    required this.rating,
  });
}
