import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/expense.dart';
import '../models/category.dart' as models;
import '../utils/icon_utils.dart';
import '../widgets/expense_dialog.dart';

class DailyExpensesPage extends StatelessWidget {
  const DailyExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, CategoryProvider>(
      builder: (context, expenseProvider, categoryProvider, child) {
        final dailyExpenses = expenseProvider.dailyExpenses;
        final categoryExpenses = _getCategoryWiseExpenses(dailyExpenses);

        return Scaffold(
          body: Column(
            children: [
              // Expense Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${expenseProvider.getTotalDailyExpenses().toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium,
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
              Expanded(
                child: ListView.builder(
                  itemCount: dailyExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = dailyExpenses[index];
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
                        trailing: Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => ExpenseDialog(expense: expense),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'daily_expenses_fab',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ExpenseDialog(),
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
    List<models.Category> categories,
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
        color: parseColor(category.color),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
