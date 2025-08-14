import 'package:core/src/models/restaurant.dart';
import 'package:core/src/models/enums.dart';
import 'package:core/src/repositories/restaurant_repo.dart';

class MockRestaurantRepo implements RestaurantRepo {
  final List<Restaurant> _restaurants = [
    Restaurant(
      id: 'rest_1',
      name: 'Burger Palace',
      description: 'The best burgers in town',
      address: '123 Burger St',
      phoneNumber: '555-1234',
      email: 'info@burgerpalace.com',
      imageUrls: ['https://example.com/burger_palace.jpg'],
      categories: [
        RestaurantCategory.casual,
        RestaurantCategory.fastFood,
        RestaurantCategory.cafe,
      ],
      rating: 4.5,
      numberOfRatings: 120,
      latitude: 37.7749,
      longitude: -122.4194,
      ownerId: '2',
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      openingHours: {
        'Monday': '9:00 AM - 10:00 PM',
        'Tuesday': '9:00 AM - 10:00 PM',
        'Wednesday': '9:00 AM - 10:00 PM',
        'Thursday': '9:00 AM - 10:00 PM',
        'Friday': '9:00 AM - 11:00 PM',
        'Saturday': '10:00 AM - 11:00 PM',
        'Sunday': '10:00 AM - 9:00 PM',
      },
    ),
    Restaurant(
      id: 'rest_2',
      name: 'Pizza Heaven',
      description: 'Authentic Italian pizzas',
      address: '456 Pizza Ave',
      phoneNumber: '555-5678',
      email: 'info@pizzaheaven.com',
      imageUrls: ['https://example.com/pizza_heaven.jpg'],
      categories: [
        RestaurantCategory.casual,
        RestaurantCategory.fastFood,
        RestaurantCategory.cloudKitchen,
      ],
      rating: 4.7,
      numberOfRatings: 85,
      openingHours: {
        'Monday': '11:00 AM - 11:00 PM',
        'Tuesday': '11:00 AM - 11:00 PM',
        'Wednesday': '11:00 AM - 11:00 PM',
        'Thursday': '11:00 AM - 11:00 PM',
        'Friday': '11:00 AM - 12:00 AM',
        'Saturday': '12:00 PM - 12:00 AM',
        'Sunday': '12:00 PM - 10:00 PM',
      },
      latitude: 37.7850,
      longitude: -122.4000,
      ownerId: '2',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Restaurant(
      id: 'rest_3',
      name: 'Sushi Express',
      description: 'Fresh sushi delivered fast',
      address: '789 Sushi Blvd',
      phoneNumber: '555-9012',
      email: 'info@sushiexpress.com',
      imageUrls: ['https://example.com/sushi_express.jpg'],
      categories: [RestaurantCategory.fineDining, RestaurantCategory.cafe],
      rating: 4.3,
      numberOfRatings: 64,
      openingHours: {
        'Monday': '12:00 PM - 10:00 PM',
        'Tuesday': '12:00 PM - 10:00 PM',
        'Wednesday': '12:00 PM - 10:00 PM',
        'Thursday': '12:00 PM - 10:00 PM',
        'Friday': '12:00 PM - 11:00 PM',
        'Saturday': '1:00 PM - 11:00 PM',
        'Sunday': '1:00 PM - 9:00 PM',
      },
      latitude: 37.7650,
      longitude: -122.4200,
      ownerId: '2',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  @override
  Future<List<Restaurant>> getRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_restaurants);
  }

  @override
  Future<Restaurant> getRestaurantById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _restaurants.firstWhere(
      (restaurant) => restaurant.id == id,
      orElse: () => throw Exception('Restaurant not found'),
    );
  }

  @override
  Future<List<Restaurant>> getRestaurantsByCategory(
    RestaurantCategory category,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _restaurants
        .where((restaurant) => restaurant.categories.contains(category))
        .toList();
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final lowercaseQuery = query.toLowerCase();
    return _restaurants
        .where(
          (restaurant) =>
              restaurant.name.toLowerCase().contains(lowercaseQuery) ||
              restaurant.description.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  @override
  Future<Restaurant> createRestaurant(Restaurant restaurant) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final newRestaurant = restaurant.copyWith(
      id: 'rest_${_restaurants.length + 1}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _restaurants.add(newRestaurant);
    return newRestaurant;
  }

  @override
  Future<Restaurant> updateRestaurant(Restaurant restaurant) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _restaurants.indexWhere((r) => r.id == restaurant.id);
    if (index == -1) {
      throw Exception('Restaurant not found');
    }

    final updatedRestaurant = restaurant.copyWith(updatedAt: DateTime.now());
    _restaurants[index] = updatedRestaurant;
    return updatedRestaurant;
  }

  @override
  Future<void> deleteRestaurant(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _restaurants.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('Restaurant not found');
    }

    _restaurants.removeAt(index);
  }

  @override
  Future<List<Restaurant>> getNearbyRestaurants(
    double latitude,
    double longitude,
    double radius,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple distance calculation for mock purposes
    return _restaurants.where((restaurant) {
      final latDiff = (restaurant.latitude - latitude).abs();
      final lngDiff = (restaurant.longitude - longitude).abs();
      final approximateDistance = latDiff + lngDiff;

      final simplifiedRadius = radius / 111000;
      return approximateDistance < simplifiedRadius;
    }).toList();
  }
}
