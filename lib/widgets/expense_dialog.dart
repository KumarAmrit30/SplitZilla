import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/trip_provider.dart';
import '../utils/icon_utils.dart';
import 'package:uuid/uuid.dart';

class ExpenseDialog extends StatefulWidget {
  final Expense? expense;
  final String? tripId;

  const ExpenseDialog({super.key, this.expense, this.tripId});

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String? _selectedPaidBy;
  late List<String> _selectedSplitBetween;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title);
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCategory = widget.expense?.category ?? '';
    _selectedPaidBy = widget.expense?.paidBy;
    _selectedSplitBetween = widget.expense?.splitBetween ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CategoryProvider, ExpenseProvider, TripProvider>(
      builder: (
        context,
        categoryProvider,
        expenseProvider,
        tripProvider,
        child,
      ) {
        final categories = categoryProvider.categories;
        if (categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_selectedCategory.isEmpty) {
          _selectedCategory = categories.first.id;
        }

        final trip =
            widget.tripId != null
                ? tripProvider.getTripById(widget.tripId!)
                : null;
        final participants = trip?.participants ?? [];

        return AlertDialog(
          title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(_selectedDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(
                                  getIconData(category.icon),
                                  color: parseColor(category.color),
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  if (trip != null) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPaidBy,
                      decoration: const InputDecoration(
                        labelText: 'Paid By',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          participants.map((participant) {
                            return DropdownMenuItem(
                              value: participant,
                              child: Text(participant),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaidBy = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Split Between'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          participants.map((participant) {
                            final isSelected = _selectedSplitBetween.contains(
                              participant,
                            );
                            return FilterChip(
                              label: Text(participant),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSplitBetween.add(participant);
                                  } else {
                                    _selectedSplitBetween.remove(participant);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ],
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
                  if (trip != null) {
                    if (_selectedPaidBy == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select who paid for this expense',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedSplitBetween.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select who to split this expense with',
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  final expense = Expense(
                    id: widget.expense?.id ?? const Uuid().v4(),
                    title: _titleController.text,
                    amount: double.parse(_amountController.text),
                    date: _selectedDate,
                    category: _selectedCategory,
                    tripId: widget.tripId,
                    paidBy: _selectedPaidBy,
                    splitBetween: _selectedSplitBetween,
                  );

                  if (widget.expense == null) {
                    expenseProvider.addExpense(expense);
                  } else {
                    expenseProvider.updateExpense(expense);
                  }

                  Navigator.of(context).pop();
                }
              },
              child: Text(widget.expense == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}
