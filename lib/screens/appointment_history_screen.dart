import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bitecare_app/models/appointments.dart';
import 'package:bitecare_app/services/appointment_service.dart';
import 'package:bitecare_app/screens/appointment_detail_screen.dart';
import 'package:bitecare_app/bitecare_theme.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  late Future<List<Appointment>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<Appointment>> _fetchHistory() async {
    final List<dynamic> rawAppointments =
        await AppointmentService.getAppointments();
    final allAppointments = rawAppointments
        .map((json) => Appointment.fromJson(json))
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allAppointments.where((appt) {
      bool isPast = false;
      try {
        DateTime apptDate = DateFormat('yyyy-MM-dd').parse(appt.date);
        isPast = apptDate.isBefore(today);
      } catch (e) {
        isPast = false;
      }

      final status = appt.status?.toLowerCase() ?? '';
      bool isCancelled = status == 'cancelled';
      bool isCompleted = status == 'completed'; // <--- NEW CHECK

      // Include in history if: Past OR Cancelled OR Completed
      return isPast || isCancelled || isCompleted;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment History"),
        backgroundColor: Colors.white,
        foregroundColor: BiteCareTheme.textDark,
        elevation: 0,
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No history found",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final historyList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final appt = historyList[index];
              final status = appt.status?.toLowerCase() ?? '';
              final bool isCancelled = status == 'cancelled';

              return Card(
                color: Colors.grey.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AppointmentDetailScreen(appointment: appt),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: isCancelled
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      isCancelled ? Icons.close : Icons.check,
                      color: isCancelled ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    appt.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  subtitle: Text("${appt.animalType} • ${appt.date}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCancelled
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      isCancelled ? "Failed" : "Completed",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCancelled ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
