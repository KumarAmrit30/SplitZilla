import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'trip.g.dart';

@HiveType(typeId: 3)
class ManualSettlement extends HiveObject {
  @HiveField(0)
  String payer;
  @HiveField(1)
  String payee;
  @HiveField(2)
  double amount;

  ManualSettlement({
    required this.payer,
    required this.payee,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'payer': payer,
    'payee': payee,
    'amount': amount,
  };

  factory ManualSettlement.fromJson(Map<String, dynamic> json) =>
      ManualSettlement(
        payer: json['payer'],
        payee: json['payee'],
        amount: (json['amount'] as num).toDouble(),
      );
}

@HiveType(typeId: 1)
class Trip extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime endDate;

  @HiveField(5)
  List<String> participants;

  @HiveField(6)
  List<String> expenseIds;

  @HiveField(7)
  List<ManualSettlement> settlements;

  Trip({
    String? id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    List<String>? participants,
    List<String>? expenseIds,
    List<ManualSettlement>? settlements,
  }) : id = id ?? const Uuid().v4(),
       participants = participants ?? [],
       expenseIds = expenseIds ?? [],
       settlements = settlements ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'participants': participants,
      'expenseIds': expenseIds,
      'settlements': settlements.map((s) => s.toJson()).toList(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      participants: List<String>.from(json['participants']),
      expenseIds: List<String>.from(json['expenseIds']),
      settlements:
          json['settlements'] != null
              ? List<Map<String, dynamic>>.from(
                json['settlements'],
              ).map((s) => ManualSettlement.fromJson(s)).toList()
              : [],
    );
  }
}
