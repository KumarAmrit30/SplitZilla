import 'package:flutter/material.dart';

// Map of category names to their corresponding icon data
final Map<String, IconData> categoryIcons = {
  'food': Icons.restaurant,
  'transport': Icons.directions_car,
  'accommodation': Icons.hotel,
  'shopping': Icons.shopping_bag,
  'entertainment': Icons.movie,
  'activities': Icons.sports_basketball,
  'other': Icons.more_horiz,
};

// Helper function to get IconData from category icon string
IconData getIconData(String iconName) {
  return categoryIcons[iconName.toLowerCase()] ?? Icons.category;
}

Color parseColor(String? colorString) {
  if (colorString == null) return const Color(0xFF9E9E9E);
  try {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    }
    // Try to parse as int
    return Color(int.parse(colorString));
  } catch (_) {
    // Try to match common color names
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
