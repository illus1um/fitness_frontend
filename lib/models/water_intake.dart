class WaterIntakeRecord {
  final double amount;
  final DateTime timestamp;
  final int? id;
  
  WaterIntakeRecord({
    required this.amount, 
    required this.timestamp, 
    this.id
  });
  
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    if (id != null) 'id': id,
  };
  
  factory WaterIntakeRecord.fromJson(Map<String, dynamic> json) {
    return WaterIntakeRecord(
      id: json['id'],
      amount: json['amount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class DailyWaterIntake {
  final String date;
  final double totalAmount;
  final List<WaterIntakeRecord> records;
  
  DailyWaterIntake({
    required this.date,
    required this.totalAmount,
    required this.records,
  });
  
  factory DailyWaterIntake.fromJson(Map<String, dynamic> json) {
    return DailyWaterIntake(
      date: json['date'],
      totalAmount: json['total_amount'].toDouble(),
      records: (json['records'] as List)
          .map((item) => WaterIntakeRecord.fromJson(item))
          .toList(),
    );
  }
}

class WaterIntakeHistory {
  final String date;
  final double amount;
  
  WaterIntakeHistory({
    required this.date,
    required this.amount,
  });
  
  factory WaterIntakeHistory.fromJson(Map<String, dynamic> json) {
    return WaterIntakeHistory(
      date: json['date'],
      amount: json['amount'].toDouble(),
    );
  }
} 