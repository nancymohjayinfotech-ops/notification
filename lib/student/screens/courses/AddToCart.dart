import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertest/student/services/cart_api_service.dart';

// Simple Cart Item Model
class CartItem {
  final String courseTitle;
  final String courseAuthor;
  final String courseImage;
  final String coursePrice;
  final double rating;
  final String students;

  CartItem({
    required this.courseTitle,
    required this.courseAuthor,
    required this.courseImage,
    required this.coursePrice,
    required this.rating,
    required this.students,
  });
}

// Simple Cart Service
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _cartItems = [];
  final List<VoidCallback> _listeners = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartCount => _cartItems.length;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void addToCart(CartItem item) {
    // Check if item already exists
    bool exists = _cartItems.any(
      (cartItem) =>
          cartItem.courseTitle == item.courseTitle &&
          cartItem.courseAuthor == item.courseAuthor,
    );

    if (!exists) {
      _cartItems.add(item);
      _notifyListeners();
    }
  }

  void removeFromCart(CartItem item) {
    _cartItems.removeWhere(
      (cartItem) =>
          cartItem.courseTitle == item.courseTitle &&
          cartItem.courseAuthor == item.courseAuthor,
    );
    _notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _notifyListeners();
  }

  bool isInCart(String courseTitle, String courseAuthor) {
    return _cartItems.any(
      (cartItem) =>
          cartItem.courseTitle == courseTitle &&
          cartItem.courseAuthor == courseAuthor,
    );
  }
}

class AddToCartPage extends StatefulWidget {
  final String courseTitle;
  final String courseAuthor;
  final String courseImage;
  final String coursePrice;
  final double rating;
  final String students;
  final String? courseId;

  const AddToCartPage({
    super.key,
    required this.courseTitle,
    required this.courseAuthor,
    required this.courseImage,
    required this.coursePrice,
    this.rating = 4.8,
    this.students = '2.5k',
    this.courseId,
  });

  @override
  State<AddToCartPage> createState() => _AddToCartPageState();
}

class _AddToCartPageState extends State<AddToCartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAddedToCart = false;

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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addToCart() async {
    HapticFeedback.mediumImpact();

    if (widget.courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course ID is missing. Cannot add to cart.'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    setState(() {
      _isAddedToCart = true;
    });

    // Use CartApiService to add to cart
    final cartApiService = Provider.of<CartApiService>(context, listen: false);
    bool success = await cartApiService.add(widget.courseId!);

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.courseTitle} added to cart!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add course to cart. Please try again.'),
          backgroundColor: Colors.red[600],
        ),
      );
    }

    // Reset after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAddedToCart = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, isDark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  _buildCourseCard(theme, isDark),
                  SizedBox(height: 24),
                  _buildPriceSection(theme, isDark),
                  SizedBox(height: 24),
                  _buildCourseFeatures(theme, isDark),
                  SizedBox(height: 24),
                  _buildWhatYouGetSection(theme, isDark),
                  SizedBox(height: 32),
                  _buildAddToCartButton(theme, isDark),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: const Color(0xFF5F299E), // Always use this color
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Add to Cart',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCourseCard(ThemeData theme, bool isDark) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Color(0xFF5F299E).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.courseImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary,
                                  ]
                                : [Color(0xFF5F299E), Color(0xFF5F299E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 40,
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
                      widget.courseTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.courseAuthor,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                widget.rating.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '${widget.students} students',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5F299E),
            Color(0xFF5F299E),
          ], // Always use this color
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5F299E).withOpacity(0.3), // Always use this color
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 8),
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
                'Course Price',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                widget.coursePrice,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.attach_money_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseFeatures(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.featured_play_list_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Course Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildFeatureItem(
            theme,
            isDark,
            Icons.access_time_rounded,
            '4+ Hours',
            'Video Content',
          ),
          SizedBox(height: 12),
          _buildFeatureItem(
            theme,
            isDark,
            Icons.download_rounded,
            'Downloadable',
            'Resources & Files',
          ),
          SizedBox(height: 12),
          _buildFeatureItem(
            theme,
            isDark,
            Icons.card_membership_rounded,
            'Certificate',
            'Upon Completion',
          ),
          SizedBox(height: 12),
          _buildFeatureItem(
            theme,
            isDark,
            Icons.all_inclusive_rounded,
            'Lifetime',
            'Access',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatYouGetSection(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFF5F299E,
          ).withOpacity(0.2), // Always use this color
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF5F299E),
                      Color(0xFF5F299E),
                    ], // Always use this color
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'What You\'ll Get',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildBenefitItem(theme, isDark, '45+ HD Video Lessons'),
          _buildBenefitItem(theme, isDark, 'Downloadable Resources'),
          _buildBenefitItem(theme, isDark, 'Quizzes & Assignments'),
          _buildBenefitItem(theme, isDark, 'Certificate of Completion'),
          _buildBenefitItem(theme, isDark, 'Lifetime Access'),
          _buildBenefitItem(theme, isDark, 'Mobile & Desktop Access'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(ThemeData theme, bool isDark, String benefit) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.green[600], size: 14),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isAddedToCart ? null : _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isAddedToCart
              ? Colors.green[600]
              : const Color(0xFF5F299E), // Always use this color
          foregroundColor: Colors.white,
          elevation: _isAddedToCart ? 8 : 12,
          shadowColor: _isAddedToCart
              ? Colors.green.withOpacity(0.4)
              : const Color(
                  0xFF5F299E,
                ).withOpacity(0.4), // Always use this color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _isAddedToCart
              ? Row(
                  key: ValueKey('added'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Added to Cart!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: ValueKey('add'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Add to Cart',
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
}
