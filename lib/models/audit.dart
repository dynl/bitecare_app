// Placeholder for Audit model.
// You can define fields here if your application includes an audit log feature.
class Audit {
  final int id;
  final String action;
  final DateTime timestamp;
  final int userId;

  Audit({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.userId,
  });

  factory Audit.fromJson(Map<String, dynamic> json) {
    return Audit(
      id: json['id'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
    };
  }
}
