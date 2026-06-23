import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/restaurant_provider.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/register_screen.dart';
import 'screens/restaurant_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // Needed before using plugins (notifications) before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.init();
  } catch (_) {
    // notifications are optional — ignore init errors (e.g. on web/desktop)
  }
  runApp(const FoodDeliveryApp());
}

class FoodDeliveryApp extends StatelessWidget {
  const FoodDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider makes our 3 providers available to the whole app.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
      ],
      child: MaterialApp(
        title: 'Food Delivery',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: Routes.splash,
        // Named routes. Screens that need an argument read it with
        // ModalRoute.of(context)!.settings.arguments.
        routes: {
          Routes.splash: (_) => const SplashScreen(),
          Routes.login: (_) => const LoginScreen(),
          Routes.register: (_) => const RegisterScreen(),
          Routes.home: (_) => const HomeScreen(),
          Routes.restaurantDetail: (_) => const RestaurantDetailScreen(),
          Routes.cart: (_) => const CartScreen(),
          Routes.orders: (_) => const OrdersScreen(),
          Routes.orderDetail: (_) => const OrderDetailScreen(),
        },
      ),
    );
  }
}
