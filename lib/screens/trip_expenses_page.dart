import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../models/expense.dart';
import '../providers/trip_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/trip_dialog.dart';
import 'trip_detail_page.dart';

class TripExpensesPage extends StatelessWidget {
  const TripExpensesPage({super.key});

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
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Trips'),
              bottom: const TabBar(
                tabs: [Tab(text: 'Active'), Tab(text: 'Past')],
              ),
            ),
            body: TabBarView(
              children: [
                _buildTripList(
                  context,
                  tripProvider.activeTrips,
                  expenseProvider,
                  categoryProvider,
                ),
                _buildTripList(
                  context,
                  tripProvider.pastTrips,
                  expenseProvider,
                  categoryProvider,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'trip_expenses_fab',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const TripDialog(),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripList(
    BuildContext context,
    List<Trip> trips,
    ExpenseProvider expenseProvider,
    CategoryProvider categoryProvider,
  ) {
    if (trips.isEmpty) {
      return const Center(child: Text('No trips found'));
    }

    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        final tripExpenses = expenseProvider.getExpensesByTripId(trip.id);
        final categoryExpenses = _getCategoryWiseExpenses(tripExpenses);
        final totalExpense = tripExpenses.fold(0.0, (sum, e) => sum + e.amount);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailPage(trip: trip),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${totalExpense.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${trip.participants.length} participants',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Trip',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Trip'),
                                  content: const Text(
                                    'Are you sure you want to delete this trip? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            Provider.of<TripProvider>(
                              context,
                              listen: false,
                            ).deleteTrip(trip.id);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
}
