class FilterModel {
  final String installationDate;
  final String currentDate;
  final int daysInUse;
  final double hoursUsed;
  final double predictedLifeHours;
  final double healthPercentage;
  final String replacementDate;
  final int daysUntilReplacement;
  final double currentEfficiency;
  final double initialEfficiency;
  final double tds;
  final double turbidity;
  final double ph;
  final double dailyUsageHours;

  FilterModel({
    required this.installationDate,
    required this.currentDate,
    required this.daysInUse,
    required this.hoursUsed,
    required this.predictedLifeHours,
    required this.healthPercentage,
    required this.replacementDate,
    required this.daysUntilReplacement,
    required this.currentEfficiency,
    required this.initialEfficiency,
    required this.tds,
    required this.turbidity,
    required this.ph,
    required this.dailyUsageHours,
  });

  // Factory constructor to create a FilterModel from a Map
  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      installationDate: json['installationDate'] as String,
      currentDate: json['currentDate'] as String,
      daysInUse: json['daysInUse'] as int,
      hoursUsed: (json['hoursUsed'] as num).toDouble(),
      predictedLifeHours: (json['predictedLifeHours'] as num).toDouble(),
      healthPercentage: (json['healthPercentage'] as num).toDouble(),
      replacementDate: json['replacementDate'] as String,
      daysUntilReplacement: json['daysUntilReplacement'] as int,
      currentEfficiency: (json['currentEfficiency'] as num).toDouble(),
      initialEfficiency: (json['initialEfficiency'] as num).toDouble(),
      tds: (json['tds'] as num).toDouble(),
      turbidity: json['turbidity'] != null ? (json['turbidity'] as num).toDouble() : 5.0,
      ph: (json['ph'] as num).toDouble(),
      dailyUsageHours: (json['dailyUsageHours'] as num).toDouble(),
    );
  }

  // Method to convert a FilterModel to a Map
  Map<String, dynamic> toJson() {
    return {
      'installationDate': installationDate,
      'currentDate': currentDate,
      'daysInUse': daysInUse,
      'hoursUsed': hoursUsed,
      'predictedLifeHours': predictedLifeHours,
      'healthPercentage': healthPercentage,
      'replacementDate': replacementDate,
      'daysUntilReplacement': daysUntilReplacement,
      'currentEfficiency': currentEfficiency,
      'initialEfficiency': initialEfficiency,
      'tds': tds,
      'turbidity': turbidity,
      'ph': ph,
      'dailyUsageHours': dailyUsageHours,
    };
  }
}