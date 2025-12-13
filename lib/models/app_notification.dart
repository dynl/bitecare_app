class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String date;
  final bool isRead;
  final String? reason; // Nullable for older notifications

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
    // 1. Extract the 'data' object from Laravel response
    final data = json['data'] ?? {};

    return AppNotification(
      id: json['id'].toString(),

      // 2. Get Title
      title: data['title'] ?? 'Notification',

      // 3. Get Message (Check 'message' first, then 'body' from your DB screenshot)
      message: data['message'] ?? data['body'] ?? 'No details available',

      // 4. Get Type (default to 'info' if missing)
      type: data['type'] ?? 'info',

      // 5. Get Date & Read Status
      date: json['created_at'] ?? '',
      isRead: json['read_at'] != null,

      // 6. Get Reason (if it exists)
      reason: data['reason'],
    );
  }
}
