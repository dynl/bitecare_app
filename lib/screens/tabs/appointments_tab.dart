import 'package:bitecare_app/services/vaccine_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bitecare_app/models/appointments.dart';
import 'package:bitecare_app/services/appointment_service.dart';
import 'package:bitecare_app/screens/bookappointment.dart';
import 'package:bitecare_app/screens/appointment_detail_screen.dart';
import 'package:bitecare_app/screens/appointment_history_screen.dart';
import 'package:bitecare_app/bitecare_theme.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  late Future<List<Appointment>> _appointmentsFuture;
  int _vaccineStock = 0;
  bool _loadingStock = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
    _fetchStock();
  }

  void _refreshList() {
    setState(() {
      _appointmentsFuture = _fetchAppointments();
    });
  }

  void _fetchStock() async {
    final stock = await VaccineService.getTodayVaccineStock();
    if (mounted) {
      setState(() {
        _vaccineStock = stock;
        _loadingStock = false;
      });
    }
  }

  Future<List<Appointment>> _fetchAppointments() async {
    final List<dynamic> rawAppointments =
        await AppointmentService.getAppointments();
    final all = rawAppointments
        .map((json) => Appointment.fromJson(json))
        .toList();

    // Filter: Show ONLY Upcoming/Active appointments here
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((appt) {
      bool isPast = false;
      try {
        DateTime apptDate = DateFormat('yyyy-MM-dd').parse(appt.date);
        isPast = apptDate.isBefore(today);
      } catch (e) {
        isPast = false;
      }

      bool isCancelled = appt.status?.toLowerCase() == 'cancelled';

      return !isPast && !isCancelled;
    }).toList();
  }

  void _openDetails(Appointment appt) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appt),
      ),
    );
    if (result == true) _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Vaccine Info Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: BiteCareTheme.secondaryColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Available Vaccine",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Anti-Rabies",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Today's Stock",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _loadingStock
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "$_vaccineStock Doses",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _vaccineStock > 0
                                        ? const Color(0xFF2196F3)
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- FIXED HISTORY BUTTON ---
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentHistoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text("View Completed & Failed Appointments"),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    // Use THEME Colors now
                    backgroundColor: BiteCareTheme.secondaryColor,
                    foregroundColor: BiteCareTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Upcoming List
        Expanded(
          child: FutureBuilder<List<Appointment>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No upcoming appointments."));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final appt = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      onTap: () => _openDetails(appt),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2196F3),
                        child: Icon(Icons.pets, color: Colors.white),
                      ),
                      title: Text(
                        appt.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${appt.animalType} • ${appt.date}",
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Book Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingScreen()),
                );
                _refreshList();
                _fetchStock();
              },
              icon: const Icon(Icons.add),
              label: const Text("Book New Appointment"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
