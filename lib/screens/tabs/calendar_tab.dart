import 'package:bitecare_app/services/appointment_service.dart';
import 'package:bitecare_app/services/vaccine_service.dart';
import 'package:bitecare_app/services/holiday_service.dart'; // Ensure this import exists
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:bitecare_app/bitecare_theme.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  Map<String, int> _availabilityMap = {}; // Appointments booked per day
  Map<String, int> _vaccineStockMap = {}; // Remaining stock per day
  Map<String, String> _holidayMap = {}; // Map of Holidays

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
    // Fetch booked appointments, stocks, AND holidays
    final availability = await AppointmentService.getAvailability();
    final stocks = await VaccineService.getVaccineStockMap();
    final holidayMap = await HolidayService.getHolidaysMap();

    if (mounted) {
      setState(() {
        _availabilityMap = availability;
        _vaccineStockMap = stocks;
        _holidayMap = holidayMap;
        _isLoading = false;
      });
    }
  }

  // --- HELPER: GET REMAINING STOCK FOR A DAY ---
  int _getCapacity(DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    // This returns the 'quantity' directly from the DB (e.g., 13)
    return _vaccineStockMap[dateKey] ?? 0;
  }

  // --- HELPER: GET BOOKED COUNT FOR A DAY ---
  int _getBookedCount(DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    return _availabilityMap[dateKey] ?? 0;
  }

  // --- HELPER: GET HOLIDAY NAME ---
  String? _getHolidayName(DateTime day) {
    return _holidayMap[DateFormat('yyyy-MM-dd').format(day)];
  }

  // --- HELPER: DETERMINE DOT COLOR ---
  Color _getColorForDay(DateTime day) {
    // 1. Check Holiday FIRST (Green)
    if (_holidayMap.containsKey(DateFormat('yyyy-MM-dd').format(day))) {
      return Colors.green;
    }

    final now = DateTime.now();
    final isPastDay = day.isBefore(DateTime(now.year, now.month, now.day));

    if (isPastDay) return Colors.grey.shade400; // Past

    // Current Remaining Stock
    int remainingStock = _getCapacity(day);

    // If stock is 0, it's either fully booked OR no stock was added.
    if (remainingStock == 0) {
      if (_getBookedCount(day) > 0) {
        return Colors.red.shade400; // Full
      }
      return Colors.grey.shade300; // No stock set
    }

    // Logic for "Half Full" / Low Stock
    if (remainingStock <= 5) {
      return Colors.orange.shade300; // Running Low
    } else {
      return const Color(0xFF2196F3); // Available
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the stock directly from the map (e.g., 13)
    int selectedCapacity = _selectedDay != null
        ? _getCapacity(_selectedDay!)
        : 0;

    // 2. FIXED: We do NOT subtract bookings anymore.
    // The DB 'quantity' IS the available slots.
    int availableSlots = selectedCapacity;

    String? holidayName = _selectedDay != null
        ? _getHolidayName(_selectedDay!)
        : null;
    bool isSelectedHoliday = holidayName != null;

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
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 15,
            children: [
              _buildLegendItem("Available", const Color(0xFF2196F3)),
              _buildLegendItem("Holiday", Colors.green),
              _buildLegendItem("Low Stock", Colors.orange.shade300),
              _buildLegendItem("Full/No Stock", Colors.red.shade400),
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
              color: BiteCareTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BiteCareTheme.primaryLightColor),
            ),
            child: Row(
              children: [
                Icon(
                  isSelectedHoliday
                      ? Icons.celebration
                      : availableSlots > 0
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: isSelectedHoliday
                      ? Colors.green
                      : (availableSlots > 0
                            ? const Color(0xFF2196F3)
                            : Colors.grey),
                  size: 30,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDay!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isLoading
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isSelectedHoliday
                                ? "Clinic Closed ($holidayName)"
                                : _selectedDay!.isBefore(
                                    DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                    ),
                                  )
                                ? "Date has passed"
                                : availableSlots == 0
                                ? "Fully Booked / No Stock"
                                : "$availableSlots Available Slots",
                            style: TextStyle(
                              color: isSelectedHoliday
                                  ? Colors.green.shade700
                                  : (availableSlots > 0
                                        ? const Color(0xFF2196F3)
                                        : Colors.red.shade800),
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
      mainAxisSize: MainAxisSize.min,
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
