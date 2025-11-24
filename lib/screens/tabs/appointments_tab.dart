import 'package:flutter/material.dart';
import 'package:bitecare_app/models/appointments.dart';
import 'package:bitecare_app/services/api_service.dart';
import 'package:bitecare_app/screens/bookappointment.dart';
import 'package:bitecare_app/screens/appointment_detail_screen.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  late Future<List<Appointment>> _appointmentsFuture;

  // --- NEW VARIABLES FOR STOCK ---
  int _vaccineStock = 0;
  bool _loadingStock = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
    _fetchStock(); // Load stock on start
  }

  void _refreshList() {
    setState(() {
      _appointmentsFuture = _fetchAppointments();
    });
  }

  // --- NEW METHOD TO FETCH STOCK ---
  void _fetchStock() async {
    final stock = await ApiService.getTodayVaccineStock();
    if (mounted) {
      setState(() {
        _vaccineStock = stock;
        _loadingStock = false;
      });
    }
  }

  Future<List<Appointment>> _fetchAppointments() async {
    final List<dynamic> rawAppointments = await ApiService.getAppointments();
    return rawAppointments.map((json) => Appointment.fromJson(json)).toList();
  }

  // Navigate to details and refresh if deleted or edited
  void _openDetails(Appointment appt) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appt),
      ),
    );

    if (result == true) {
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Vaccine Info Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.teal.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Available Vaccine",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Anti-Rabies (Verorab)",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
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
                      // --- DYNAMIC DISPLAY ---
                      _loadingStock
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              "$_vaccineStock Doses",
                              style: TextStyle(
                                fontSize: 20,
                                color: _vaccineStock > 0
                                    ? Colors.teal.shade700
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
        ),

        // Appointments List
        Expanded(
          child: FutureBuilder<List<Appointment>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No appointments found."));
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
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.pets, color: Colors.white),
                      ),
                      title: Text(
                        appt.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${appt.animalType} • ${appt.date} @ ${appt.time}",
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
                _fetchStock(); // Refresh stock after potential booking
              },
              icon: const Icon(Icons.add),
              label: const Text("Book New Appointment"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
