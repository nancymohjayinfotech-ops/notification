import 'package:flutter/material.dart';
import '../../../widgets/app_layout.dart';
import '../../../models/category.dart';
import '../../../services/categories_service.dart';
import '../../courses/AllCoursesPage.dart';

class SubcategoryPage extends StatefulWidget {
  final String categoryName;
  final String? categoryId;
  final String categoryIcon;
  final Color categoryColor;

  const SubcategoryPage({
    super.key,
    required this.categoryName,
    this.categoryId,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<SubcategoryPage> createState() => _SubcategoryPageState();
}

class _SubcategoryPageState extends State<SubcategoryPage> {
  final CategoriesService _categoriesService = CategoriesService();
  List<Subcategory> _subcategories = [];
  bool _isLoading = true;
  String? _errorMessage;
  // Removed quiz toggle - only showing courses now

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First, get the category to find its ID if not provided
      String? categoryId = widget.categoryId;

      if (categoryId == null) {
        // Find category by name
        final categories = await _categoriesService.getAllCategories();
        final category = categories.firstWhere(
          (cat) => cat.name.toLowerCase() == widget.categoryName.toLowerCase(),
          orElse: () => throw Exception('Category not found'),
        );
        categoryId = category.id!;
      }

      final subcategories = await _categoriesService.getSubcategories(
        categoryId,
      );

      setState(() {
        _subcategories = subcategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subcategories: ${e.toString()}';
        _isLoading = false;
        // Fallback to mock data
        _subcategories = _getFallbackSubcategories(widget.categoryName);
      });
    }
  }

  Future<void> _refreshSubcategories() async {
    await _loadSubcategories();
  }

  // Card builder
  Widget _buildItemCard(Map<String, dynamic> item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
        border: isDark ? Border.all(color: Colors.grey[700]!) : null,
      ),
      child: InkWell(
        onTap: () {
          final sub = _subcategories.firstWhere(
            (s) => s.name == item['name'],
            orElse: () => Subcategory(name: item['name'], description: ''),
          );
          if (sub.id != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AllCoursesPage(
                  selectedLanguage: 'en',
                  subcategoryId: sub.id,
                  subcategoryName: sub.name,
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            // Icon container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item['color'].withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Builder(
                  builder: (context) {
                    final sub = _subcategories.firstWhere(
                      (s) => s.name == item['name'],
                      orElse: () =>
                          Subcategory(name: item['name'], description: ''),
                    );
                    return Icon(sub.iconData, color: item['color'], size: 28);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subcategoriesData = _subcategories
        .map((subcat) => _convertToMap(subcat))
        .toList();

    return AppLayout(
      title: widget.categoryName,
      currentIndex: 1, // Categories tab
      showBackButton: true,
      showBottomNavigation: false, // Hide bottom navigation
      showHeaderActions: false, // Hide header icons
      child: _isLoading
          ? _buildLoadingState(isDark)
          : _errorMessage != null
          ? _buildErrorState(isDark)
          : Container(
              color: isDark ? Colors.grey[900] : Colors.white,
              child: Column(
                children: [
                  // Header with toggle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [Colors.grey[900]!, Colors.grey[800]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF5F299E), Color(0xFF7B68EE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    ),
                    child: Column(
                      children: [
                        // Category title
                        Text(
                          widget.categoryName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subcategories list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshSubcategories,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                      color: isDark ? Colors.white70 : const Color(0xFF5F299E),
                      child: _buildSubcategoriesContent(
                        subcategoriesData,
                        isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white70 : const Color(0xFF5F299E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading subcategories...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red[300] : Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSubcategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.grey[700]
                  : const Color(0xFF5F299E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoriesContent(
    List<Map<String, dynamic>> subcategories,
    bool isDark,
  ) {
    return subcategories.isEmpty
        ? _buildEmptyState(isDark)
        : Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                return _buildItemCard(subcategories[index], isDark);
              },
            ),
          );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No subcategories found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This category doesn\'t have any subcategories yet',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Convert Subcategory to Map for UI compatibility
  Map<String, dynamic> _convertToMap(Subcategory subcategory) {
    // Generate a color based on the subcategory name for consistency
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECA57),
      const Color(0xFF6C5CE7),
      const Color(0xFFE17055),
      const Color(0xFF00B894),
      const Color(0xFF0984E3),
    ];
    final colorIndex = subcategory.name.hashCode % colors.length;

    return {
      'name': subcategory.name,
      'color': subcategory.backgroundColor.isNotEmpty
          ? subcategory.colorValue
          : colors[colorIndex.abs()],
      'icon': subcategory.icon.isNotEmpty ? subcategory.icon : '📚',
    };
  }

  // Fallback subcategories for offline mode
  List<Subcategory> _getFallbackSubcategories(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'digital marketing':
        return [
          Subcategory(
            name: 'SEO Optimization',
            description: 'Search Engine Optimization',
            icon: '🔍',
          ),
          Subcategory(
            name: 'Social Media Marketing',
            description: 'Social platforms marketing',
            icon: '📱',
          ),
          Subcategory(
            name: 'Email Marketing',
            description: 'Email campaign strategies',
            icon: '📧',
          ),
          Subcategory(
            name: 'Content Marketing',
            description: 'Content creation and strategy',
            icon: '📝',
          ),
        ];
      case 'ui/ux design':
        return [
          Subcategory(
            name: 'User Interface Design',
            description: 'UI design principles',
            icon: '🎨',
          ),
          Subcategory(
            name: 'User Experience',
            description: 'UX research and design',
            icon: '👤',
          ),
          Subcategory(
            name: 'Prototyping',
            description: 'Design prototyping tools',
            icon: '🔧',
          ),
          Subcategory(
            name: 'Design Systems',
            description: 'Component libraries',
            icon: '📐',
          ),
        ];
      case 'flutter development':
        return [
          Subcategory(
            name: 'Flutter Basics',
            description: 'Getting started with Flutter',
            icon: '📱',
          ),
          Subcategory(
            name: 'State Management',
            description: 'Managing app state',
            icon: '⚙️',
          ),
          Subcategory(
            name: 'UI Components',
            description: 'Building beautiful UIs',
            icon: '🎨',
          ),
          Subcategory(
            name: 'API Integration',
            description: 'Connecting to APIs',
            icon: '🔗',
          ),
        ];
      default:
        return [
          Subcategory(
            name: 'Getting Started',
            description: 'Introduction to $categoryName',
            icon: '🚀',
          ),
          Subcategory(
            name: 'Advanced Topics',
            description: 'Advanced $categoryName concepts',
            icon: '🎯',
          ),
        ];
    }
  }
}
