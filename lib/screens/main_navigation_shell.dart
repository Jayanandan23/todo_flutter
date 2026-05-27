import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'home_screen.dart';
import 'task_status_screen.dart';
import 'calendar_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  TaskStatus? _activeStatusFilter;

  void _navigateToTab(int index, TaskStatus? statusFilter) {
    setState(() {
      _currentIndex = index;
      _activeStatusFilter = statusFilter;
    });
    
    // Notify provider of status filter if switching to Status Tab
    final provider = Provider.of<TaskProvider>(context, listen: false);
    if (index == 1) {
      provider.setFilterStatus(statusFilter);
    } else {
      provider.clearFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pages list
    final List<Widget> pages = [
      HomeScreen(onNavigateToTab: _navigateToTab),
      TaskStatusScreen(initialStatus: _activeStatusFilter),
      const CalendarScreen(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C1B),
              Color(0xFF151026),
              Color(0xFF1C1337),
            ],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      
      // Glassmorphic Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => _navigateToTab(index, null),
              backgroundColor: const Color(0xFF0F0C1B).withOpacity(0.8),
              selectedItemColor: const Color(0xFF8C52FF),
              unselectedItemColor: Colors.white38,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  activeIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF8C52FF)),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.checklist_rounded),
                  activeIcon: Icon(Icons.checklist_rounded, color: Color(0xFF8C52FF)),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_rounded),
                  activeIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF8C52FF)),
                  label: 'Calendar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
