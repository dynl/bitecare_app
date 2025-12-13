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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();

  String _selectedSex = 'Male';
  String _selectedPurpose = '1st Dose';

  DateTime? _selectedDate;
  bool _isLoading = false;

  Map<String, dynamic>? _recommendation;
  Map<String, int> _stockMap = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _animalController.dispose();
    _phoneController.dispose();
    _guardianController.dispose();
    super.dispose();
  }

  void _fetchData() async {
    final stocks = await VaccineService.getVaccineStockMap();

    Map<String, dynamic>? bestDay;

    final backendRec = await RecommendationService.getBestDayRecommendation();

    if (mounted) {
      setState(() {
        _stockMap = stocks;
      });

      String? bestDateKey;
      int maxStock = -1;

      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      stocks.forEach((dateKey, qty) {
        if (dateKey.compareTo(todayStr) >= 0 && qty > 0) {
          if (qty > maxStock) {
            maxStock = qty;
            bestDateKey = dateKey;
          }
        }
      });

      if (bestDateKey != null && maxStock > 0) {
        DateTime dateObj = DateTime.parse(bestDateKey!);
        String readable = DateFormat('MMMM d, yyyy (EEEE)').format(dateObj);

        bestDay = {
          'date': bestDateKey,
          'readable_date': readable,
          'slots_left': maxStock,
          'traffic_level': maxStock > 10 ? 'Low' : 'Moderate',
        };
      } else {
        bestDay = backendRec;
      }

      setState(() {
        _recommendation = bestDay;
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
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          return false;
        }
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
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);
      int dailyStock = _stockMap[formattedDate] ?? 0;

      if (dailyStock <= 0) {
        _showErrorDialog(
          "No vaccine stock available for ${DateFormat('MMM d').format(_selectedDate!)}. Please choose another date.",
        );
        return;
      }

      setState(() => _isLoading = true);

      final Map<String, dynamic> bookingData = {
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'sex': _selectedSex,
        'animal_type': _animalController.text,
        'date': formattedDate,
        'time': 'Walk-In / Day',
        'phone_number': _phoneController.text,
        'guardian': _guardianController.text,
        'purpose': _selectedPurpose,
      };

      final response = await AppointmentService.bookAppointment(bookingData);

      if (mounted) {
        setState(() => _isLoading = false);

        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Appointment Booked!'),
            ),
          );
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
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF2196F3),
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
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Best Availability (${_recommendation!['slots_left']} doses left):",
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
                              "${_recommendation!['traffic_level']} Traffic",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2196F3),
                          size: 32,
                        ),
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
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _guardianController,
                decoration: const InputDecoration(
                  labelText: "Guardian Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedPurpose,
                decoration: const InputDecoration(
                  labelText: "Purpose",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vaccines),
                ),
                items: ['1st Dose', '2nd Dose']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPurpose = v!),
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

              // Date Picker
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
                        backgroundColor: const Color(0xFF2196F3),
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
