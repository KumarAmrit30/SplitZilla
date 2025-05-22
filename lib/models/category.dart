import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  String color;

  Category({
    String? id,
    required this.name,
    required this.icon,
    required this.color,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'color': color};
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
    );
  }
}
