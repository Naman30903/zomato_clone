import 'package:core/src/models/menu_item.dart';
import 'package:core/src/models/enums.dart';
import 'package:core/src/repositories/menu_repo.dart';

class MockMenuRepo implements MenuRepo {
  final List<MenuItem> _menuItems = [
    MenuItem(
      id: 'menu_1',
      restaurantId: 'rest_1',
      name: 'Classic Cheeseburger',
      description:
          'Juicy beef patty with cheese, lettuce, tomato, and special sauce',
      price: 8.99,
      imageUrls: 'https://example.com/cheeseburger.jpg',
      categories: [FoodCategory.snacks, FoodCategory.nonVeg],
      isVegetarian: false,
      isVegan: false,
      isGlutenFree: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MenuItem(
      id: 'menu_2',
      restaurantId: 'rest_1',
      name: 'Veggie Burger',
      description: 'Plant-based patty with lettuce, tomato, and vegan mayo',
      price: 9.99,
      imageUrls: 'https://example.com/veggie_burger.jpg',
      categories: [FoodCategory.snacks, FoodCategory.veg],
      isVegetarian: true,
      isVegan: true,
      isGlutenFree: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    MenuItem(
      id: 'menu_3',
      restaurantId: 'rest_1',
      name: 'French Fries',
      description: 'Crispy golden fries with sea salt',
      price: 3.99,
      imageUrls: 'https://example.com/fries.jpg',
      categories: [FoodCategory.snacks, FoodCategory.veg, FoodCategory.vegan],
      isVegetarian: true,
      isVegan: true,
      isGlutenFree: true,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    MenuItem(
      id: 'menu_4',
      restaurantId: 'rest_1',
      name: 'Chocolate Milkshake',
      description: 'Creamy chocolate shake with whipped cream',
      price: 4.99,
      imageUrls: 'https://example.com/milkshake.jpg',
      categories: [FoodCategory.desserts, FoodCategory.beverages],
      isVegetarian: true,
      isVegan: false,
      isGlutenFree: true,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    MenuItem(
      id: 'menu_5',
      restaurantId: 'rest_2',
      name: 'Margherita Pizza',
      description: 'Classic pizza with tomato sauce, mozzarella, and basil',
      price: 12.99,
      imageUrls: 'https://example.com/margherita.jpg',
      categories: [FoodCategory.lunch, FoodCategory.dinner, FoodCategory.veg],
      isVegetarian: true,
      isVegan: false,
      isGlutenFree: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    MenuItem(
      id: 'menu_6',
      restaurantId: 'rest_2',
      name: 'Pepperoni Pizza',
      description: 'Pizza with tomato sauce, mozzarella, and pepperoni',
      price: 14.99,
      imageUrls: 'https://example.com/pepperoni.jpg',
      categories: [
        FoodCategory.lunch,
        FoodCategory.dinner,
        FoodCategory.nonVeg,
      ],
      isVegetarian: false,
      isVegan: false,
      isGlutenFree: false,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    MenuItem(
      id: 'menu_7',
      restaurantId: 'rest_3',
      name: 'California Roll',
      description: 'Crab, avocado, and cucumber wrapped in seaweed and rice',
      price: 7.99,
      imageUrls: 'https://example.com/california_roll.jpg',
      categories: [
        FoodCategory.lunch,
        FoodCategory.dinner,
        FoodCategory.nonVeg,
      ],
      isVegetarian: false,
      isVegan: false,
      isGlutenFree: true,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  @override
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _menuItems
        .where((item) => item.restaurantId == restaurantId)
        .toList();
  }

  @override
  Future<MenuItem> getMenuItemById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _menuItems.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Menu item not found'),
    );
  }

  @override
  Future<List<MenuItem>> getMenuItemsByCategory(
    String restaurantId,
    FoodCategory category,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _menuItems
        .where(
          (item) =>
              item.restaurantId == restaurantId &&
              item.categories.contains(category),
        )
        .toList();
  }

  @override
  Future<MenuItem> createMenuItem(MenuItem menuItem) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final newMenuItem = menuItem.copyWith(
      id: 'menu_${_menuItems.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _menuItems.add(newMenuItem);
    return newMenuItem;
  }

  @override
  Future<MenuItem> updateMenuItem(MenuItem menuItem) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _menuItems.indexWhere((item) => item.id == menuItem.id);
    if (index == -1) {
      throw Exception('Menu item not found');
    }

    final updatedMenuItem = menuItem.copyWith(updatedAt: DateTime.now());
    _menuItems[index] = updatedMenuItem;
    return updatedMenuItem;
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _menuItems.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Menu item not found');
    }

    _menuItems.removeAt(index);
  }

  @override
  Future<List<MenuItem>> searchMenuItems(
    String restaurantId,
    String query,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final lowercaseQuery = query.toLowerCase();
    return _menuItems
        .where(
          (item) =>
              item.restaurantId == restaurantId &&
              (item.name.toLowerCase().contains(lowercaseQuery) ||
                  item.description.toLowerCase().contains(lowercaseQuery)),
        )
        .toList();
  }
}
