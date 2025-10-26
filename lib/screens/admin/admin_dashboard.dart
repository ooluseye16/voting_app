
import 'package:flutter/material.dart';
import 'results_page.dart';
import 'categories_page.dart';
import 'nominees_page.dart';
import 'access_codes_page.dart';
import '../login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ResultsPage(),
    const CategoriesPage(),
    const NomineesPage(),
    const AccessCodesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            backgroundColor: Colors.white,
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(
              color: Color(0xFF6366F1),
            ),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_rounded),
                label: Text('Results'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_rounded),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_rounded),
                label: Text('Nominees'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.vpn_key_rounded),
                label: Text('Codes'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1, color: Colors.grey.shade200),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}