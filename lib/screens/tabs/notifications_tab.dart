import 'package:flutter/material.dart';
import 'package:bitecare_app/models/app_notification.dart';
import 'package:bitecare_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _notificationsFuture = NotificationService.getNotifications();
    });
  }

  // --- Helper: Get Color based on Type ---
  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  // --- Helper: Get Icon based on Type ---
  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'danger':
        return Icons.cancel_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = list[index];
                final color = _getIconColor(notif.type);
                final icon = _getIcon(notif.type);

                return Card(
                  elevation: 0,
                  // Read = Grey Background, Unread = White
                  color: notif.isRead ? Colors.grey.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ICON ---
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color),
                        ),
                        const SizedBox(width: 12),

                        // --- CONTENT ---
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: notif.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                  color: notif.isRead
                                      ? Colors.grey.shade700
                                      : Colors.black,
                                ),
                              ),

                              // --- DISPLAY REASON (If Available) ---
                              if (notif.reason != null)
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: color.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    "Reason: ${notif.reason}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 4),

                              // Body / Message
                              Text(
                                notif.message,
                                style: TextStyle(color: Colors.grey.shade800),
                              ),

                              const SizedBox(height: 8),

                              // Date
                              Text(
                                _formatDate(notif.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
