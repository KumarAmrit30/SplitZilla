import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String category;

  @HiveField(5)
  String? tripId;

  @HiveField(6)
  String? paidBy;

  @HiveField(7)
  List<String>? splitBetween;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.tripId,
    this.paidBy,
    this.splitBetween,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'tripId': tripId,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      tripId: json['tripId'],
      paidBy: json['paidBy'],
      splitBetween:
          json['splitBetween'] != null
              ? List<String>.from(json['splitBetween'])
              : null,
    );
  }
}
