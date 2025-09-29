import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../services/categories_service.dart';

class SubcategorySelectPage extends StatefulWidget {
  final Category category;
  final Set<String> initiallySelected;
  final ValueChanged<Set<String>> onDone;

  const SubcategorySelectPage({
    super.key,
    required this.category,
    required this.initiallySelected,
    required this.onDone,
  });

  @override
  State<SubcategorySelectPage> createState() => _SubcategorySelectPageState();
}

class _SubcategorySelectPageState extends State<SubcategorySelectPage> {
  final CategoriesService _categoriesService = CategoriesService();
  List<Subcategory> _subcategories = [];
  bool _loading = true;
  final Set<String> _selected = {};
  int _currentIndex = 0;
  late PageController _pageController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initiallySelected);
    _pageController = PageController();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.category.id == null) {
      setState(() {
        _subcategories = [];
        _loading = false;
      });
      return;
    }
    final subs = await _categoriesService.getSubcategories(widget.category.id!);
    setState(() {
      _subcategories = subs;
      _loading = false;
    });
  }

  Future<void> _submitSelection() async {
    if (_selected.isEmpty || _isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      widget.onDone(_selected);
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth > 800 ? _buildWebLayout() : _buildMobileLayout();
        },
      ),
    );
  }

  // Mobile layout (keeping your existing mobile layout)
  Widget _buildMobileLayout() {
    final screenSize = getSubcategoryScreenSize(context);
    final height = MediaQuery.of(context).size.height;
    final isVerySmall = height < 650;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top decorative image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/shape8.png',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title chip
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  const Color(0xFF5F299E).withOpacity(0.1),
                                  const Color(0xFF5F299E).withOpacity(0.05),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFFF7B440).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Select Your Interest',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2D3748),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Swipe to explore different career paths',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : const Color(0xFF2D3748),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_subcategories.isEmpty)
                      Center(
                        child: Text(
                          'No subcategories available',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: screenSize.cardHeight,
                            child: PageView.builder(
                              controller: _pageController,
                              scrollDirection: Axis.horizontal,
                              itemCount: _subcategories.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final s = _subcategories[index];
                                final selected = _selected.contains(s.id ?? '');
                                return Center(
                                  child: Container(
                                    height: screenSize.cardHeight,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: screenSize.cardMargin,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (s.id == null) return;
                                          _selected
                                            ..clear()
                                            ..add(s.id!);
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        height: screenSize.cardContentHeight,
                                        decoration: BoxDecoration(
                                          gradient: selected
                                              ? LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    s.colorValue,
                                                    s.colorValue.withOpacity(0.8),
                                                  ],
                                                )
                                              : null,
                                          color: _getCardBackgroundColor(context, selected, s.colorValue),
                                          borderRadius: BorderRadius.circular(22),
                                          border: Border.all(
                                            color: _getBorderColor(context, selected),
                                            width: 1,
                                          ),
                                          boxShadow: isDark && !selected
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: selected
                                                        ? s.colorValue.withOpacity(0.3)
                                                        : Colors.black.withOpacity(0.08),
                                                    blurRadius: selected ? 15 : 12,
                                                    offset: Offset(0, selected ? 8 : 6),
                                                    spreadRadius: selected ? -2 : -1,
                                                  ),
                                                  if (!selected)
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.04),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                      spreadRadius: 0,
                                                    ),
                                                ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenSize.cardHorizontalPadding,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: screenSize.iconSize,
                                                height: screenSize.iconSize,
                                                decoration: BoxDecoration(
                                                  color: _getIconBackgroundColor(context, selected, s.colorValue),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  s.iconData,
                                                  color: selected ? Colors.white : s.colorValue,
                                                  size: screenSize.iconContentSize,
                                                ),
                                              ),
                                              SizedBox(width: screenSize.iconSpacing),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      s.name,
                                                      style: TextStyle(
                                                        fontSize: screenSize.cardTitleFontSize,
                                                        fontWeight: FontWeight.bold,
                                                        color: _getTextColor(context, selected),
                                                        letterSpacing: 0.5,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      s.description.isNotEmpty
                                                          ? s.description
                                                          : 'Explore ${s.name} courses',
                                                      style: TextStyle(
                                                        fontSize: screenSize.cardDescriptionFontSize,
                                                        fontWeight: FontWeight.w400,
                                                        color: _getDescriptionTextColor(context, selected),
                                                        height: 1.2,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: screenSize.iconSpacing),
                                              Container(
                                                width: screenSize.indicatorSize,
                                                height: screenSize.indicatorSize,
                                                decoration: BoxDecoration(
                                                  color: _getIndicatorBackgroundColor(context, selected),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: selected
                                                    ? Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                        size: screenSize.indicatorIconSize,
                                                      )
                                                    : Container(
                                                        width: screenSize.unselectedIndicatorSize,
                                                        height: screenSize.unselectedIndicatorSize,
                                                        margin: EdgeInsets.all(
                                                            screenSize.unselectedIndicatorMargin),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                                                            width: 2,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_subcategories.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _subcategories.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentIndex == index ? 18 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getDotIndicatorColor(context, _currentIndex == index),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.fromLTRB(60, 0, 60, 24),
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: (_selected.isNotEmpty && !_isSubmitting)
                          ? const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                            )
                          : null,
                      color: (_selected.isEmpty || _isSubmitting) 
                          ? (isDark ? Colors.grey[800]! : Colors.grey[300]!)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: (_selected.isNotEmpty && !_isSubmitting)
                          ? [
                              BoxShadow(
                                color: isDark 
                                    ? Colors.black.withOpacity(0.5)
                                    : const Color(0xFFF7B440).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: (_selected.isNotEmpty && !_isSubmitting) ? _submitSelection : null,
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: _getButtonTextColor(_selected.isNotEmpty),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: _getButtonTextColor(_selected.isNotEmpty),
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  // Web layout (matching your InterestBasedPage style)
  Widget _buildWebLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final layoutValues = _getWebLayoutValues(screenWidth);

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/interest-backgound2.jpg'),
              fit: BoxFit.cover,
            ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildWebTitle(layoutValues),
                        const SizedBox(height: 20),
                        _buildWebSubtitle(layoutValues),
                        const SizedBox(height: 50),
                        _buildWebSubcategoryGrid(),
                        const SizedBox(height: 50),
                        _buildWebContinueButton(layoutValues),
                      ],
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

  Widget _buildWebTitle(WebLayoutValues values) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: values.titlePadding, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Select Your Subcategory',
          style: TextStyle(
            fontSize: values.titleFontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWebSubtitle(WebLayoutValues values) {
    return Center(
      child: Text(
        'Choose your specific interest in ${widget.category.name}',
        style: TextStyle(
          fontSize: values.subtitleFontSize,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWebContinueButton(WebLayoutValues values) {
    final isEnabled = _selected.isNotEmpty;
    
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: values.buttonWidth,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isEnabled ? const Color(0xFF7B3FB8) : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled ? const Color(0xFF7B3FB8).withOpacity(0.2) : Colors.black.withOpacity(0.1),
              blurRadius: isEnabled ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: isEnabled ? _submitSelection : null,
            child: Center(
              child: _isSubmitting
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7B3FB8)),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? const Color(0xFF7B3FB8) : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: isEnabled ? const Color(0xFF7B3FB8) : Colors.grey[500],
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

  Widget _buildWebSubcategoryGrid() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    if (_subcategories.isEmpty) {
      return Center(
        child: Text(
          'No subcategories available',
          style: TextStyle(fontSize: 16, color: Colors.white),
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
            itemCount: _subcategories.length,
            itemBuilder: (context, index) => _buildWebSubcategoryCard(_subcategories[index], gridValues),
          ),
        );
      },
    );
  }

  Widget _buildWebSubcategoryCard(Subcategory subcategory, WebGridValues gridValues) {
    final isSelected = _selected.contains(subcategory.id ?? '');
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (subcategory.id == null) return;
          _selected
            ..clear()
            ..add(subcategory.id!);
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [subcategory.colorValue, subcategory.colorValue.withOpacity(0.8)],
            ) : const LinearGradient(colors: [Colors.white, Colors.white]),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? subcategory.colorValue.withOpacity(0.3) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? subcategory.colorValue.withOpacity(0.3) : Colors.black.withOpacity(0.08),
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
                    color: isSelected ? Colors.white.withOpacity(0.2) : subcategory.colorValue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white.withOpacity(0.3) : subcategory.colorValue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    subcategory.iconData,
                    color: isSelected ? Colors.white : subcategory.colorValue,
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
                        subcategory.name,
                        style: TextStyle(
                          fontSize: gridValues.titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF2D3748),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subcategory.description.isNotEmpty ? subcategory.description : 'Explore ${subcategory.name} courses',
                        style: TextStyle(
                          fontSize: gridValues.descriptionFontSize,
                          fontWeight: FontWeight.w400,
                          color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
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
                      color: isSelected ? Colors.white : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                  child: isSelected ? Icon(Icons.check, size: 16, color: subcategory.colorValue) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for theme-aware colors (keep your existing methods)
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.grey[50]!;
  }

  Color _getCardBackgroundColor(BuildContext context, bool selected, Color categoryColor) {
    if (selected) return categoryColor;
    
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).cardColor
        : Colors.grey[50]!;
  }

  Color _getBorderColor(BuildContext context, bool selected) {
    if (selected) return Colors.transparent;
    
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[200]!;
  }

  Color _getTextColor(BuildContext context, bool selected) {
    if (selected) return Colors.white;
    
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF2D3748);
  }

  Color _getDescriptionTextColor(BuildContext context, bool selected) {
    if (selected) return Colors.white.withOpacity(0.8);
    
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]!
        : Colors.grey[600]!;
  }

  Color _getIconBackgroundColor(BuildContext context, bool selected, Color categoryColor) {
    if (selected) return Colors.white.withOpacity(0.2);
    
    return Theme.of(context).brightness == Brightness.dark
        ? categoryColor.withOpacity(0.15)
        : categoryColor.withOpacity(0.08);
  }

  Color _getIndicatorBackgroundColor(BuildContext context, bool selected) {
    if (selected) return Colors.white.withOpacity(0.2);
    
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[50]!;
  }

  Color _getDotIndicatorColor(BuildContext context, bool isActive) {
    if (isActive) return const Color(0xFF5F299E);
    
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[600]!
        : Colors.grey[300]!;
  }

  Color _getButtonTextColor(bool isEnabled) {
    if (!isEnabled) return Colors.grey[500]!;
    
    return Colors.white;
  }

  // Web layout values (matching your InterestBasedPage)
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

// Helper classes for web layout (matching your InterestBasedPage)
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

// Keep your existing SubcategoryScreenSize class and getSubcategoryScreenSize function
class SubcategoryScreenSize {
  final double cardHeight;
  final double cardContentHeight;
  final double cardMargin;
  final double cardHorizontalPadding;
  final double iconSize;
  final double iconContentSize;
  final double iconSpacing;
  final double cardTitleFontSize;
  final double cardDescriptionFontSize;
  final double indicatorSize;
  final double indicatorIconSize;
  final double indicatorSpacing;
  final double unselectedIndicatorSize;
  final double unselectedIndicatorMargin;

  const SubcategoryScreenSize({
    required this.cardHeight,
    required this.cardContentHeight,
    required this.cardMargin,
    required this.cardHorizontalPadding,
    required this.iconSize,
    required this.iconContentSize,
    required this.iconSpacing,
    required this.cardTitleFontSize,
    required this.cardDescriptionFontSize,
    required this.indicatorSize,
    required this.indicatorIconSize,
    required this.indicatorSpacing,
    required this.unselectedIndicatorSize,
    required this.unselectedIndicatorMargin,
  });
}

SubcategoryScreenSize getSubcategoryScreenSize(BuildContext context) {
  final height = MediaQuery.of(context).size.height;
  final isSmall = height < 700;
  final isVerySmall = height < 600;
  return SubcategoryScreenSize(
    cardHeight: isVerySmall ? 80 : (isSmall ? 100 : 110),
    cardContentHeight: isVerySmall ? 70 : (isSmall ? 80 : 90),
    cardMargin: isVerySmall ? 10 : (isSmall ? 14 : 20),
    cardHorizontalPadding: isVerySmall ? 8 : (isSmall ? 12 : 20),
    iconSize: isVerySmall ? 22 : (isSmall ? 26 : 30),
    iconContentSize: isVerySmall ? 16 : (isSmall ? 18 : 22),
    iconSpacing: isVerySmall ? 10 : (isSmall ? 14 : 18),
    cardTitleFontSize: isVerySmall ? 12 : (isSmall ? 13 : 15),
    cardDescriptionFontSize: isVerySmall ? 9 : (isSmall ? 10 : 12),
    indicatorSize: isVerySmall ? 18 : (isSmall ? 22 : 26),
    indicatorIconSize: isVerySmall ? 10 : (isSmall ? 12 : 14),
    indicatorSpacing: isVerySmall ? 6 : (isSmall ? 8 : 10),
    unselectedIndicatorSize: isVerySmall ? 8 : (isSmall ? 10 : 12),
    unselectedIndicatorMargin: isVerySmall ? 2 : (isSmall ? 3 : 4),
  );
}