import 'package:flutter/material.dart';
import 'package:voting_app/screens/admin/access_codes_page.dart';
import 'package:voting_app/screens/admin/categories_page.dart';
import 'package:voting_app/screens/admin/event_results_tab.dart'; // you'll create or update this
import 'package:voting_app/screens/admin/nominees_page.dart';

import '../../models/event_statistics.dart';
import '../../models/voting_event.dart';
import '../../services/firebase_service.dart';

class EventManagementPage extends StatefulWidget {
  final VotingEvent event;

  const EventManagementPage({super.key, required this.event});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EventStatistics? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final stats = await FirebaseService.getEventStatistics(widget.event.id);
    if (mounted) {
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
      });
    }
  }

  void _showEventSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: _iconTile(Icons.refresh_rounded, Colors.orange),
              title: const Text('Reset Votes'),
              subtitle: const Text('Delete all votes, reset access codes'),
              onTap: () {
                Navigator.pop(context);
                _resetEventVotes();
              },
            ),
            ListTile(
              leading: _iconTile(Icons.clear_all_rounded, Colors.red),
              title: const Text('Clear All Data'),
              subtitle: const Text('Delete everything except event shell'),
              onTap: () {
                Navigator.pop(context);
                _clearEventData();
              },
            ),
            ListTile(
              leading: _iconTile(Icons.archive_rounded, Colors.blue),
              title: const Text('Archive Event'),
              subtitle: const Text('Mark as inactive'),
              onTap: () {
                Navigator.pop(context);
                _archiveEvent();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: color),
  );

  Future<void> _resetEventVotes() async {
    final confirm = await _confirmDialog(
      title: 'Reset Votes?',
      content:
          'This will delete all votes and reset access codes. Nominees and categories will be preserved.',
      confirmColor: Colors.orange,
      confirmText: 'Reset',
    );

    if (confirm == true) {
      final success = await FirebaseService.resetEventData(widget.event.id);
      if (mounted) {
        _showSnack(
          success ? 'Votes reset successfully' : 'Failed to reset votes',
        );
        if (success) _loadStatistics();
      }
    }
  }

  Future<void> _clearEventData() async {
    final confirm = await _confirmDialog(
      title: 'Clear All Data?',
      content:
          'This will delete ALL data including nominees, categories, votes, and access codes. This action cannot be undone.',
      confirmColor: Colors.red,
      confirmText: 'Clear All',
    );

    if (confirm == true) {
      final success = await FirebaseService.clearEventData(widget.event.id);
      if (mounted) {
        _showSnack(success ? 'Event data cleared' : 'Failed to clear data');
        if (success) _loadStatistics();
      }
    }
  }

  Future<void> _archiveEvent() async {
    final success = await FirebaseService.archiveEvent(widget.event.id);
    if (mounted && success) {
      Navigator.pop(context);
      _showSnack('Event archived', color: Colors.green.shade600);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String content,
    required Color confirmColor,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.name,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.event.type.toUpperCase(),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (!_isLoadingStats && _statistics != null) _buildStatisticsMenu(),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.black87),
            onPressed: _showEventSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Results'),
            Tab(icon: Icon(Icons.category_rounded), text: 'Categories'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Nominees'),
            Tab(icon: Icon(Icons.vpn_key_rounded), text: 'Codes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EventResultsTab(event: widget.event),
          CategoriesPage(event: widget.event),
          NomineesPage(event: widget.event, onUpdate: _loadStatistics),
          AccessCodesPage(event: widget.event, onUpdate: _loadStatistics),
        ],
      ),
    );
  }

  Widget _buildStatisticsMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Statistics',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.analytics_rounded, color: Color(0xFF6366F1)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Statistics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              _buildStatRow(
                Icons.people,
                'Nominees',
                _statistics!.totalNominees.toString(),
              ),
              _buildStatRow(
                Icons.category,
                'Categories',
                _statistics!.totalCategories.toString(),
              ),
              _buildStatRow(
                Icons.vpn_key,
                'Total Codes',
                _statistics!.totalAccessCodes.toString(),
              ),
              _buildStatRow(
                Icons.check_circle,
                'Used Codes',
                _statistics!.usedCodes.toString(),
                Colors.green,
              ),
              _buildStatRow(
                Icons.pending,
                'Unused Codes',
                _statistics!.unusedCodes.toString(),
                Colors.orange,
              ),
              _buildStatRow(
                Icons.how_to_vote,
                'Total Votes',
                _statistics!.totalVotes.toString(),
                Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value, [
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
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
                fontSize: 14,
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
