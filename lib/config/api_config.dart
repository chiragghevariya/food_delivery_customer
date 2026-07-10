/// Central place for the API connection settings.
class ApiConfig {
  /// Base URL of the Laravel API.
  ///
  /// Pick the right host for where you run the app:
  ///   - Android emulator:        http://10.0.2.2:8000/api   (10.0.2.2 = your PC's localhost)
  ///   - iOS simulator / web:     http://127.0.0.1:8000/api
  ///   - Real phone (same wifi):  http://<YOUR-PC-IP>:8000/api  e.g. http://192.168.1.20:8000/api
  ///   - Laragon virtual host:    http://food-delivery.test/api
  ///
  /// Start the backend with:  php artisan serve   (defaults to port 8000)
  static const String baseUrl = 'http://192.168.1.10:8000/api';

  static const String stripePublishableKey = 'pk_test_51SaXt3Be7lcgzOrDgqNNn0AYmjrp7T0nZbPreRD8NUTTi4t3ykiALBmewLMQPdGSGqL3rixcqujuDJKciUiG87gd00epUc9GJp';
  static const String googleMapsApiKey = 'AIzaSyBmIEJSOtppzhwY8ADACmFpj-VH8k9DOh8';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Headers sent with every request.
  static Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
}
