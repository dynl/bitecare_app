import 'package:bitecare_app/services/vaccine_service.dart';
import 'package:bitecare_app/services/holiday_service.dart';
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
  String? _todayHolidayName;

  @override
  void initState() {
    super.initState();
    _refreshList();
    _fetchData();
  }

  void _refreshList() {
    setState(() {
      _appointmentsFuture = _fetchAppointments();
    });
  }

  void _fetchData() async {
    final stock = await VaccineService.getTodayVaccineStock();
    final holidayName = await HolidayService.getTodayHolidayName();

    if (mounted) {
      setState(() {
        _vaccineStock = stock;
        _todayHolidayName = holidayName;
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

    // Filter: Show ONLY Upcoming/Active appointments
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

      final status = appt.status?.toLowerCase() ?? '';
      bool isCancelled = status == 'cancelled';
      bool isCompleted = status == 'completed';

      // Keep only Active (Pending/Confirmed) & Future appointments
      return !isPast && !isCancelled && !isCompleted;
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHoliday = _todayHolidayName != null;

    return Column(
      children: [
        // --- TOP INFO CARD (Stock or Holiday) ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: isHoliday
                    ? Colors.green.shade50
                    : BiteCareTheme.secondaryColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isHoliday
                      ? const BorderSide(color: Colors.green)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isHoliday
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.celebration,
                              color: Colors.green,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            // --- OVERFLOW FIX: Wrapped in Expanded ---
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Clinic Closed",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    "Today is $_todayHolidayName",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
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

              // --- HISTORY BUTTON ---
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

        // --- SPLIT LIST (APPROVED vs PENDING) ---
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

              final allAppointments = snapshot.data!;

              // 1. Separate the lists
              final approvedList = allAppointments.where((appt) {
                final s = appt.status?.toLowerCase() ?? '';
                return s == 'confirmed' || s == 'approved';
              }).toList();

              final pendingList = allAppointments.where((appt) {
                final s = appt.status?.toLowerCase() ?? '';
                return s == 'pending';
              }).toList();

              // 2. Build the Scrollable View
              return ListView(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                children: [
                  // --- APPROVED SECTION ---
                  if (approvedList.isNotEmpty) ...[
                    _buildSectionHeader("Approved Appointments"),
                    ...approvedList.map((appt) => _buildAppointmentCard(appt)),
                    const SizedBox(height: 20),
                  ],

                  // --- PENDING SECTION ---
                  if (pendingList.isNotEmpty) ...[
                    _buildSectionHeader("Pending Requests"),
                    ...pendingList.map((appt) => _buildAppointmentCard(appt)),
                  ],

                  // Fallback if filtering messed up
                  if (approvedList.isEmpty && pendingList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                        child: Text("No active appointments found."),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // --- BOOK BUTTON ---
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
                _fetchData();
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

  // --- HELPER: SECTION HEADER ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // --- HELPER: APPOINTMENT CARD ---
  Widget _buildAppointmentCard(Appointment appt) {
    final statusColor = _getStatusColor(appt.status);
    final statusText = appt.status ?? 'Pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => _openDetails(appt),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.pets, color: statusColor),
        ),
        title: Text(
          appt.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("${appt.animalType} • ${appt.date}"),
            const SizedBox(height: 6),
            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }
}
