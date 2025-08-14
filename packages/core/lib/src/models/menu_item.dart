import 'enums.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String restaurantId;
  final String imageUrls;
  final bool isAvailable;
  final List<FoodCategory> categories;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final Map<String, bool> allergens;
  final double? discountPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.restaurantId,
    this.imageUrls = '',
    this.isAvailable = true,
    this.categories = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.allergens = const {},
    this.discountPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  double get effectivePrice {
    if (discountPercentage == null || discountPercentage == 0) {
      return price;
    }
    return price * (1 - (discountPercentage! / 100));
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? restaurantId,
    List<String>? imageUrls,
    bool? isAvailable,
    List<FoodCategory>? categories,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    Map<String, bool>? allergens,
    double? discountPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      restaurantId: restaurantId ?? this.restaurantId,
      imageUrls: '',
      isAvailable: isAvailable ?? this.isAvailable,
      categories: categories ?? this.categories,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      allergens: allergens ?? this.allergens,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'restaurantId': restaurantId,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'categories': categories
          .map((c) => c.toString().split('.').last)
          .toList(),
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'allergens': allergens,
      'discountPercentage': discountPercentage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      restaurantId: json['restaurantId'],
      imageUrls: (json['imageUrls'] is List)
          ? (json['imageUrls'] as List).join(',')
          : (json['imageUrls'] ?? ''),
      isAvailable: json['isAvailable'] ?? true,
      categories:
          (json['categories'] as List?)
              ?.map(
                (c) => FoodCategory.values.firstWhere(
                  (e) => e.toString().split('.').last == c,
                  orElse: () => FoodCategory.snacks,
                ),
              )
              .toList() ??
          [],
      isVegetarian: json['isVegetarian'] ?? false,
      isVegan: json['isVegan'] ?? false,
      isGlutenFree: json['isGlutenFree'] ?? false,
      allergens: Map<String, bool>.from(json['allergens'] ?? {}),
      discountPercentage: json['discountPercentage'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
