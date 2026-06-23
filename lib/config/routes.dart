/// All named-route paths in one place (so we avoid typos).
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String restaurantDetail = '/restaurant'; // expects int restaurantId as argument
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail'; // expects int orderId as argument
}
