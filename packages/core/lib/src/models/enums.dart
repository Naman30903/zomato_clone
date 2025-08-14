enum OrderStatus {
  placed,
  confirmed,
  preparing,
  readyForPickup,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

enum PaymentMethod { cashOnDelivery, creditCard, debitCard, upi, wallet }

enum UserRole { customer, restaurantOwner, deliveryPerson, admin }

enum FoodCategory {
  breakfast,
  lunch,
  dinner,
  snacks,
  beverages,
  desserts,
  veg,
  nonVeg,
  vegan,
}

enum RestaurantCategory {
  fastFood,
  casual,
  fineDining,
  cafe,
  bakery,
  buffet,
  cloudKitchen,
}
