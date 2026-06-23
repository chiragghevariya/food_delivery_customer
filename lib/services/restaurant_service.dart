import 'package:dio/dio.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import 'api_service.dart';

/// Talks to the public restaurant + category endpoints.
class RestaurantService {
  final Dio _dio = ApiService.instance.dio;

  /// GET /api/restaurants  (with optional search + category filter)
  Future<List<Restaurant>> getRestaurants({String? search, int? categoryId}) async {
    final res = await _dio.get('/restaurants', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category': categoryId,
    });
    // The list endpoint is paginated, so the array is under "data".
    final list = res.data['data'] as List;
    return list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/restaurants/{id}  (includes the menu items)
  Future<Restaurant> getRestaurant(int id) async {
    final res = await _dio.get('/restaurants/$id');
    return Restaurant.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/categories
  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/categories');
    final list = res.data['data'] as List;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }
}
