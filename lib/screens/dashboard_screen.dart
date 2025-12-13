import 'package:flutter/material.dart';
import 'package:bitecare_app/screens/tabs/appointments_tab.dart';
import 'package:bitecare_app/screens/tabs/calendar_tab.dart';
import 'package:bitecare_app/screens/tabs/profile_tab.dart';
import 'package:bitecare_app/screens/tabs/notifications_tab.dart'; // Import New Tab

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AppointmentsTab(),
    const CalendarTab(),
    const NotificationsTab(), // Index 2
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We hide the main AppBar on the Notification Tab because it has its own
      appBar: _selectedIndex == 2
          ? null
          : AppBar(
              title: Text(
                _selectedIndex == 0
                    ? "My Appointments"
                    : _selectedIndex == 1
                    ? "Availability Calendar"
                    : "My Profile",
              ),
              automaticallyImplyLeading: false,
            ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Required for 4+ items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          // --- NEW TAB ---
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifiacations',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2196F3),
        onTap: _onItemTapped,
      ),
    );
  }
}
