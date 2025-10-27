import 'package:flutter/material.dart';
import 'package:voting_app/screens/admin/event_management_page.dart';

import '../../models/voting_event.dart';
import '../../services/firebase_service.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<VotingEvent>? _events;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await FirebaseService.getAllEvents();
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  void _showCreateEventDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'general';
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Create New Event',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Event Name',
                      hintText: 'e.g., School Elections 2025',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief description of the event',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Event Type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text('General'),
                      ),
                      DropdownMenuItem(value: 'school', child: Text('School')),
                      DropdownMenuItem(value: 'sports', child: Text('Sports')),
                      DropdownMenuItem(
                        value: 'company',
                        child: Text('Company'),
                      ),
                      DropdownMenuItem(
                        value: 'community',
                        child: Text('Community'),
                      ),
                      DropdownMenuItem(value: 'awards', child: Text('Awards')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => selectedType = value ?? 'general'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          endDate == null
                              ? 'No end date'
                              : 'Ends: ${endDate!.day}/${endDate!.month}/${endDate!.year}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 7),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null)
                            setDialogState(() => endDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Set End Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter event name')),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _isLoading = true);

                final eventId = await FirebaseService.createEvent(
                  name: name,
                  description: desc,
                  type: selectedType,
                  endDate: endDate,
                );

                if (eventId != null) {
                  _loadEvents();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Event "$name" created'),
                        backgroundColor: Colors.green.shade600,
                      ),
                    );
                  }
                } else {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to create event'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(VotingEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Delete Event?'),
          ],
        ),
        content: Text(
          'Delete "${event.name}"?\n\nThis will permanently delete all categories, nominees, votes, and access codes for this event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await FirebaseService.deleteEvent(event.id);
      _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Event deleted' : 'Failed to delete event'),
            backgroundColor: success ? Colors.green.shade600 : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _archiveEvent(VotingEvent event) async {
    final success = await FirebaseService.archiveEvent(event.id);
    _loadEvents();

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event "${event.name}" archived'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  Future<void> _duplicateEvent(VotingEvent event) async {
    final nameController = TextEditingController(text: '${event.name} (Copy)');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Duplicate Event'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Event Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => _isLoading = true);
      final newEventId = await FirebaseService.duplicateEvent(
        event.id,
        newName,
      );

      if (mounted) {
        if (newEventId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event duplicated: $newName'),
              backgroundColor: Colors.green.shade600,
            ),
          );
          _loadEvents();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to duplicate event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'school':
        return Icons.school_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'company':
        return Icons.business_rounded;
      case 'community':
        return Icons.people_rounded;
      case 'awards':
        return Icons.emoji_events_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'school':
        return Colors.blue;
      case 'sports':
        return Colors.green;
      case 'company':
        return Colors.orange;
      case 'community':
        return Colors.purple;
      case 'awards':
        return Colors.amber;
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _buildInfoChip(IconData icon, String label, [Color? color]) {
    final chipColor = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voting Events',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage multiple independent voting events',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showCreateEventDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _events == null || _events!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first voting event to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _events!.length,
                  itemBuilder: (context, index) {
                    final event = _events![index];
                    final eventColor = _getEventColor(event.type);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: eventColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getEventIcon(event.type),
                                    color: eventColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (event.description.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            event.description,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildInfoChip(
                                  Icons.calendar_today_rounded,
                                  'Created ${_formatDate(event.createdAt)}',
                                ),
                                const SizedBox(width: 12),
                                _buildInfoChip(
                                  Icons.category_rounded,
                                  event.type.toUpperCase(),
                                  eventColor,
                                ),
                                if (event.endDate != null) ...[
                                  const SizedBox(width: 12),
                                  _buildInfoChip(
                                    Icons.event_busy_rounded,
                                    'Ends ${_formatDate(event.endDate!)}',
                                    Colors.orange,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EventManagementPage(event: event),
                                      ),
                                    ).then((_) => _loadEvents());
                                  },
                                  icon: const Icon(Icons.login_rounded),
                                  label: const Text('Enter Event'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.grey.shade600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'duplicate':
                                        await _duplicateEvent(event);
                                        break;
                                      case 'archive':
                                        await _archiveEvent(event);
                                        break;
                                      case 'delete':
                                        await _deleteEvent(event);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'duplicate',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.content_copy_rounded,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Duplicate Event'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          Icon(Icons.archive_rounded, size: 20),
                                          SizedBox(width: 12),
                                          Text('Archive Event'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_rounded,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Delete Event',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
