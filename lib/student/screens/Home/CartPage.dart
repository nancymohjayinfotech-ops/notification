import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertest/student/services/cart_api_service.dart';
import 'package:fluttertest/student/models/course.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CartApiService _cartApiService;
  bool _isLoading = false;
  bool _hasInitialized = false; // Track if cart has been loaded
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cartApiService = Provider.of<CartApiService>(context);
    _cartApiService.addListener(_onCartChanged);
    // Only load cart once when page is first opened
    if (!_hasInitialized) {
      _hasInitialized = true;
      _loadCart();
    }
  }

  void _loadCart() async {
    if (_cartApiService.isLoading)
      return; // Prevent multiple simultaneous calls

    setState(() {
      _isLoading = true;
    });
    await _cartApiService.fetchCart();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _cartApiService.removeListener(_onCartChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      debugPrint(
        '🔄 Cart changed - Items count: ${_cartApiService.items.length}',
      );
      debugPrint('🔄 Cart items: ${_cartApiService.items}');
      setState(() {});
    }
  }

  void _removeFromCart(Course course) async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    bool success = await _cartApiService.remove(course.id ?? '');

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.remove_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${course.title} removed from cart!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove course from cart'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var item in _cartApiService.items) {
      if (item is Map<String, dynamic>) {
        // Check for nested course structure first
        final course = item['course'] ?? item;
        if (course['price'] != null) {
          total += (course['price'] as num).toDouble();
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🏗️ Building CartPage - Loading: $_isLoading, Items: ${_cartApiService.items.length}, IsEmpty: ${_cartApiService.items.isEmpty}',
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _cartApiService.items.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
        ),
      ),
      bottomNavigationBar: _cartApiService.items.isNotEmpty
          ? _buildCheckoutButton()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF5F299E),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'My Cart (${_cartApiService.cartCount})',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (_cartApiService.items.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {
              _showClearCartDialog();
            },
          ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : Color(0xFF5F299E);
    final Color bgColor = isDark
        ? Color(0xFF5F299E).withOpacity(0.18)
        : Color(0xFF5F299E).withOpacity(0.1);
    final Color textColor = isDark ? Colors.black : Colors.white;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: iconColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Add some courses to get started!',
            style: TextStyle(fontSize: 16, color: subTextColor),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5F299E),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Courses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _cartApiService.items.length,
            itemBuilder: (context, index) {
              final item = _cartApiService.items[index];
              return _buildCartItem(item, index);
            },
          ),
        ),
        _buildTotalSection(),
      ],
    );
  }

  Widget _buildCartItem(dynamic item, int index) {
    // Extract course data from the nested structure
    final course =
        item['course'] ?? item; // Fallback to item if course is not nested
    final courseTitle = course['title'] ?? 'Course Title';
    final coursePrice = (course['price'] as num?)?.toDouble() ?? 0.0;
    final instructorName = course['instructor']?['name'] ?? 'Instructor';
    final courseImage = course['thumbnail'] ?? course['image'] ?? '';
    final courseRating = (course['averageRating'] as num?)?.toDouble() ?? 0.0;
    final courseId = course['_id'] ?? course['id'] ?? '';

    debugPrint(
      '🎯 Rendering cart item - Title: $courseTitle, Price: $coursePrice, Instructor: $instructorName',
    );

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF5F299E).withValues(alpha: 0.2),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  courseImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            // Course Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    instructorName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F299E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xFF5F299E),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        courseRating.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F299E),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Text(
                      //   '0 students', // TODO: Add student count from API
                      //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
            // Price and Remove Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${coursePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5F299E),
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Create a Course object from the cart item
                    final courseObj = Course(
                      id: courseId,
                      title: courseTitle,
                      price: coursePrice,
                    );
                    _removeFromCart(courseObj);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final total = _calculateTotal();
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5F299E),
                ),
              ),
            ],
          ),
          Text(
            '${_cartApiService.cartCount} item${_cartApiService.cartCount != 1 ? 's' : ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            _showCheckoutDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF5F299E),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: Color(0xFF5F299E).withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment_rounded, size: 24),
              SizedBox(width: 8),
              Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear Cart',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to remove all items from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                // Clear cart via API - remove all items individually
                for (var item in List.from(_cartApiService.items)) {
                  await _cartApiService.remove(item['_id'] ?? '');
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cart cleared successfully!'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.payment_rounded, color: Color(0xFF5F299E)),
              SizedBox(width: 8),
              Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: \$${_calculateTotal().toStringAsFixed(2)}'),
              SizedBox(height: 8),
              Text('Items: ${_cartApiService.cartCount}'),
              SizedBox(height: 16),
              Text(
                'This is a demo. In a real app, this would proceed to payment.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Clear cart via API - remove all items individually
                for (var item in List.from(_cartApiService.items)) {
                  await _cartApiService.remove(item['_id'] ?? '');
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order placed successfully! (Demo)'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5F299E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Place Order'),
            ),
          ],
        );
      },
    );
  }
}
