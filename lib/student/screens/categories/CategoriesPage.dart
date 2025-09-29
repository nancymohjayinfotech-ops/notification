import 'package:flutter/material.dart';
import '../../services/categories_service.dart';
import '../../models/category.dart';
import 'SubCategories/SubcategoryPage.dart';
import '../../widgets/app_layout.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoriesService _categoriesService = CategoriesService();

  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await _categoriesService.getCategories();

      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories.where((category) {
          return category.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _refreshCategories() async {
    try {
      final categories = await _categoriesService.refreshCategories();
      setState(() {
        _categories = categories;
        _filteredCategories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh categories'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppLayout(
      title: 'Categories',
      currentIndex: 1, // Categories tab
      showBackButton: true,
      showBottomNavigation: false, // Hide bottom navigation
      showHeaderActions: false, // Hide header icons
      child: Container(
        color: isDark ? Colors.grey[900] : Colors.white,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5F299E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading categories...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshCategories,
                color: const Color(0xFF5F299E),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Banner Section
                      _buildFeaturedBanner(isDark),
                      const SizedBox(height: 24),

                      // Search Bar
                      _buildSearchBar(isDark),
                      const SizedBox(height: 20),

                      // Categories Count
                      Text(
                        '${_filteredCategories.length} categories available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Categories Grid
                      _buildCategoriesGrid(isDark),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFeaturedBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learning & Development',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essentials For All Your Skills With Our Comprehensive Courses',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EXPLORE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.school, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDark ? 0.3 : 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterCategories,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search categories...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterCategories('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Responsive Categories Grid
  Widget _buildCategoriesGrid(bool isDark) {
    if (_filteredCategories.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No categories found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3; // Default mobile (>370px)

        if (constraints.maxWidth > 1200) {
          crossAxisCount = 5; // Desktop/Web (>=1200px)
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 4; // Tablet (801px - 1200px)
        } else if (constraints.maxWidth <= 370) {
          crossAxisCount = 2; // Small screens (<=370px) - 2 categories per row
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisCount == 2
                ? 12
                : 16, // Smaller spacing for 2-column layout
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 2
                ? 1.0
                : 0.85, // Better aspect ratio for 2-column
          ),
          itemCount: _filteredCategories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(
              _filteredCategories[index],
              constraints.maxWidth,
              isDark,
            );
          },
        );
      },
    );
  }

  /// Category Card with Responsive Font Sizes
  Widget _buildCategoryCard(
    CategoryModel category,
    double screenWidth,
    bool isDark,
  ) {
    double nameFontSize = 12;
    double courseFontSize = 11;
    double iconSize = 28;

    // Mobile (<=800px)
    if (screenWidth <= 800) {
      nameFontSize = 12;
      courseFontSize = 11;
      iconSize = 28;
    }
    // Tablet (801px - 1200px)
    else if (screenWidth > 800 && screenWidth <= 1200) {
      nameFontSize = 16;
      courseFontSize = 14;
      iconSize = 32;
    }
    // Desktop/Web (>=1200px)
    else if (screenWidth > 1200) {
      nameFontSize = 20;
      courseFontSize = 18;
      iconSize = 36;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to subcategory page for this category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubcategoryPage(
              categoryName: category.name,
              categoryIcon: category.icon.toString(),
              categoryColor: category.color,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(isDark ? 0.4 : 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize + 22,
              height: iconSize + 22,
              decoration: BoxDecoration(
                color: category.color.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: category.color.withOpacity(isDark ? 0.4 : 0.25),
                  width: 0.8,
                ),
              ),
              child: Icon(category.icon, size: iconSize, color: category.color),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: TextStyle(
                fontSize: nameFontSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${category.courseCount} courses',
              style: TextStyle(
                fontSize: courseFontSize,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
