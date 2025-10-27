// File: lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:voting_app/screens/admin/events_page.dart';
import 'package:voting_app/screens/login_page.dart';
import 'package:voting_app/services/firebase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats =
        await FirebaseService.getOverallStatistics(); // not event-scoped
    if (mounted) {
      setState(() {
        _statistics = stats.isNotEmpty ? stats : null;
        _isLoadingStats = false;
      });
    }
  }

  int _getStatValue(String key) => (_statistics?[key] as int?) ?? 0;

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
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
              ),
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
          // Statistics popup
          if (!_isLoadingStats && _statistics != null)
            PopupMenuButton<String>(
              tooltip: 'Statistics',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF6366F1),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 50),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistics Overview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(),
                      _buildStatRow(
                        Icons.event,
                        'Total Events',
                        _getStatValue('totalEvents').toString(),
                      ),
                      _buildStatRow(
                        Icons.people,
                        'Total Nominees',
                        _getStatValue('totalNominees').toString(),
                      ),
                      _buildStatRow(
                        Icons.category,
                        'Total Categories',
                        _getStatValue('totalCategories').toString(),
                      ),
                      _buildStatRow(
                        Icons.how_to_vote,
                        'Total Votes',
                        _getStatValue('totalVotes').toString(),
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Logout
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),

      // The dashboard body is just the EventsPage
      body: EventsPage(),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value, [
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF6366F1)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
