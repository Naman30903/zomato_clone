import 'package:feastly/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
// import 'screens/home_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/splash_screen.dart';
// import 'screens/restaurant_screen.dart';
// import 'screens/cart_screen.dart';
// import 'screens/order_tracking_screen.dart';
// import 'screens/profile_screen.dart';

void main() {
  runApp(const FeastlyApp());
}

class FeastlyApp extends StatelessWidget {
  const FeastlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Feastly',
      theme: ThemeGenerator.customerTheme(isDark: false),
      darkTheme: ThemeGenerator.customerTheme(isDark: true),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

// Define route names as constants
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String restaurant = '/restaurant/:id';
  static const String cart = '/cart';
  static const String orderTracking = '/order/:id';
  static const String profile = '/profile';
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    //     GoRoute(
    //       path: Routes.login,
    //       builder: (context, state) => const LoginScreen(),
    //     ),
    //     GoRoute(
    //       path: Routes.home,
    //       builder: (context, state) => const HomeScreen(),
    //     ),
    //     GoRoute(
    //       path: Routes.restaurant,
    //       builder: (context, state) {
    //         final restaurantId = state.pathParameters['id'] ?? '';
    //         return RestaurantScreen(restaurantId: restaurantId);
    //       },
    //     ),
    //     GoRoute(
    //       path: Routes.cart,
    //       builder: (context, state) => const CartScreen(),
    //     ),
    //     GoRoute(
    //       path: Routes.orderTracking,
    //       builder: (context, state) {
    //         final orderId = state.pathParameters['id'] ?? '';
    //         return OrderTrackingScreen(orderId: orderId);
    //       },
    //     ),
    //     GoRoute(
    //       path: Routes.profile,
    //       builder: (context, state) => const ProfileScreen(),
    //     ),
  ],
  initialLocation: Routes.splash,
);
