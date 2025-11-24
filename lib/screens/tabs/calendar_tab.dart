import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:bitecare_app/services/api_service.dart';
import 'package:intl/intl.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  Map<String, int> _availabilityMap = {}; // Appointments booked per day
  Map<String, int> _vaccineStockMap = {}; // Total capacity per day
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  void _loadData() async {
    // Fetch both booked appointments and daily limits (vaccine stock)
    final availability = await ApiService.getAvailability();
    final stocks = await ApiService.getVaccineStockMap();

    if (mounted) {
      setState(() {
        _availabilityMap = availability;
        _vaccineStockMap = stocks;
        _isLoading = false;
      });
    }
  }

  // --- HELPER: GET TOTAL CAPACITY FOR A DAY ---
  int _getCapacity(DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);

    // FIX: Default is now 0. If doctor didn't set stock, it's 0.
    return _vaccineStockMap[dateKey] ?? 0;
  }

  // --- HELPER: GET BOOKED COUNT FOR A DAY ---
  int _getBookedCount(DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    return _availabilityMap[dateKey] ?? 0;
  }

  // --- HELPER: DETERMINE DOT COLOR ---
  Color _getColorForDay(DateTime day) {
    final now = DateTime.now();
    final isPastDay = day.isBefore(DateTime(now.year, now.month, now.day));

    if (isPastDay) return Colors.grey.shade400; // Past

    int booked = _getBookedCount(day);
    int capacity = _getCapacity(day);

    // If capacity is 0 (No stock set), mark as unavailable (Red/Grey)
    if (capacity == 0) {
      return Colors.grey.shade300; // No stock = Grey out
    }

    if (booked >= capacity) {
      return Colors.red.shade400; // Full
    } else if (booked >= (capacity / 2)) {
      return Colors.orange.shade300; // Half Full
    } else {
      return Colors.green.shade400; // Available
    }
  }

  @override
  Widget build(BuildContext context) {
    // CALCULATE DATA FOR THE BOTTOM BOX
    int selectedCapacity = _selectedDay != null
        ? _getCapacity(_selectedDay!)
        : 0;
    int selectedBooked = _selectedDay != null
        ? _getBookedCount(_selectedDay!)
        : 0;

    // LOGIC CHANGE: Calculate Available Slots
    int availableSlots = selectedCapacity - selectedBooked;
    if (availableSlots < 0) availableSlots = 0;

    return Column(
      children: [
        // --- CALENDAR ---
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) => _buildDay(day, false),
            selectedBuilder: (context, day, focusedDay) => _buildDay(day, true),
            todayBuilder: (context, day, focusedDay) =>
                _buildDay(day, false, isToday: true),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 10),

        // --- LEGEND ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem("Available", Colors.green.shade400),
              _buildLegendItem("Half Full", Colors.orange.shade300),
              _buildLegendItem("Full", Colors.red.shade400),
              _buildLegendItem("Past", Colors.grey.shade400),
            ],
          ),
        ),
        const Divider(height: 30),

        // --- SELECTED DAY DETAILS BOX ---
        if (_selectedDay != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              children: [
                // Dynamic Icon
                Icon(
                  availableSlots > 0
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: availableSlots > 0 ? Colors.teal : Colors.grey,
                  size: 30,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. SHOW THE DAY
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDay!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 2. SHOW AVAILABLE SLOTS
                    _isLoading
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _selectedDay!.isBefore(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                  ),
                                )
                                ? "Date has passed"
                                : selectedCapacity == 0
                                ? "No Vaccine Stock Set" // <--- SPECIFIC MESSAGE FOR 0 CAPACITY
                                : availableSlots == 0
                                ? "Fully Booked"
                                : "$availableSlots Available Slots",
                            style: TextStyle(
                              color: availableSlots > 0
                                  ? Colors.teal.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDay(DateTime day, bool isSelected, {bool isToday = false}) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _getColorForDay(day),
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        boxShadow: isToday
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        day.day.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
