import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../providers/trip_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/expense_dialog.dart';
import '../widgets/trip_dialog.dart';
import '../utils/icon_utils.dart';
import '../models/category.dart' as models;

class TripDetailPage extends StatefulWidget {
  final Trip trip;

  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  @override
  void initState() {
    super.initState();
    // No need to load settlements here, they are loaded with the trip
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<TripProvider, ExpenseProvider, CategoryProvider>(
      builder: (
        context,
        tripProvider,
        expenseProvider,
        categoryProvider,
        child,
      ) {
        final trip = widget.trip;
        final tripExpenses = expenseProvider.getExpensesByTripId(trip.id);
        final categoryExpenses = _getCategoryWiseExpenses(tripExpenses);
        final totalExpense = tripExpenses.fold(0.0, (sum, e) => sum + e.amount);
        final perPersonExpense = totalExpense / trip.participants.length;

        // Apply manual settlements to balances (from trip.settlements)
        final Map<String, double> manualAdjustments = {
          for (var p in trip.participants) p: 0.0,
        };
        for (final s in trip.settlements) {
          manualAdjustments[s.payer] =
              (manualAdjustments[s.payer] ?? 0) + s.amount;
          manualAdjustments[s.payee] =
              (manualAdjustments[s.payee] ?? 0) - s.amount;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(trip.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => TripDialog(trip: trip),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete Trip'),
                          content: const Text(
                            'Are you sure you want to delete this trip? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                tripProvider.deleteTrip(trip.id);
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Go back to trips page
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Trip Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children:
                              trip.participants.map((participant) {
                                return Chip(label: Text(participant));
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expense Summary
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Total Expenses',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalExpense.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${perPersonExpense.toStringAsFixed(2)} per person',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // Settlement Section
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Participant Balances',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Record Payment'),
                              onPressed: () async {
                                final result =
                                    await showDialog<ManualSettlement>(
                                      context: context,
                                      builder:
                                          (context) => _RecordPaymentDialog(
                                            participants: trip.participants,
                                          ),
                                    );
                                if (result != null) {
                                  await tripProvider.addManualSettlement(
                                    trip.id,
                                    result,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._buildParticipantBalances(
                          trip,
                          tripExpenses,
                          manualAdjustments,
                        ),
                      ],
                    ),
                  ),
                ),

                // Who Pays Whom Section
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Who Pays Whom',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ..._buildSettlementList(
                          trip,
                          tripExpenses,
                          manualAdjustments,
                        ),
                      ],
                    ),
                  ),
                ),

                // Pie Chart
                if (categoryExpenses.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _createPieChartSections(
                          categoryExpenses,
                          categoryProvider.categories,
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),

                // Expense List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tripExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = tripExpenses[index];
                    final category = categoryProvider.getCategoryById(
                      expense.category,
                    );
                    return Dismissible(
                      key: Key(expense.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        expenseProvider.deleteExpense(expense.id);
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: parseColor(category?.color),
                          child: Icon(
                            getIconData(category?.icon ?? 'other'),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(expense.title),
                        subtitle: Text(
                          '${category?.name ?? 'Other'} • ${expense.date.toString().split(' ')[0]}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (expense.paidBy != null)
                              Text(
                                'Paid by ${expense.paidBy}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => ExpenseDialog(
                                  expense: expense,
                                  tripId: trip.id,
                                ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'trip_detail_fab',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ExpenseDialog(tripId: trip.id),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Map<String, double> _getCategoryWiseExpenses(List<Expense> expenses) {
    Map<String, double> categoryExpenses = {};
    for (var expense in expenses) {
      categoryExpenses[expense.category] =
          (categoryExpenses[expense.category] ?? 0) + expense.amount;
    }
    return categoryExpenses;
  }

  List<PieChartSectionData> _createPieChartSections(
    Map<String, double> categoryExpenses,
    List<dynamic> categories,
  ) {
    return categoryExpenses.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse:
            () => models.Category(
              name: 'Other',
              icon: 'more_horiz',
              color: '#9E9E9E',
            ),
      );

      return PieChartSectionData(
        value: entry.value,
        title:
            '${(entry.value / categoryExpenses.values.reduce((a, b) => a + b) * 100).toStringAsFixed(1)}%',
        color: parseColor(category?.color),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildParticipantBalances(
    Trip trip,
    List<Expense> expenses,
    Map<String, double> manualAdjustments,
  ) {
    // Calculate net balance for each participant
    final Map<String, double> balances = {
      for (var p in trip.participants) p: 0.0,
    };
    for (final expense in expenses) {
      if (expense.paidBy != null &&
          expense.splitBetween != null &&
          expense.splitBetween!.isNotEmpty) {
        final split = expense.amount / expense.splitBetween!.length;
        for (final participant in expense.splitBetween!) {
          balances[participant] = (balances[participant] ?? 0) - split;
        }
        balances[expense.paidBy!] =
            (balances[expense.paidBy!] ?? 0) + expense.amount;
      }
    }
    // Apply manual settlements
    manualAdjustments.forEach((k, v) {
      balances[k] = (balances[k] ?? 0) + v;
    });
    // Build UI
    return trip.participants.map((participant) {
      final balance = balances[participant] ?? 0.0;
      Color color =
          balance > 0 ? Colors.green : (balance < 0 ? Colors.red : Colors.grey);
      String text =
          balance > 0
              ? 'should receive ₹${balance.abs().toStringAsFixed(2)}'
              : balance < 0
              ? 'should pay ₹${balance.abs().toStringAsFixed(2)}'
              : 'is settled up';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(participant)),
            Text(text, style: TextStyle(color: color)),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildSettlementList(
    Trip trip,
    List<Expense> expenses,
    Map<String, double> manualAdjustments,
  ) {
    // Calculate net balance for each participant
    final Map<String, double> balances = {
      for (var p in trip.participants) p: 0.0,
    };
    for (final expense in expenses) {
      if (expense.paidBy != null &&
          expense.splitBetween != null &&
          expense.splitBetween!.isNotEmpty) {
        final split = expense.amount / expense.splitBetween!.length;
        for (final participant in expense.splitBetween!) {
          balances[participant] = (balances[participant] ?? 0) - split;
        }
        balances[expense.paidBy!] =
            (balances[expense.paidBy!] ?? 0) + expense.amount;
      }
    }
    // Apply manual settlements
    manualAdjustments.forEach((k, v) {
      balances[k] = (balances[k] ?? 0) + v;
    });
    // Create a list of creditors and debtors
    final creditors = <String, double>{};
    final debtors = <String, double>{};
    balances.forEach((participant, balance) {
      if (balance > 0.01) {
        creditors[participant] = balance;
      } else if (balance < -0.01) {
        debtors[participant] = -balance;
      }
    });
    final settlements = <Widget>[];
    final creditorList = creditors.entries.toList();
    final debtorList = debtors.entries.toList();
    int i = 0, j = 0;
    while (i < debtorList.length && j < creditorList.length) {
      final debtor = debtorList[i];
      final creditor = creditorList[j];
      final amount =
          debtor.value < creditor.value ? debtor.value : creditor.value;
      settlements.add(
        Row(
          children: [
            Expanded(child: Text('${debtor.key} pays ${creditor.key}')),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
      );
      debtorList[i] = MapEntry(debtor.key, debtor.value - amount);
      creditorList[j] = MapEntry(creditor.key, creditor.value - amount);
      if (debtorList[i].value < 0.01) i++;
      if (creditorList[j].value < 0.01) j++;
    }
    if (settlements.isEmpty) {
      settlements.add(
        const Text('All settled up!', style: TextStyle(color: Colors.green)),
      );
    }
    return settlements;
  }
}

// Dialog for recording a payment
class _RecordPaymentDialog extends StatefulWidget {
  final List<String> participants;
  const _RecordPaymentDialog({required this.participants});

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  String? _payer;
  String? _payee;
  String _amount = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _payer,
            decoration: const InputDecoration(labelText: 'Payer'),
            items:
                widget.participants
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
            onChanged: (v) => setState(() => _payer = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _payee,
            decoration: const InputDecoration(labelText: 'Payee'),
            items:
                widget.participants
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
            onChanged: (v) => setState(() => _payee = v),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _amount = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_payer != null &&
                _payee != null &&
                _payer != _payee &&
                double.tryParse(_amount) != null &&
                double.parse(_amount) > 0) {
              Navigator.pop(
                context,
                ManualSettlement(
                  payer: _payer!,
                  payee: _payee!,
                  amount: double.parse(_amount),
                ),
              );
            }
          },
          child: const Text('Record'),
        ),
      ],
    );
  }
}
