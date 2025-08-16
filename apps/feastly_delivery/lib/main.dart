import 'package:feastly_delivery/bloc/delivery_auth_bloc.dart';
import 'package:feastly_delivery/bloc/delivery_order_bloc.dart';
import 'package:feastly_delivery/bloc/delivery_status_bloc.dart';
import 'package:feastly_delivery/screens/assigned_order_screen.dart';
import 'package:feastly_delivery/screens/home_screen.dart';
import 'package:feastly_delivery/screens/login_screen.dart';
import 'package:feastly_delivery/screens/signup_screen.dart';
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
        RepositoryProvider<AuthRepo>(create: (_) => FirebaseAuthRepo()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepo: context.read<AuthRepo>())..add(AppStarted()),
          ),
          BlocProvider<DeliveryOrderBloc>(
            create: (context) =>
                DeliveryOrderBloc(orderRepo: context.read<OrderRepo>()),
          ),
          BlocProvider<DeliveryStatusBloc>(
            create: (context) =>
                DeliveryStatusBloc(orderRepo: context.read<OrderRepo>()),
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return MaterialApp.router(
              title: 'Feastly Delivery',
              theme: ThemeGenerator.deliveryTheme(isDark: false),
              darkTheme: ThemeGenerator.deliveryTheme(isDark: true),
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
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const DeliveryLoginScreen(),
    ),
    GoRoute(
      path: Routes.signup,
      builder: (context, state) => const DeliverySignupScreen(),
    ),
    GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: Routes.orderDetails,
      builder: (context, state) {
        final orderId = state.pathParameters['id'] ?? '';
        return AssignedOrderScreen(orderId: orderId);
      },
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
