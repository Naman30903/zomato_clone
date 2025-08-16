import 'package:feastly_restaurant/bloc/incoming_order_bloc.dart';
import 'package:feastly_restaurant/bloc/menu_mgmt_bloc.dart';
import 'package:feastly_restaurant/bloc/order_action_bloc.dart';
import 'package:feastly_restaurant/bloc/restaurant_auth_bloc.dart';
import 'package:feastly_restaurant/screens/home_screen.dart';
import 'package:feastly_restaurant/screens/menu_mgmt_screen.dart';
import 'package:feastly_restaurant/screens/order_details_screen.dart';
import 'package:feastly_restaurant/screens/restaurant_signup_screen.dart';
import 'package:feastly_restaurant/screens/restuartant_login_screen.dart';
import 'package:feastly_restaurant/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        RepositoryProvider<AuthRepo>(create: (_) => FirebaseAuthRepo()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepo: context.read<AuthRepo>())..add(AppStarted()),
          ),
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
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Feastly Restaurant',
              theme: ThemeGenerator.restaurantTheme(isDark: false),
              darkTheme: ThemeGenerator.restaurantTheme(isDark: true),
              themeMode: ThemeMode.system,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}

// Define route names as constants
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
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
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const RestaurantLoginScreen(),
    ),
    GoRoute(
      path: Routes.signup,
      builder: (context, state) => const RestaurantSignupScreen(),
    ),
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
  ],
  initialLocation: Routes.splash,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final bool isLoggedIn = authState is Authenticated;

    final bool isGoingToLogin = state.matchedLocation == Routes.login;
    final bool isGoingToSignup = state.matchedLocation == Routes.signup;
    final bool isGoingToSplash = state.matchedLocation == Routes.splash;

    // If not logged in and not going to auth pages, redirect to login
    if (!isLoggedIn &&
        !isGoingToLogin &&
        !isGoingToSignup &&
        !isGoingToSplash) {
      return Routes.login;
    }

    // If logged in and going to auth pages, redirect to home
    if (isLoggedIn && (isGoingToLogin || isGoingToSignup)) {
      return Routes.home;
    }

    // No redirect needed
    return null;
  },
);
