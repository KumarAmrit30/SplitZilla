import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/category.dart' as models;

class CategoryProvider with ChangeNotifier {
  late Box<models.Category> _categoryBox;
  List<models.Category> _categories = [];

  List<models.Category> get categories => _categories;

  Future<void> init() async {
    _categoryBox = await Hive.openBox<models.Category>('categories');
    if (_categoryBox.isEmpty) {
      await _initializeDefaultCategories();
    }
    _loadCategories();
  }

  Future<void> _initializeDefaultCategories() async {
    final defaultCategories = [
      models.Category(name: 'Food', icon: 'restaurant', color: '#FF5722'),
      models.Category(
        name: 'Transport',
        icon: 'directions_car',
        color: '#2196F3',
      ),
      models.Category(
        name: 'Shopping',
        icon: 'shopping_cart',
        color: '#9C27B0',
      ),
      models.Category(name: 'Entertainment', icon: 'movie', color: '#E91E63'),
      models.Category(name: 'Bills', icon: 'receipt', color: '#FFC107'),
      models.Category(name: 'Health', icon: 'local_hospital', color: '#4CAF50'),
      models.Category(name: 'Travel', icon: 'flight', color: '#00BCD4'),
      models.Category(name: 'Other', icon: 'more_horiz', color: '#9E9E9E'),
    ];

    for (var category in defaultCategories) {
      await _categoryBox.put(category.id, category);
    }
  }

  void _loadCategories() {
    _categories = _categoryBox.values.toList();
    notifyListeners();
  }

  Future<void> addCategory(models.Category category) async {
    await _categoryBox.put(category.id, category);
    _loadCategories();
  }

  Future<void> updateCategory(models.Category category) async {
    await _categoryBox.put(category.id, category);
    _loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
    _loadCategories();
  }

  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  models.Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }
}
