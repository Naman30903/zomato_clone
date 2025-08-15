import 'package:feastly_restaurant/bloc/incoming_order_bloc.dart';
import 'package:feastly_restaurant/bloc/menu_mgmt_bloc.dart';
import 'package:feastly_restaurant/bloc/order_action_bloc.dart';
import 'package:feastly_restaurant/screens/home_screen.dart';
import 'package:feastly_restaurant/screens/menu_mgmt_screen.dart';
import 'package:feastly_restaurant/screens/order_details_screen.dart';
import 'package:feastly_restaurant/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

void main() {
  runApp(const FeastlyRestaurantApp());
}

class FeastlyRestaurantApp extends StatelessWidget {
  const FeastlyRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OrderRepo>(create: (_) => MockOrderRepo()),
        RepositoryProvider<MenuRepo>(create: (_) => MockMenuRepo()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<IncomingOrdersBloc>(
            create: (context) =>
                IncomingOrdersBloc(orderRepo: context.read<OrderRepo>())
                  ..add(const StartWatchingIncomingOrders('rest_1')),
          ),
          BlocProvider<OrderActionsBloc>(
            create: (context) =>
                OrderActionsBloc(orderRepo: context.read<OrderRepo>()),
          ),
          BlocProvider<MenuMgmtBloc>(
            create: (context) =>
                MenuMgmtBloc(menuRepo: context.read<MenuRepo>()),
          ),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Feastly Restaurant',
          theme: ThemeGenerator.restaurantTheme(isDark: false),
          darkTheme: ThemeGenerator.restaurantTheme(isDark: true),
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
  static const String menuManagement = '/menu';
  static const String orderManagement = '/orders';
  static const String orderDetails = '/order/:id';
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
      path: Routes.orderDetails,
      builder: (context, state) {
        final orderId = state.pathParameters['id'] ?? '';
        return OrderDetailsScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: Routes.menuManagement,
      builder: (context, state) => MenuManagementScreen(restaurantId: 'rest_1'),
    ),
    // GoRoute(
    //   path: '/menu/add',
    //   builder: (context, state) => const AddEditMenuItemScreen(isEditing: false),
    // ),
    // GoRoute(
    //   path: '/menu/edit/:id',
    //   builder: (context, state) {
    //     final menuItemId = state.pathParameters['id'] ?? '';
    //     return AddEditMenuItemScreen(isEditing: true, menuItemId: menuItemId);
    //   },
    // ),
    //     GoRoute(
    //       path: Routes.profile,
    //       builder: (context, state) => const ProfileScreen(),
    //     ),
  ],
  initialLocation: Routes.splash,
);
