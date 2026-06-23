import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../utils/error_utils.dart';

/// Fetches and holds the restaurant list + category list, plus the
/// current search text and selected category filter.
class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _service = RestaurantService();

  List<Restaurant> _restaurants = [];
  List<Category> _categories = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  int? _selectedCategoryId;

  List<Restaurant> get restaurants => _restaurants;
  List<Category> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  int? get selectedCategoryId => _selectedCategoryId;

  /// Load categories + restaurants together (called once on the home screen).
  Future<void> loadInitial() async {
    await Future.wait([loadCategories(), loadRestaurants()]);
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (_) {
      // categories are optional for browsing — ignore failures here
    }
  }

  Future<void> loadRestaurants() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _restaurants = await _service.getRestaurants(
        search: _search,
        categoryId: _selectedCategoryId,
      );
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    loadRestaurants();
  }

  /// Tap a chip to select it; tap it again to clear the filter.
  void selectCategory(int? categoryId) {
    _selectedCategoryId = (_selectedCategoryId == categoryId) ? null : categoryId;
    notifyListeners();
    loadRestaurants();
  }
}
