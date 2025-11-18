import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bitecare_app/services/api_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _animalController = TextEditingController();

  String _selectedSex = 'Male';
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  // Master list of time slots (Lunch Break Removed)
  final List<String> _timeSlots = [
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
  ];

  // --- NEW: LOGIC TO FILTER PAST TIMES ---
  List<String> _getAvailableSlots() {
    // If no date is selected, we can show all (or none).
    // Showing all allows user to see what's typically offered.
    if (_selectedDate == null) return _timeSlots;

    final now = DateTime.now();

    // Check if the selected date is TODAY
    bool isToday =
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    if (!isToday) {
      // If it's a future date, ALL slots are available
      return _timeSlots;
    }

    // If it IS today, filter out passed times
    return _timeSlots.where((slot) {
      try {
        // Parse "08:00 AM"
        final format = DateFormat("hh:mm a");
        final time = format.parse(slot);

        // Create a DateTime object for TODAY at this SLOT's time
        final slotDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // Only keep slots that are in the future
        return slotDateTime.isAfter(now);
      } catch (e) {
        return true; // Fallback
      }
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Prevents past dates
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // IMPORTANT: Reset time when date changes to ensure validity
        _selectedTimeSlot = null;
      });
    }
  }

  void _submitBooking() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTimeSlot != null) {
      setState(() => _isLoading = true);

      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);

      final Map<String, dynamic> bookingData = {
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'sex': _selectedSex,
        'animal_type': _animalController.text,
        'date': formattedDate,
        'time': _selectedTimeSlot,
      };

      // Call API
      final response = await ApiService.bookAppointment(bookingData);

      if (mounted) {
        setState(() => _isLoading = false);

        if (response['success'] == true) {
          // Success Case
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Appointment Booked!')));
          Navigator.pop(context);
        } else {
          // Failure Case - Show POPUP
          _showErrorDialog(response['message'] ?? 'Booking Failed');
        }
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a Date')));
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Booking Unavailable",
          style: TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate available slots dynamically
    final availableSlots = _getAvailableSlots();

    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Patient Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: const InputDecoration(
                  labelText: "Sex",
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female']
                    .map(
                      (sex) => DropdownMenuItem(value: sex, child: Text(sex)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedSex = v!),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _animalController,
                decoration: const InputDecoration(
                  labelText: "Animal Type (e.g. Dog, Cat)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Select Date",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? "Choose Date"
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // --- UPDATED DROPDOWN ---
              DropdownButtonFormField<String>(
                value: _selectedTimeSlot,
                decoration: const InputDecoration(
                  labelText: "Select Time",
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                // Use dynamic availableSlots list
                items: availableSlots.map((time) {
                  return DropdownMenuItem(value: time, child: Text(time));
                }).toList(),
                onChanged: (v) => setState(() => _selectedTimeSlot = v),
                validator: (v) => v == null ? 'Please select a time' : null,
                // Helper text if date isn't selected yet
                hint: _selectedDate == null
                    ? const Text("Select Date first")
                    : null,
              ),

              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Confirm Booking"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
