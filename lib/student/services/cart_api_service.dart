import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class CartApiService with ChangeNotifier {
  static final CartApiService _instance = CartApiService._internal();
  factory CartApiService() => _instance;
  CartApiService._internal();

  final ApiClient _apiClient = ApiClient();

  int _cartCount = 0;
  List<dynamic> _items = [];
  String? _error;
  bool _isLoading = false;

  int get cartCount => _cartCount;
  List<dynamic> get items => List.unmodifiable(_items);
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> fetchCart() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('🛒 Fetching cart items...');
      final response = await _apiClient.get<Map<String, dynamic>>(ApiConfig.cart);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('🔍 Raw cart API response: $data');

        if (data['success'] == true) {
          // Check different possible cart data structures
          List<dynamic> cartItems = [];
          
          if (data['data'] != null && 
              data['data']['cart'] != null && 
              data['data']['cart']['items'] != null) {
            // New API structure: data.data.cart.items
            cartItems = (data['data']['cart']['items'] as List<dynamic>? ?? []);
            debugPrint('📦 Found cart items in data["data"]["cart"]["items"]: ${cartItems.length} items');
          } else if (data['cart'] != null && data['cart'] is List) {
            // Old structure: data.cart (direct list)
            cartItems = (data['cart'] as List<dynamic>? ?? []);
            debugPrint('📦 Found cart items in data["cart"]: ${cartItems.length} items');
          } else if (data['data'] != null && data['data']['cart'] != null && data['data']['cart'] is List) {
            // Alternative structure: data.data.cart (direct list)
            cartItems = (data['data']['cart'] as List<dynamic>? ?? []);
            debugPrint('📦 Found cart items in data["data"]["cart"]: ${cartItems.length} items');
          } else if (data['items'] != null) {
            // Direct items structure
            cartItems = (data['items'] as List<dynamic>? ?? []);
            debugPrint('📦 Found cart items in data["items"]: ${cartItems.length} items');
          } else {
            debugPrint('⚠️ No cart items found in expected fields. Available keys: ${data.keys.toList()}');
            if (data['data'] != null) {
              debugPrint('⚠️ data["data"] keys: ${(data['data'] as Map).keys.toList()}');
              if (data['data']['cart'] != null) {
                debugPrint('⚠️ data["data"]["cart"] keys: ${(data['data']['cart'] as Map).keys.toList()}');
              }
            }
          }
          
          _items = cartItems;
          _cartCount = _items.length;
          debugPrint('✅ Successfully loaded $_cartCount cart items');

          // If cart is empty, don't show error - just empty state
          if (_items.isEmpty) {
            debugPrint('📭 Cart is empty - showing empty state');
          }
        } else {
          // Only set error if it's not an empty cart scenario
          final message = data['message'] ?? 'Failed to load cart';
          if (!message.toLowerCase().contains('empty') && !message.toLowerCase().contains('no items')) {
            _error = message;
            debugPrint('❌ Failed to load cart: $_error');
          } else {
            // Cart is empty, clear items and show empty state
            _items = [];
            _cartCount = 0;
            debugPrint('📭 Cart is empty');
          }
        }
      } else {
        // Handle different error scenarios
        if (response.error?.code == 404) {
          // Cart not found - treat as empty cart
          _items = [];
          _cartCount = 0;
          debugPrint('📭 Cart not found - treating as empty');
        } else if (response.error?.code == 403) {
          _error = 'Access denied. Please check your permissions.';
          debugPrint('❌ Access denied');
        } else {
          _error = response.error?.message ?? 'Failed to load cart';
          debugPrint('❌ API request failed: $_error');
        }
      }
    } catch (e) {
      _error = 'Error loading cart: $e';
      debugPrint('❌ Error in fetchCart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add(String courseId) async {

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('➕ Adding item $courseId to cart...');
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.addToCart,
        data: {'courseId': courseId},
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        if (data['success'] == true) {
          await fetchCart();
          return true;
        } else {
          _error = data['message'] ?? 'Failed to add to cart';
          debugPrint('❌ Failed to add to cart: $_error');
        }
      } else {
        _error = response.error?.message ?? 'Failed to add to cart';
        debugPrint('❌ API request failed: $_error');
      }
      return false;
    } catch (e) {
      _error = 'Error adding to cart: $e';
      debugPrint('❌ Error in add: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> remove(String courseId) async {

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('➖ Removing item $courseId from cart...');
      final response = await _apiClient.delete<Map<String, dynamic>>(
        ApiConfig.removeFromCart(courseId),
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        if (data['success'] == true) {
          await fetchCart();
          return true;
        } else {
          _error = data['message'] ?? 'Failed to remove from cart';
          debugPrint('❌ Failed to remove from cart: $_error');
        }
      } else {
        _error = response.error?.message ?? 'Failed to remove from cart';
        debugPrint('❌ API request failed: $_error');
      }
      return false;
    } catch (e) {
      _error = 'Error removing from cart: $e';
      debugPrint('❌ Error in remove: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
