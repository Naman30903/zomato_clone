import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
// import 'screens/login_screen.dart';
// import 'screens/splash_screen.dart';
// import 'screens/home_screen.dart';
// import 'screens/order_details_screen.dart';
// import 'screens/navigation_screen.dart';
// import 'screens/profile_screen.dart';

void main() {
  runApp(const FeastlyDeliveryApp());
}

class FeastlyDeliveryApp extends StatelessWidget {
  const FeastlyDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Feastly Delivery',
      theme: ThemeGenerator.deliveryTheme(isDark: false),
      darkTheme: ThemeGenerator.deliveryTheme(isDark: true),
      themeMode: ThemeMode.system,
      // routerConfig: _router,
    );
  }
}

// Define route names as constants
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String orderDetails = '/order/:id';
  static const String navigation = '/navigation/:orderId';
  static const String profile = '/profile';
}

// Router configuration
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
//       path: Routes.home,
//       builder: (context, state) => const HomeScreen(),
//     ),
//     GoRoute(
//       path: Routes.orderDetails,
//       builder: (context, state) {
//         final orderId = state.pathParameters['id'] ?? '';
//         return OrderDetailsScreen(orderId: orderId);
//       },
//     ),
//     GoRoute(
//       path: Routes.navigation,
//       builder: (context, state) {
//         final orderId = state.pathParameters['orderId'] ?? '';
//         return NavigationScreen(orderId: orderId);
//       },
//     ),
//     GoRoute(
//       path: Routes.profile,
//       builder: (context, state) => const ProfileScreen(),
//     ),
//   ],
//   initialLocation: Routes.splash,
// );
