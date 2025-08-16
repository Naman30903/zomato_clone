import 'package:feastly_delivery/bloc/delivery_order_bloc.dart';
import 'package:feastly_delivery/bloc/delivery_status_bloc.dart';
import 'package:feastly_delivery/screens/assigned_order_screen.dart';
import 'package:feastly_delivery/screens/home_screen.dart';
import 'package:feastly_delivery/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FeastlyDeliveryApp());
}

class FeastlyDeliveryApp extends StatelessWidget {
  const FeastlyDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrderRepo>(create: (_) => MockOrderRepo()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DeliveryOrderBloc>(
            create: (context) =>
                DeliveryOrderBloc(orderRepo: context.read<OrderRepo>()),
          ),
          BlocProvider<DeliveryStatusBloc>(
            create: (context) =>
                DeliveryStatusBloc(orderRepo: context.read<OrderRepo>()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Feastly Delivery',
          theme: ThemeGenerator.deliveryTheme(isDark: false),
          darkTheme: ThemeGenerator.deliveryTheme(isDark: true),
          themeMode: ThemeMode.system,
          routerConfig: _router,
        ),
      ),
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
    GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
    // GoRoute(
    //   path: Routes.orderDetails,
    //   builder: (context, state) {
    //     final orderId = state.pathParameters['id'] ?? '';
    //     return OrderDetailsScreen(orderId: orderId);
    //   },
    // ),
    GoRoute(
      path: Routes.orderDetails,
      builder: (context, state) {
        final orderId = state.pathParameters['id'] ?? '';
        return AssignedOrderScreen(orderId: orderId);
      },
    ),
    //     GoRoute(
    //       path: Routes.profile,
    //       builder: (context, state) => const ProfileScreen(),
    //     ),
  ],
  initialLocation: Routes.splash,
);
