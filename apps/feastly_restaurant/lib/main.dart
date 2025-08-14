import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
// import 'screens/login_screen.dart';

// import 'screens/dashboard_screen.dart';
// import 'screens/menu_management_screen.dart';
// import 'screens/order_management_screen.dart';
// import 'screens/order_details_screen.dart';
// import 'screens/profile_screen.dart';

void main() {
  runApp(const FeastlyRestaurantApp());
}

class FeastlyRestaurantApp extends StatelessWidget {
  const FeastlyRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Feastly Restaurant',
      theme: ThemeGenerator.restaurantTheme(isDark: false),
      darkTheme: ThemeGenerator.restaurantTheme(isDark: true),
      themeMode: ThemeMode.system,
      // routerConfig: _router,
    );
  }
}

// Define route names as constants
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String menuManagement = '/menu';
  static const String orderManagement = '/orders';
  static const String orderDetails = '/order/:id';
  static const String profile = '/profile';
}

// Router configuration;
// final GoRouter _router = GoRouter(
//   routes: [
//     GoRoute(
//       path: Routes.splash,
//       builder: (context, state) => const SplashScreen(),
//     ),
    //     GoRoute(
    //       path: Routes.login,
    //       builder: (context, state) => const LoginScreen(),
    //     ),
    //     GoRoute(
    //       path: Routes.dashboard,
    //       builder: (context, state) => const DashboardScreen(),
    //     ),
    //     GoRoute(
    //       path: Routes.menuManagement,
    //       builder: (context, state) => const MenuManagementScreen(),
    //     ),
    //     GoRoute(
    //       path: Routes.orderManagement,
    //       builder: (context, state) => const OrderManagementScreen(),
    //     ),
    //     GoRoute(
    //       path: Routes.orderDetails,
    //       builder: (context, state) {
    //         final orderId = state.pathParameters['id'] ?? '';
    //         return OrderDetailsScreen(orderId: orderId);
    //       },
    //     ),
    //     GoRoute(
    //       path: Routes.profile,
    //       builder: (context, state) => const ProfileScreen(),
    //     ),
//   ],
//   initialLocation: Routes.splash,
// );
