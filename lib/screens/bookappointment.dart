import 'package:bitecare_app/services/appointment_service.dart';
import 'package:bitecare_app/services/recommendation_service.dart';
import 'package:bitecare_app/services/vaccine_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bitecare_app/bitecare_theme.dart';

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
  bool _isLoading = false;

  // Store recommendation data
  Map<String, dynamic>? _recommendation;

  // --- NEW: Store Stock Data to validate availability ---
  Map<String, int> _stockMap = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    // 1. Get Recommendation
    final rec = await RecommendationService.getBestDayRecommendation();
    // 2. Get Stock Map to check for 0 stock days
    final stocks = await VaccineService.getVaccineStockMap();

    if (mounted) {
      setState(() {
        if (rec != null) _recommendation = rec;
        _stockMap = stocks;
      });
    }
  }

  DateTime _getInitialDate() {
    DateTime date = DateTime.now();
    if (date.hour >= 17) {
      date = date.add(const Duration(days: 1));
    }
    while (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  Future<void> _pickDate() async {
    final initialDate = _getInitialDate();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      selectableDayPredicate: (DateTime day) {
        // Disable Weekends
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          return false;
        }
        // Disable "Today" if past 5 PM
        final now = DateTime.now();
        bool isToday =
            day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        if (isToday && now.hour >= 17) return false;

        return true;
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitBooking() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      // --- NEW: CHECK IF STOCK IS AVAILABLE ---
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);

      // Get stock for this day (Default to 0 if not found)
      int dailyStock = _stockMap[formattedDate] ?? 0;

      if (dailyStock <= 0) {
        // BLOCK THE BOOKING
        _showErrorDialog(
          "No vaccine stock available for ${DateFormat('MMM d').format(_selectedDate!)}. Please choose another date.",
        );
        return;
      }
      // ----------------------------------------

      setState(() => _isLoading = true);

      final Map<String, dynamic> bookingData = {
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'sex': _selectedSex,
        'animal_type': _animalController.text,
        'date': formattedDate,
        'time': 'Walk-In / Day',
      };

      final response = await AppointmentService.bookAppointment(bookingData);

      if (mounted) {
        setState(() => _isLoading = false);

        if (response['success'] == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Appointment Booked!')));
          Navigator.pop(context);
        } else {
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
    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- SMART SUGGESTION CARD ---
              if (_recommendation != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [BiteCareTheme.secondaryColor, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BiteCareTheme.primaryLightColor),
                    boxShadow: [
                      BoxShadow(
                        color: BiteCareTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF2196F3), // Blue color
                        size: 30,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Smart Suggestion",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3), // Blue color
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Avoid waiting! Best day to visit:",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _recommendation!['readable_date'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${_recommendation!['slots_left']} slots open • ${_recommendation!['traffic_level']} Traffic",
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF2196F3), // Blue color
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2196F3), // Blue color
                          size: 32,
                        ),
                        tooltip: "Select this date",
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.parse(
                              _recommendation!['date'],
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Date set to ${_recommendation!['readable_date']}",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              // --- END RECOMMENDATION CARD ---
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

              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF2196F3), // Blue color
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
