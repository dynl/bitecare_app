class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String date;
  final bool isRead;
  final String? reason;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    required this.isRead,
    this.reason,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return AppNotification(
      id: json['id'].toString(),
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? data['body'] ?? 'No details available',
      type: data['type'] ?? 'info',
      date: json['created_at'] ?? '',
      isRead: json['read_at'] != null,
      reason: data['reason'],
    );
  }
}
