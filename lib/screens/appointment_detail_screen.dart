import 'package:bitecare_app/services/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:bitecare_app/models/appointments.dart';
import 'package:bitecare_app/screens/edit_appointment_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isLoading = false;

  // --- HELPER: GET STATUS COLOR ---
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _deleteAppointment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text(
          "Are you sure you want to cancel this appointment? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              final success = await AppointmentService.deleteAppointment(
                widget.appointment.id!,
              );

              if (mounted) {
                setState(() => _isLoading = false);
                if (success) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Appointment Cancelled")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to cancel appointment"),
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Confirm Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _editAppointment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditAppointmentScreen(appointment: widget.appointment),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment updated successfully")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    final statusColor = _getStatusColor(appt.status);

    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Details")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STATUS BADGE ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "STATUS: ${appt.status?.toUpperCase() ?? 'PENDING'}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- DETAILS CARD ---
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.person,
                            "Patient Name",
                            appt.name,
                          ),
                          const Divider(),

                          // --- NEW FIELD: GUARDIAN ---
                          _buildDetailRow(
                            Icons.person_outline,
                            "Guardian",
                            appt.guardian ?? 'N/A',
                          ),
                          const Divider(),

                          // --- NEW FIELD: PHONE ---
                          _buildDetailRow(
                            Icons.phone,
                            "Contact Number",
                            appt.phoneNumber ?? 'N/A',
                          ),
                          const Divider(),

                          _buildDetailRow(
                            Icons.pets,
                            "Animal",
                            appt.animalType,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            Icons.calendar_today,
                            "Date",
                            appt.date,
                          ),
                          const Divider(),
                          _buildDetailRow(Icons.access_time, "Time", appt.time),
                          const Divider(),

                          // --- NEW FIELD: PURPOSE ---
                          _buildDetailRow(
                            Icons.vaccines,
                            "Purpose",
                            appt.purpose ?? 'N/A',
                          ),
                          const Divider(),

                          _buildDetailRow(
                            Icons.info_outline,
                            "Age",
                            "${appt.age} years old",
                          ),
                          const Divider(),
                          _buildDetailRow(Icons.transgender, "Sex", appt.sex),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- EDIT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _editAppointment,
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Appointment"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- DELETE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _deleteAppointment,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Cancel Appointment"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 28), // Blue color
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
