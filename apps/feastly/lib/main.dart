import 'package:feastly/bloc/cart_bloc.dart';
import 'package:feastly/bloc/menu_bloc.dart';
import 'package:feastly/bloc/order_bloc.dart';
import 'package:feastly/bloc/order_history_bloc.dart';
import 'package:feastly/bloc/restuartant_list_bloc.dart';
import 'package:feastly/screens/cart_screen.dart';
import 'package:feastly/screens/home_screen.dart';
import 'package:feastly/screens/order_history_screen.dart';
import 'package:feastly/screens/order_tracking-screen.dart';
import 'package:feastly/screens/profile_screen.dart';
import 'package:feastly/screens/restaurant_detail_screen.dart';
import 'package:feastly/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

void main() {
  runApp(const FeastlyApp());
}

class FeastlyApp extends StatelessWidget {
  const FeastlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<RestaurantRepo>(create: (_) => MockRestaurantRepo()),
        RepositoryProvider<MenuRepo>(create: (_) => MockMenuRepo()),
        RepositoryProvider<OrderRepo>(create: (_) => MockOrderRepo()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RestaurantListBloc>(
            create: (context) => RestaurantListBloc(
              restaurantRepo: context.read<RestaurantRepo>(),
            )..add(const FetchRestaurants()),
          ),
          BlocProvider<MenuBloc>(
            create: (context) => MenuBloc(
              menuRepo: context.read<MenuRepo>(),
              restaurantRepo: context.read<RestaurantRepo>(),
            ),
          ),
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(
              orderRepo: context.read<OrderRepo>(),
              restaurantRepo: context.read<RestaurantRepo>(),
            ),
          ),
          BlocProvider<OrderBloc>(
            create: (context) =>
                OrderBloc(orderRepo: context.read<OrderRepo>()),
          ),
          BlocProvider<OrderHistoryBloc>(
            create: (context) =>
                OrderHistoryBloc(orderRepo: context.read<OrderRepo>()),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Feastly',
          theme: ThemeGenerator.customerTheme(isDark: false),
          darkTheme: ThemeGenerator.customerTheme(isDark: true),
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
    GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: Routes.restaurant,
      builder: (context, state) {
        final restaurantId = state.pathParameters['id'] ?? '';
        return RestaurantDetailScreen(restaurantId: restaurantId);
      },
    ),
    GoRoute(path: Routes.cart, builder: (context, state) => const CartScreen()),
    GoRoute(
      path: Routes.orderTracking,
      builder: (context, state) {
        final orderId = state.pathParameters['id'] ?? '';
        return OrderTrackingScreen();
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: Routes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  initialLocation: Routes.splash,
);
