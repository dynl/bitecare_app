import 'package:flutter/material.dart';
import 'package:bitecare_app/models/appointments.dart';
import 'package:bitecare_app/services/api_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isLoading = false;

  void _deleteAppointment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              setState(() => _isLoading = true);

              final success = await ApiService.deleteAppointment(widget.appointment.id!);

              if (mounted) {
                setState(() => _isLoading = false);
                if (success) {
                  Navigator.pop(context, true); // Return 'true' to indicate deletion happened
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Appointment Cancelled")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to cancel appointment")),
                  );
                }
              }
            },
            child: const Text("Confirm Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;

    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Details")),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INFO CARD
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.person, "Patient Name", appt.name),
                          const Divider(),
                          _buildDetailRow(Icons.pets, "Animal", appt.animalType),
                          const Divider(),
                          _buildDetailRow(Icons.calendar_today, "Date", appt.date),
                          const Divider(),
                          _buildDetailRow(Icons.access_time, "Time", appt.time),
                          const Divider(),
                          _buildDetailRow(Icons.info_outline, "Age", "${appt.age} years old"),
                          const Divider(),
                          _buildDetailRow(Icons.transgender, "Sex", appt.sex),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),

                  // DELETE BUTTON
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
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}