import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import 'trip_provider.dart';

class ExpenseProvider with ChangeNotifier {
  late Box<Expense> _expenseBox;
  List<Expense> _expenses = [];
  final TripProvider _tripProvider;

  ExpenseProvider(this._tripProvider);

  List<Expense> get expenses => _expenses;
  List<Expense> get tripExpenses =>
      _expenses.where((e) => e.tripId != null).toList();
  List<Expense> get dailyExpenses =>
      _expenses.where((e) => e.tripId == null).toList();

  Future<void> init() async {
    try {
      _expenseBox = await Hive.openBox<Expense>('expenses');
      _loadExpenses();
    } catch (e) {
      debugPrint('Error initializing ExpenseProvider: $e');
    }
  }

  void _loadExpenses() {
    try {
      _expenses = _expenseBox.values.toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      debugPrint('_loadExpenses: Loaded ${_expenses.length} expenses');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _expenseBox.put(expense.id, expense);
      debugPrint(
        'addExpense: Added expense with id: ${expense.id}, tripId: ${expense.tripId}',
      );
      if (expense.tripId != null) {
        await _tripProvider.addExpenseToTrip(expense.tripId!, expense.id);
        debugPrint(
          'addExpense: Called addExpenseToTrip for tripId: ${expense.tripId}, expenseId: ${expense.id}',
        );
      }
      _loadExpenses();
      debugPrint('Expense added successfully: ${expense.title}');
    } catch (e) {
      debugPrint('Error adding expense: $e');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _expenseBox.put(expense.id, expense);
      _loadExpenses();
      debugPrint('Expense updated successfully: ${expense.title}');
    } catch (e) {
      debugPrint('Error updating expense: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final expense = _expenses.firstWhere((e) => e.id == id);
      if (expense.tripId != null) {
        await _tripProvider.removeExpenseFromTrip(expense.tripId!, id);
      }
      await _expenseBox.delete(id);
      _loadExpenses();
      debugPrint('Expense deleted successfully: $id');
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }

  List<Expense> getExpensesByTripId(String tripId) {
    try {
      final result = _expenses.where((e) => e.tripId == tripId).toList();
      debugPrint('getExpensesByTripId: tripId=$tripId, found=${result.length}');
      return result;
    } catch (e) {
      debugPrint('Error getting expenses by trip id: $e');
      return [];
    }
  }

  List<Expense> getExpensesByCategory(String category) {
    try {
      return _expenses.where((e) => e.category == category).toList();
    } catch (e) {
      debugPrint('Error getting expenses by category: $e');
      return [];
    }
  }

  List<Expense> getExpensesByDate(DateTime date) {
    try {
      return _expenses
          .where(
            (e) =>
                e.date.year == date.year &&
                e.date.month == date.month &&
                e.date.day == date.day,
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting expenses by date: $e');
      return [];
    }
  }

  double getTotalExpenses() {
    try {
      return _expenses.fold(0, (sum, e) => sum + e.amount);
    } catch (e) {
      debugPrint('Error calculating total expenses: $e');
      return 0;
    }
  }

  double getTotalTripExpenses() {
    try {
      return tripExpenses.fold(0, (sum, e) => sum + e.amount);
    } catch (e) {
      debugPrint('Error calculating total trip expenses: $e');
      return 0;
    }
  }

  double getTotalDailyExpenses() {
    try {
      return dailyExpenses.fold(0, (sum, e) => sum + e.amount);
    } catch (e) {
      debugPrint('Error calculating total daily expenses: $e');
      return 0;
    }
  }
}
