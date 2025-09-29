import 'package:flutter/material.dart';
import '../services/categories_service.dart';
import 'SubcategoryPage.dart';
import '../widgets/app_layout.dart';

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
        SnackBar(
          content: Text('Failed to refresh categories'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // void _showSearchDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Search Categories'),
  //         content: TextField(
  //           controller: _searchController,
  //           onChanged: _filterCategories,
  //           decoration: InputDecoration(
  //             hintText: 'Enter category name...',
  //             prefixIcon: Icon(Icons.search),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //           ),
  //           autofocus: true,
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               _searchController.clear();
  //               _filterCategories('');
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Clear'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Categories',
      currentIndex: 1, // Categories tab
      showBackButton: true,
      showBottomNavigation: false, // Hide bottom navigation
      showHeaderActions: false, // Hide header icons

      child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF5F299E),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading categories...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshCategories,
              color: Color(0xFF5F299E),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Banner Section
                    _buildFeaturedBanner(),
                    SizedBox(height: 24),

                    // Search Bar
                    _buildSearchBar(),
                    SizedBox(height: 20),

                    // Categories Count
                    Text(
                      '${_filteredCategories.length} categories available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Categories Grid
                    _buildCategoriesGrid(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeaturedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE91E63).withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning & Development',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Essentials For All Your Skills With Our Comprehensive Courses',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.yellow[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
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
          SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(Icons.school, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterCategories,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _searchController.clear();
                    _filterCategories('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    if (_filteredCategories.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No categories found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your search',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(_filteredCategories[index]);
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(category.icon, size: 28, color: category.color),
            ),
            SizedBox(height: 12),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              '${category.courseCount} courses',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Category Model Class
class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;
  final int courseCount;

  CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.courseCount,
  });

  // For future API integration
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'category'),
      color: Color(json['color'] ?? 0xFF5F299E),
      courseCount: json['courseCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'courseCount': courseCount,
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'marketing':
      case 'campaign':
        return Icons.campaign;
      case 'design':
      case 'ui':
      case 'ux':
        return Icons.design_services;
      case 'flutter':
      case 'mobile':
        return Icons.phone_android;
      case 'devops':
      case 'cloud':
        return Icons.cloud;
      case 'data':
      case 'analytics':
        return Icons.analytics;
      case 'testing':
      case 'bug':
        return Icons.bug_report;
      case 'web':
        return Icons.web;
      case 'ml':
      case 'ai':
        return Icons.psychology;
      case 'business':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
}
