class ForecastData {
  final Map<String, dynamic> meta;
  final List<HourlyForecast> scores;

  ForecastData({
    required this.meta,
    required this.scores,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      meta: json['meta'] as Map<String, dynamic>,
      scores: (json['scores'] as List)
          .map((item) => HourlyForecast.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HourlyForecast {
  final String date;
  final Map<String, SportForecast> sports;

  HourlyForecast({
    required this.date,
    required this.sports,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final sportsMap = (json['sports'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(
              key,
              SportForecast.fromJson(value as Map<String, dynamic>),
            ));
    return HourlyForecast(
      date: json['date'] as String,
      sports: sportsMap,
    );
  }
}

class Tip {
  final String id;
  final String severity; // 'info', 'warn'
  final String icon; // 'wetsuit', 'sun', 'warning', etc.
  final String text;

  Tip({
    required this.id,
    required this.severity,
    required this.icon,
    required this.text,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    // Handle both string and dynamic types for safety
    return Tip(
      id: json['id']?.toString() ?? 'unknown',
      severity: (json['severity'] as String?) ?? 'info',
      icon: (json['icon'] as String?) ?? 'info',
      text: json['text']?.toString() ?? '',
    );
  }
}

class SportForecast {
  final String sport;
  final String date;
  final String label;
  final double score;
  final Map<String, dynamic> context;
  final List<String> flags;
  final List<String> reasons;
  final List<Tip> tips;
  final Map<String, List<String>> conditionLabels;

  SportForecast({
    required this.sport,
    required this.date,
    required this.label,
    required this.score,
    required this.context,
    required this.flags,
    required this.reasons,
    this.tips = const [],
    this.conditionLabels = const {},
  });

  factory SportForecast.fromJson(Map<String, dynamic> json) {
    // Parse condition_labels if present
    Map<String, List<String>> conditionLabels = {};
    if (json['condition_labels'] != null) {
      final labelsMap = json['condition_labels'] as Map<String, dynamic>;
      conditionLabels = {
        'green': (labelsMap['green'] as List?)?.map((e) => e as String).toList() ?? [],
        'yellow': (labelsMap['yellow'] as List?)?.map((e) => e as String).toList() ?? [],
        'red': (labelsMap['red'] as List?)?.map((e) => e as String).toList() ?? [],
      };
    }
    
    return SportForecast(
      sport: json['sport'] as String,
      date: json['date'] as String,
      label: json['label'] as String,
      score: (json['score'] as num).toDouble(),
      context: json['context'] as Map<String, dynamic>,
      flags: (json['flags'] as List?)?.map((e) => e as String).toList() ?? [],
      reasons: (json['reasons'] as List).map((e) => e as String).toList(),
      tips: (json['tips'] as List?)?.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      conditionLabels: conditionLabels,
    );
  }

  String get sportDisplayName {
    switch (sport) {
      case 'surfing':
        return 'Surfing';
      case 'sup':
        return 'SUP';
      case 'sup_surf':
        return 'SUP Surf';
      case 'windsurfing':
        return 'Windsurfing';
      case 'kitesurfing':
        return 'Kitesurfing';
      default:
        return sport;
    }
  }
}
