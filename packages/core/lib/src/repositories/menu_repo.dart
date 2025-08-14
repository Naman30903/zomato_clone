import 'package:core/src/models/menu_item.dart';
import 'package:core/src/models/enums.dart';

abstract class MenuRepo {
  Future<List<MenuItem>> getMenuItems(String restaurantId);
  Future<MenuItem> getMenuItemById(String id);
  Future<List<MenuItem>> getMenuItemsByCategory(
    String restaurantId,
    FoodCategory category,
  );
  Future<MenuItem> createMenuItem(MenuItem menuItem);
  Future<MenuItem> updateMenuItem(MenuItem menuItem);
  Future<void> deleteMenuItem(String id);
  Future<List<MenuItem>> searchMenuItems(String restaurantId, String query);
}
