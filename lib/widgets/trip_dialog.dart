import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';

class TripDialog extends StatefulWidget {
  final Trip? trip;

  const TripDialog({super.key, this.trip});

  @override
  State<TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<TripDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;
  final List<String> _participants = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip?.name);
    _descriptionController = TextEditingController(
      text: widget.trip?.description,
    );
    _startDate = widget.trip?.startDate ?? DateTime.now();
    _endDate =
        widget.trip?.endDate ?? DateTime.now().add(const Duration(days: 1));
    if (widget.trip != null) {
      _participants.addAll(widget.trip!.participants);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        return AlertDialog(
          title: Text(widget.trip == null ? 'Add Trip' : 'Edit Trip'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Trip Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a trip name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate.add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Participants'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._participants.map((participant) {
                        return Chip(
                          label: Text(participant),
                          onDeleted: () {
                            setState(() {
                              _participants.remove(participant);
                            });
                          },
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add),
                        label: const Text('Add Participant'),
                        onPressed: () {
                          _showAddParticipantDialog();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_participants.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add at least one participant'),
                      ),
                    );
                    return;
                  }

                  final trip = Trip(
                    id: widget.trip?.id,
                    name: _nameController.text,
                    description: _descriptionController.text,
                    startDate: _startDate,
                    endDate: _endDate,
                    participants: _participants,
                  );

                  if (widget.trip == null) {
                    tripProvider.addTrip(trip);
                  } else {
                    tripProvider.updateTrip(trip);
                  }

                  Navigator.of(context).pop();
                }
              },
              child: Text(widget.trip == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddParticipantDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Participant'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _participants.add(controller.text);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
