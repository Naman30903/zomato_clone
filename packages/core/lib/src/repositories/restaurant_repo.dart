import 'package:core/src/models/restaurant.dart';
import 'package:core/src/models/enums.dart';

abstract class RestaurantRepo {
  Future<List<Restaurant>> getRestaurants();
  Future<Restaurant> getRestaurantById(String id);
  Future<List<Restaurant>> getRestaurantsByCategory(
    RestaurantCategory category,
  );
  Future<List<Restaurant>> searchRestaurants(String query);
  Future<Restaurant> createRestaurant(Restaurant restaurant);
  Future<Restaurant> updateRestaurant(Restaurant restaurant);
  Future<void> deleteRestaurant(String id);
  Future<List<Restaurant>> getNearbyRestaurants(
    double latitude,
    double longitude,
    double radius,
  );
}
