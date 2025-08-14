import 'enums.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phoneNumber;
  final String email;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final double rating;
  final int numberOfRatings;
  final bool isOpen;
  final String ownerId;
  final List<RestaurantCategory> categories;
  final Map<String, dynamic> openingHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.latitude,
    required this.longitude,
    this.imageUrls = const [],
    this.rating = 0.0,
    this.numberOfRatings = 0,
    this.isOpen = false,
    required this.ownerId,
    this.categories = const [],
    required this.openingHours,
    required this.createdAt,
    required this.updatedAt,
  });

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? email,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    double? rating,
    int? numberOfRatings,
    bool? isOpen,
    String? ownerId,
    List<RestaurantCategory>? categories,
    Map<String, dynamic>? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      rating: rating ?? this.rating,
      numberOfRatings: numberOfRatings ?? this.numberOfRatings,
      isOpen: isOpen ?? this.isOpen,
      ownerId: ownerId ?? this.ownerId,
      categories: categories ?? this.categories,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'rating': rating,
      'numberOfRatings': numberOfRatings,
      'isOpen': isOpen,
      'ownerId': ownerId,
      'categories': categories
          .map((c) => c.toString().split('.').last)
          .toList(),
      'openingHours': openingHours,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      rating: json['rating'] ?? 0.0,
      numberOfRatings: json['numberOfRatings'] ?? 0,
      isOpen: json['isOpen'] ?? false,
      ownerId: json['ownerId'],
      categories:
          (json['categories'] as List?)
              ?.map(
                (c) => RestaurantCategory.values.firstWhere(
                  (e) => e.toString().split('.').last == c,
                  orElse: () => RestaurantCategory.casual,
                ),
              )
              .toList() ??
          [],
      openingHours: json['openingHours'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
