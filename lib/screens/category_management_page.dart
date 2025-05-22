import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart' as models;
import '../utils/icon_utils.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Category Management')),
          body: ListView.builder(
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: parseColor(category.color),
                  child: Icon(getIconData(category.icon), color: Colors.white),
                ),
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    categoryProvider.deleteCategory(category.id);
                  },
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'category_management_fab',
            onPressed: () {
              _showAddCategoryDialog(context, categoryProvider);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    CategoryProvider categoryProvider,
  ) {
    final nameController = TextEditingController();
    final List<String> iconOptions = [
      'restaurant',
      'directions_car',
      'hotel',
      'shopping_bag',
      'movie',
      'sports_basketball',
      'more_horiz',
    ];
    final List<String> colorOptions = [
      '#FF5722',
      '#2196F3',
      '#9C27B0',
      '#E91E63',
      '#FFC107',
      '#4CAF50',
      '#00BCD4',
      '#9E9E9E',
    ];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ],
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
                if (nameController.text.isNotEmpty) {
                  final random = DateTime.now().millisecondsSinceEpoch;
                  final icon = iconOptions[random % iconOptions.length];
                  final color = colorOptions[random % colorOptions.length];
                  final category = models.Category(
                    name: nameController.text,
                    icon: icon,
                    color: color,
                  );
                  categoryProvider.addCategory(category);
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
