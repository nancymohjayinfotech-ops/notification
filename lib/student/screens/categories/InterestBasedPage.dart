import 'package:flutter/material.dart';
import '../../services/categories_service.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../models/category.dart';
import 'SubCategories/SubcategorySelectPage.dart';

class InterestBasedPage extends StatefulWidget {
  const InterestBasedPage({super.key});

  @override
  _InterestBasedPageState createState() => _InterestBasedPageState();
}

class _InterestBasedPageState extends State<InterestBasedPage>
    with TickerProviderStateMixin {
  // Services
  late CategoriesService _categoriesService;
  late ApiClient _apiClient;

  // Data
  List<Category> _categories = [];
  final Map<String, List<Subcategory>> _subcategoriesByCategory = {};
  final Set<String> _selectedCategoryIds = {};
  final Set<String> _selectedSubcategoryIds = {};

  // UI state
  final String _selectedLanguage = '';
  int _currentIndex = 0;
  bool _isLoading = false;

  // Controllers & animations
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadCategories();
  }

  void _initializeServices() {
    _apiClient = ApiClient();
    _categoriesService = CategoriesService();
    _pageController = PageController();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth > 800 ? _buildWebLayout(isDark) : _buildMobileLayout(isDark);
        },
      ),
    );
  }

  // Mobile layout
  Widget _buildMobileLayout(bool isDark) {
    return Stack(
      children: [
        // Background images positioned behind the content
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/shape8.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        
        // Centered content
        Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenSize = _getScreenSize(constraints);
                  
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header section with animated content
                          _buildHeaderSection(screenSize, isDark),
                          const SizedBox(height: 20),
                          
                          // Main content with categories
                          _buildCategoryPageView(screenSize, isDark),
                          const SizedBox(height: 20),
                          
                          // Dots Indicator
                          if (_categories.isNotEmpty) _buildDotsIndicator(isDark),
                          const SizedBox(height: 30),
                          
                          // Continue button
                          _buildContinueButton(screenSize, isDark),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/shape9.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  // Web layout
  Widget _buildWebLayout(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final layoutValues = _getWebLayoutValues(screenWidth);

        return Container(
          decoration: BoxDecoration(
            image: isDark 
                ? null
                : const DecorationImage(
                    image: AssetImage('assets/images/interest-backgound2.jpg'),
                    fit: BoxFit.cover,
                  ),
            color: isDark ? const Color(0xFF121212) : null,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.vertical,
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: layoutValues.maxWidth),
                    padding: EdgeInsets.symmetric(
                      horizontal: layoutValues.horizontalPadding,
                      vertical: layoutValues.verticalPadding,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildWebTitle(layoutValues, isDark),
                            const SizedBox(height: 20),
                            _buildWebSubtitle(layoutValues, isDark),
                            const SizedBox(height: 50),
                            _buildWebCategoryGrid(isDark),
                            const SizedBox(height: 50),
                            _buildWebContinueButton(layoutValues, isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods for mobile layout
  Widget _buildHeaderSection(ScreenSize screenSize, bool isDark) {
    return Column(
      children: [
        // Title
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.titleHorizontalPadding,
            vertical: screenSize.titleVerticalPadding,
          ),
          child: Center(
            child: Text(
              'Select Your Interest',
              style: TextStyle(
                fontSize: screenSize.titleFontSize,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3748),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: screenSize.spacingAfterTitle),
        
        Center(
          child: Text(
            'Swipe to explore different career paths',
            style: TextStyle(
              fontSize: screenSize.subtitleFontSize,
              color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF2D3748),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: screenSize.spacingAfterSubtitle),
      ],
    );
  }

  Widget _buildDotsIndicator(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _categories.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == index 
                  ? const Color(0xFF5F299E) 
                  : isDark ? Colors.white.withOpacity(0.3) : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(ScreenSize screenSize, bool isDark) {
    final isEnabled = _selectedCategoryIds.isNotEmpty || _selectedLanguage.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenSize.buttonMargin),
      height: screenSize.buttonHeight,
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: isEnabled ? const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
        ) : null,
        color: !isEnabled 
            ? isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: isDark 
                ? const Color(0xFF5F299E).withOpacity(0.6)
                : const Color(0xFFF7B440).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled ? _handleContinue : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: screenSize.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: isEnabled 
                        ? Colors.white 
                        : isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isEnabled 
                      ? Colors.white 
                      : isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                  size: screenSize.isSmallScreen ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPageView(ScreenSize screenSize, bool isDark) {
    if (_isLoading) {
      return SizedBox(
        height: screenSize.cardHeight,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white : const Color(0xFF7B3FB8)
            ),
          ),
        ),
      );
    }
    
    if (_categories.isEmpty) {
      return SizedBox(
        height: screenSize.cardHeight,
        child: Center(
          child: Text(
            'No categories available',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: screenSize.cardHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: screenSize.cardMargin),
            child: _buildCategoryCard(_categories[index], screenSize, isDark),
          );
        },
      ),
    );
  }

  // Helper methods for web layout
  Widget _buildWebTitle(WebLayoutValues values, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: values.titlePadding, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Select Your Interest',
          style: TextStyle(
            fontSize: values.titleFontSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3748),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWebSubtitle(WebLayoutValues values, bool isDark) {
    return Center(
      child: Text(
        'Choose your career path to get started',
        style: TextStyle(
          fontSize: values.subtitleFontSize,
          color: isDark ? Colors.white.withOpacity(0.8) : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWebContinueButton(WebLayoutValues values, bool isDark) {
    final isEnabled = _selectedCategoryIds.isNotEmpty;
    
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: values.buttonWidth,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isEnabled 
                ? const Color(0xFF7B3FB8) 
                : isDark ? Colors.white.withOpacity(0.3) : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled 
                  ? const Color(0xFF7B3FB8).withOpacity(isDark ? 0.4 : 0.2)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: isEnabled ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: isEnabled ? _handleContinue : null,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isEnabled 
                          ? const Color(0xFF7B3FB8) 
                          : isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: isEnabled 
                        ? const Color(0xFF7B3FB8) 
                        : isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Common UI components
  Widget _buildCategoryCard(Category category, ScreenSize screenSize, bool isDark) {
    final isSelected = _selectedCategoryIds.contains(category.id ?? '');
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!;
    
    return GestureDetector(
      onTap: () => _handleCategorySelection(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: screenSize.cardContentHeight,
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [category.colorValue, category.colorValue.withOpacity(0.8)],
          ) : null,
          color: isSelected ? null : cardColor,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? null : Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? category.colorValue.withOpacity(0.4) 
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: isSelected ? 15 : 12,
              offset: Offset(0, isSelected ? 8 : 6),
              spreadRadius: isSelected ? -2 : -1,
            ),
            if (!isSelected) BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenSize.cardHorizontalPadding),
          child: Row(
            children: [
              // Icon
              Container(
                width: screenSize.iconSize,
                height: screenSize.iconSize,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : category.colorValue.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.iconData,
                  color: isSelected ? Colors.white : category.colorValue,
                  size: screenSize.iconContentSize,
                ),
              ),
              SizedBox(width: screenSize.iconSpacing),
              // Title and description
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: screenSize.cardTitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF2D3748)),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenSize.cardTitleSpacing),
                    Text(
                      category.description.isNotEmpty ? category.description : 'Explore ${category.name} courses',
                      style: TextStyle(
                        fontSize: screenSize.cardDescriptionFontSize,
                        fontWeight: FontWeight.w400,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.8) 
                            : isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600],
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenSize.indicatorSpacing),
              // Selection indicator
              Container(
                width: screenSize.indicatorSize,
                height: screenSize.indicatorSize,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : isDark ? Colors.white.withOpacity(0.1) : Colors.grey[50]!,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isSelected ? Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: screenSize.indicatorIconSize,
                ) : Container(
                  width: screenSize.unselectedIndicatorSize,
                  height: screenSize.unselectedIndicatorSize,
                  margin: EdgeInsets.all(screenSize.unselectedIndicatorMargin),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[400]!, 
                      width: 2
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebCategoryGrid(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.white : const Color(0xFF7B3FB8)
          ),
        ),
      );
    }
    
    if (_categories.isEmpty) {
      return Center(
        child: Text(
          'No categories available',
          style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.white),
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridValues = _getWebGridValues(constraints.maxWidth);

        return Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth > 800 ? 800 : constraints.maxWidth),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridValues.crossAxisCount,
              crossAxisSpacing: gridValues.crossAxisSpacing,
              mainAxisSpacing: gridValues.mainAxisSpacing,
              childAspectRatio: gridValues.childAspectRatio,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) => _buildWebCategoryCard(_categories[index], gridValues, isDark),
          ),
        );
      },
    );
  }

  Widget _buildWebCategoryCard(Category category, WebGridValues gridValues, bool isDark) {
    final isSelected = _selectedCategoryIds.contains(category.id ?? '');
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isSelected 
        ? category.colorValue.withOpacity(0.3) 
        : isDark ? Colors.white.withOpacity(0.2) : Colors.grey[200]!;
    
    return GestureDetector(
      onTap: () => _handleCategorySelection(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [category.colorValue, category.colorValue.withOpacity(0.8)],
          ) : null,
          color: isSelected ? null : cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? category.colorValue.withOpacity(0.3) 
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: isSelected ? 25 : 20,
              offset: Offset(0, isSelected ? 12 : 8),
              spreadRadius: isSelected ? 0 : -2,
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(gridValues.cardPadding),
          child: Row(
            children: [
              // Icon
              Container(
                width: gridValues.iconSize,
                height: gridValues.iconSize,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : category.colorValue.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.3) 
                        : category.colorValue.withOpacity(isDark ? 0.3 : 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  category.iconData,
                  color: isSelected ? Colors.white : category.colorValue,
                  size: 24,
                ),
              ),
              SizedBox(width: gridValues.iconPadding),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: gridValues.titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF2D3748)),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.description.isNotEmpty ? category.description : 'Explore ${category.name} courses',
                      style: TextStyle(
                        fontSize: gridValues.descriptionFontSize,
                        fontWeight: FontWeight.w400,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.9) 
                            : isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white 
                        : isDark ? Colors.white.withOpacity(0.4) : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
                child: isSelected ? Icon(Icons.check, size: 16, color: category.colorValue) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Event handlers
  void _handleCategorySelection(Category category) {
    setState(() {
      _selectedCategoryIds
        ..clear()
        ..add(category.id ?? '');
      _selectedSubcategoryIds.clear();
    });
  }

  Future<void> _handleContinue() async {
    if (_selectedCategoryIds.isNotEmpty && _selectedSubcategoryIds.isEmpty) {
      final firstId = _selectedCategoryIds.first;
      final category = _categories.firstWhere(
            (c) => (c.id ?? '') == firstId,
        orElse: () => _categories.first,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubcategorySelectPage(
            category: category,
            initiallySelected: _selectedSubcategoryIds,
            onDone: (subs) {
              setState(() {
                _selectedSubcategoryIds
                  ..clear()
                  ..addAll(subs);
              });
            },
          ),
        ),
      );
      
      // After returning from subcategory selection, submit interests if we have selections
      if (mounted && _selectedSubcategoryIds.isNotEmpty) {
        await _submitInterests();
      }
    } else if (_selectedCategoryIds.isNotEmpty && _selectedSubcategoryIds.isNotEmpty) {
      await _submitInterests();
    } else if (_selectedLanguage.isNotEmpty) {
      _handleNext();
    }
  }

  void _handleNext() {
    // Navigate to subcategory selection with selected categories
    if (_selectedCategoryIds.isNotEmpty) {
      final category = _categories.firstWhere((c) => c.id == _selectedCategoryIds.first);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategorySelectPage(
            category: category,
            initiallySelected: _selectedSubcategoryIds,
            onDone: (subs) {
              setState(() {
                _selectedSubcategoryIds
                  ..clear()
                  ..addAll(subs);
              });
            },
          ),
        ),
      );
    }
  }

  // Data methods
  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final categories = await _categoriesService.getAllCategories();
      print('📊 Loaded ${categories.length} categories from API');
      for (int i = 0; i < categories.length; i++) {
        print('Category ${i + 1}: ${categories[i].name} (ID: ${categories[i].id})');
      }
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitInterests() async {
    if (_selectedCategoryIds.isEmpty || _selectedSubcategoryIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.post(
        ApiConfig.userInterests,
        data: {
          'categories': _selectedCategoryIds.toList(),
          'subcategories': _selectedSubcategoryIds.toList(),
        },
      );

      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Interests saved successfully'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.green[700] 
                : Colors.green,
          ),
        );
        // Navigate to dashboard after successful interest submission
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Failed to save interests'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.red[700] 
                : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper classes for responsive values
  ScreenSize _getScreenSize(BoxConstraints constraints) {
    final isSmallScreen = constraints.maxWidth < 360 || constraints.maxHeight < 640;
    final isVerySmallScreen = constraints.maxHeight < 700;
    final isExtremelySmallScreen = constraints.maxHeight < 550;

    return ScreenSize(
      titleFontSize: isExtremelySmallScreen ? 14 : (isSmallScreen ? 16 : 20),
      subtitleFontSize: isExtremelySmallScreen ? 10 : (isSmallScreen ? 11 : 14),
      titleHorizontalPadding: isExtremelySmallScreen ? 12 : (isSmallScreen ? 14 : 20),
      titleVerticalPadding: isExtremelySmallScreen ? 6 : (isSmallScreen ? 8 : 12),
      spacingAfterTitle: isExtremelySmallScreen ? 0 : (isSmallScreen ? 1 : 4),
      spacingAfterSubtitle: isExtremelySmallScreen ? 8 : (isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 25)),
      cardHeight: isExtremelySmallScreen ? 80 : (isVerySmallScreen ? 90 : (isSmallScreen ? 100 : 110)),
      cardMargin: isExtremelySmallScreen ? 10 : (isSmallScreen ? 14 : 20),
      spacingAfterCards: isExtremelySmallScreen ? 4 : (isSmallScreen ? 8 : 15),
      spacingBeforeButton: isExtremelySmallScreen ? 8 : (isVerySmallScreen ? 15 : (isSmallScreen ? 20 : 50)),
      buttonMargin: isExtremelySmallScreen ? 20 : (isSmallScreen ? 30 : 60),
      buttonHeight: isExtremelySmallScreen ? 44 : (isSmallScreen ? 48 : 56),
      buttonFontSize: isExtremelySmallScreen ? 14 : (isSmallScreen ? 15 : 18),
      cardContentHeight: isExtremelySmallScreen ? 70 : (isVerySmallScreen ? 80 : (isSmallScreen ? 90 : 100)),
      cardHorizontalPadding: isExtremelySmallScreen ? 8 : (isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
      iconSize: isExtremelySmallScreen ? 18 : (isVerySmallScreen ? 22 : (isSmallScreen ? 26 : 30)),
      iconContentSize: isExtremelySmallScreen ? 16 : (isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 24)),
      iconSpacing: isExtremelySmallScreen ? 14 : (isVerySmallScreen ? 18 : (isSmallScreen ? 24 : 30)),
      cardTitleFontSize: isExtremelySmallScreen ? 11 : (isVerySmallScreen ? 13 : (isSmallScreen ? 14 : 16)),
      cardTitleSpacing: isExtremelySmallScreen ? 0 : (isVerySmallScreen ? 1 : (isSmallScreen ? 2 : 4)),
      cardDescriptionFontSize: isExtremelySmallScreen ? 8 : (isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 12)),
      indicatorSize: isExtremelySmallScreen ? 26 : (isVerySmallScreen ? 30 : (isSmallScreen ? 36 : 40)),
      indicatorIconSize: isExtremelySmallScreen ? 16 : (isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 24)),
      indicatorSpacing: isExtremelySmallScreen ? 8 : (isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
      unselectedIndicatorSize: isExtremelySmallScreen ? 12 : (isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 20)),
      unselectedIndicatorMargin: isExtremelySmallScreen ? 4 : (isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 10)),
      isSmallScreen: isSmallScreen,
    );
  }

  WebLayoutValues _getWebLayoutValues(double screenWidth) {
    if (screenWidth < 600) {
      return WebLayoutValues(
        maxWidth: 500,
        horizontalPadding: 20,
        verticalPadding: 30,
        titleFontSize: 22,
        subtitleFontSize: 13,
        titlePadding: 25,
        buttonWidth: 200,
      );
    } else if (screenWidth < 900) {
      return WebLayoutValues(
        maxWidth: 700,
        horizontalPadding: 30,
        verticalPadding: 40,
        titleFontSize: 24,
        subtitleFontSize: 14,
        titlePadding: 30,
        buttonWidth: 240,
      );
    } else {
      return WebLayoutValues(
        maxWidth: 1000,
        horizontalPadding: 40,
        verticalPadding: 60,
        titleFontSize: 28,
        subtitleFontSize: 16,
        titlePadding: 40,
        buttonWidth: 280,
      );
    }
  }

  WebGridValues _getWebGridValues(double maxWidth) {
    if (maxWidth > 1200) {
      return WebGridValues(
        crossAxisCount: 2,
        crossAxisSpacing: 50,
        mainAxisSpacing: 35,
        childAspectRatio: 3.5,
        cardPadding: 20,
        iconSize: 48,
        titleFontSize: 16,
        descriptionFontSize: 12,
        iconPadding: 16,
      );
    } else if (maxWidth > 900) {
      return WebGridValues(
        crossAxisCount: 2,
        crossAxisSpacing: 40,
        mainAxisSpacing: 30,
        childAspectRatio: 3.0,
        cardPadding: 20,
        iconSize: 48,
        titleFontSize: 16,
        descriptionFontSize: 12,
        iconPadding: 16,
      );
    } else if (maxWidth > 700) {
      return WebGridValues(
        crossAxisCount: 2,
        crossAxisSpacing: 30,
        mainAxisSpacing: 25,
        childAspectRatio: 2.8,
        cardPadding: 20,
        iconSize: 48,
        titleFontSize: 16,
        descriptionFontSize: 12,
        iconPadding: 16,
      );
    } else if (maxWidth > 500) {
      return WebGridValues(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 2.5,
        cardPadding: 18,
        iconSize: 44,
        titleFontSize: 15,
        descriptionFontSize: 11,
        iconPadding: 14,
      );
    } else {
      return WebGridValues(
        crossAxisCount: 1,
        crossAxisSpacing: 0,
        mainAxisSpacing: 15,
        childAspectRatio: 3.0,
        cardPadding: 15,
        iconSize: 40,
        titleFontSize: 14,
        descriptionFontSize: 11,
        iconPadding: 12,
      );
    }
  }
}

