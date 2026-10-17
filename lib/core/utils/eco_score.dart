
class EcoScoreCalculator {
  static const Map<String, int> materialScores = {
    'Bamboo / wood': 90,
    'Recycled material': 95,
    'Organic natural material': 95,
    'Glass': 85,
    'Stainless steel': 85,
    'Conventional plastic': 30,
    'Recycled plastic': 70,
    'Mixed materials': 60,
  };

  static const Map<String, int> reusableScores = {
    'Yes': 100,
    'No': 0,
    'Unknown': 50,
  };

  static const Map<String, int> recyclableScores = {
    'Yes': 100,
    'Depends': 60,
    'No': 0,
    'Unknown': 50,
  };

  static const Map<String, int> packagingScores = {
    'Low': 100,
    'Medium': 60,
    'High': 20,
    'Unknown': 50,
  };

  static const Map<String, int> certificationScores = {
    'Certified organic/sustainable': 100,
    'Not certified': 50,
    'Explicitly conventional/non-organic': 0,
    'Unknown': 50,
  };

  /// Returns a 0–100 eco score, rounded.
  static int calculate({
    required String material,
    required String reusable,
    required String recyclable,
    required String packaging,
    required String certification,
  }) {
    final values = [
      materialScores[material] ?? 50,
      reusableScores[reusable] ?? 50,
      recyclableScores[recyclable] ?? 50,
      packagingScores[packaging] ?? 50,
      certificationScores[certification] ?? 50,
    ];
    final avg = values.reduce((a, b) => a + b) / values.length;
    return avg.round();
  }
}