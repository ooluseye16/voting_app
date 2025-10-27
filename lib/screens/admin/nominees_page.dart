import 'package:flutter/material.dart';
import 'package:voting_app/models/voting_event.dart';
import 'package:voting_app/services/firebase_service.dart';

import '../../models/nominee.dart';

class NomineesPage extends StatefulWidget {
  const NomineesPage({super.key, required this.event, this.onUpdate});
  final VotingEvent event;
  final VoidCallback? onUpdate;

  @override
  State<NomineesPage> createState() => _NomineesPageState();
}

class _NomineesPageState extends State<NomineesPage> {
  List<Nominee>? _nominees;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNominees();
  }

  Future<void> _loadNominees() async {
    final nominees = await FirebaseService.getNomineesForEvent(widget.event.id);
    setState(() {
      _nominees = nominees;
      _isLoading = false;
    });
  }

  void _showAddNomineeDialog() {
    final outerContext = context; // capture the valid parent context
    final nameController = TextEditingController();

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Nominee',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nominee Name',
              hintText: 'e.g., John Doe',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a nominee name')),
                );
                return;
              }

              final nominee = Nominee(id: '', name: name);
              await FirebaseService.addNominee(widget.event.id, nominee.name);

              if (dialogContext.mounted) Navigator.pop(dialogContext);
              await _loadNominees();
              widget.onUpdate?.call();

              if (outerContext.mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: Text('✅ Nominee added: ${nominee.name}'),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNominee(Nominee nominee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Nominee'),
        content: Text('Are you sure you want to delete "${nominee.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService.deleteNominee(widget.event.id, nominee.id);
      await _loadNominees();
      widget.onUpdate?.call();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nominee deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    'Nominees',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'People who can be voted for in this event',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddNomineeDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Nominee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _nominees == null || _nominees!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No nominees yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    childAspectRatio: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _nominees!.length,
                  itemBuilder: (context, index) {
                    final nominee = _nominees![index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(
                                0xFF6366F1,
                              ).withOpacity(0.1),
                              child: Text(
                                nominee.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                nominee.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_rounded,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                              onPressed: () => _deleteNominee(nominee),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