// Helper classes for responsive values
class ScreenSize {
  final double titleFontSize;
  final double subtitleFontSize;
  final double titleHorizontalPadding;
  final double titleVerticalPadding;
  final double spacingAfterTitle;
  final double spacingAfterSubtitle;
  final double cardHeight;
  final double cardMargin;
  final double spacingAfterCards;
  final double spacingBeforeButton;
  final double buttonMargin;
  final double buttonHeight;
  final double buttonFontSize;
  final double cardContentHeight;
  final double cardHorizontalPadding;
  final double iconSize;
  final double iconContentSize;
  final double iconSpacing;
  final double cardTitleFontSize;
  final double cardTitleSpacing;
  final double cardDescriptionFontSize;
  final double indicatorSize;
  final double indicatorIconSize;
  final double indicatorSpacing;
  final double unselectedIndicatorSize;
  final double unselectedIndicatorMargin;
  final bool isSmallScreen;

  const ScreenSize({
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.titleHorizontalPadding,
    required this.titleVerticalPadding,
    required this.spacingAfterTitle,
    required this.spacingAfterSubtitle,
    required this.cardHeight,
    required this.cardMargin,
    required this.spacingAfterCards,
    required this.spacingBeforeButton,
    required this.buttonMargin,
    required this.buttonHeight,
    required this.buttonFontSize,
    required this.cardContentHeight,
    required this.cardHorizontalPadding,
    required this.iconSize,
    required this.iconContentSize,
    required this.iconSpacing,
    required this.cardTitleFontSize,
    required this.cardTitleSpacing,
    required this.cardDescriptionFontSize,
    required this.indicatorSize,
    required this.indicatorIconSize,
    required this.indicatorSpacing,
    required this.unselectedIndicatorSize,
    required this.unselectedIndicatorMargin,
    required this.isSmallScreen,
  });
}

class WebLayoutValues {
  final double maxWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final double titleFontSize;
  final double subtitleFontSize;
  final double titlePadding;
  final double buttonWidth;

  const WebLayoutValues({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.titlePadding,
    required this.buttonWidth,
  });
}

class WebGridValues {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final double cardPadding;
  final double iconSize;
  final double titleFontSize;
  final double descriptionFontSize;
  final double iconPadding;

  const WebGridValues({
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.childAspectRatio,
    required this.cardPadding,
    required this.iconSize,
    required this.titleFontSize,
    required this.descriptionFontSize,
    required this.iconPadding,
  });
}