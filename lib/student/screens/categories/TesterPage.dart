import 'package:flutter/material.dart';
import 'package:fluttertest/student/screens/categories/InterestBasedPage.dart' as interest_page;

class TesterPages extends StatefulWidget {
  const TesterPages({super.key});

  @override
  _TesterPagesState createState() => _TesterPagesState();
}

class _TesterPagesState extends State<TesterPages>
    with TickerProviderStateMixin {
  String _selectedLanguage = '';
  int _currentSlide = 0;
  late PageController _pageController;

  final List<Map<String, dynamic>> testingTools = [
    {
      'name': 'Selenium',
      'icon': Icons.web,
      'color': Color.fromARGB(255, 47, 151, 24),
    },
    {
      'name': 'JUnit',
      'icon': Icons.check_circle,
      'color': Color.fromARGB(255, 177, 103, 0),
    },
    {
      'name': 'Postman',
      'icon': Icons.api,
      'color': Color.fromARGB(255, 177, 47, 0),
    },
    {
      'name': 'JIRA',
      'icon': Icons.bug_report,
      'color': Color.fromARGB(255, 0, 63, 158),
    },
    {
      'name': 'Bugzilla',
      'icon': Icons.search,
      'color': Color.fromARGB(255, 146, 0, 0),
    },
    {
      'name': 'TestNG',
      'icon': Icons.check_box,
      'color': Color.fromARGB(255, 76, 175, 80),
    },
    {
      'name': 'Cucumber',
      'icon': Icons.grass,
      'color': Color.fromARGB(255, 139, 195, 74),
    },
    {
      'name': 'Appium',
      'icon': Icons.phone_android,
      'color': Color.fromARGB(255, 33, 150, 243),
    },
    {
      'name': 'JMeter',
      'icon': Icons.speed,
      'color': Color.fromARGB(255, 255, 152, 0),
    },
    {
      'name': 'SoapUI',
      'icon': Icons.webhook,
      'color': Color.fromARGB(255, 156, 39, 176),
    },
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

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

    _animation_controller_forward_safe();
  }

  void _animation_controller_forward_safe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleSlideChange(int index) {
    setState(() {
      _currentSlide = index;
    });
  }

  Widget _buildLanguageCard(Map<String, dynamic> lang) {
    final isSelected = _selectedLanguage == lang['name'];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive values based on available width - matching DeveloperPage sizing
        double horizontalMargin = constraints.maxWidth < 300 ? 12 : 18;
        double verticalPadding = constraints.maxWidth < 300 ? 16 : 20;
        double horizontalPadding = constraints.maxWidth < 300 ? 22 : 28;
        double iconSize = constraints.maxWidth < 300 ? 28 : 34;
        double iconPadding = constraints.maxWidth < 300 ? 14 : 18;
        double fontSize = constraints.maxWidth < 300 ? 18 : 20;
        double indicatorSize = constraints.maxWidth < 300 ? 30 : 36;
        double checkIconSize = constraints.maxWidth < 300 ? 14 : 16;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5F299E).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedLanguage = lang['name'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.white, Colors.grey.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5F299E)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : (lang['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          lang['icon'],
                          color: isSelected ? Colors.white : lang['color'],
                          size: iconSize * 0.65,
                        ),
                      ),
                      SizedBox(width: iconPadding),
                      Expanded(
                        child: Text(
                          lang['name'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF2D3748),
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        width: indicatorSize,
                        height: indicatorSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[400]!,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: const Color(0xFF5F299E),
                                size: checkIconSize,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotIndicators() {
    // Determine cards per slide based on screen width
    final width = MediaQuery.of(context).size.width;
    int cardsPerSlide;
    if (width <= 360) {
      cardsPerSlide = 1;
    } else if (width <= 800) {
      cardsPerSlide = 3;
    } else {
      cardsPerSlide = width < 1000 ? 4 : 5;
    }

    final int totalSlides = (testingTools.length / cardsPerSlide).ceil();

    if (totalSlides <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalSlides,
          (index) => GestureDetector(
            onTap: () {
              setState(() {
                _currentSlide = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: _currentSlide == index ? 30 : 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _currentSlide == index
                    ? const Color(0xFF5F299E)
                    : Colors.grey[400],
                boxShadow: _currentSlide == index
                    ? [
                        BoxShadow(
                          color: const Color(0xFF5F299E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          if (screenWidth > 800) {
            return _buildWebLayout(screenWidth, screenHeight);
          } else {
            return _buildMobileLayout(screenWidth, screenHeight);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(double screenWidth, double screenHeight) {
    double horizontalPadding = screenWidth < 360 ? 20 : 30;
    double titleFontSize = screenWidth < 360 ? 18 : 20;
    double subtitleFontSize = screenWidth < 360 ? 12 : 14;
    double imageHeight = screenHeight < 700 ? 100 : 120;
    double cardHeight = screenHeight < 700 ? 60 : 80;

    // For mobile, show 3 cards per slide when possible (fallback to 1 on very narrow screens)
    final int cardsPerSlide = screenWidth <= 360 ? 1 : 3;
    final int pageCount = (testingTools.length / cardsPerSlide).ceil();

    return SafeArea(
      child: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                SizedBox(
                  height: screenHeight * 0.12, // Reduced from 15% to 12%
                  child: Image.asset(
                    'assets/images/shape7.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Back button overlay
                Positioned(
                  top: 8,
                  left: horizontalPadding,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Title overlay
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Tester Courses",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenHeight * 0.015),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 360 ? 15 : 20,
                          vertical: screenWidth < 360 ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF5F299E).withOpacity(0.1),
                              const Color(0xFF5F299E).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFF7B440).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "Select Your Testing Tools",
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Text(
                        "Choose your preferred testing framework",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF7B440).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/tester.jpg',
                            height: imageHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      SizedBox(
                        height: cardHeight,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: PageView.builder(
                              controller: _page_controller_safe(),
                              onPageChanged: _handleSlideChange,
                              itemCount: pageCount,
                              itemBuilder: (context, slideIndex) {
                                int startIndex = slideIndex * cardsPerSlide;
                                int endIndex = (startIndex + cardsPerSlide)
                                    .clamp(0, testingTools.length);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int i = startIndex; i < endIndex; i++)
                                      _buildLanguageCard(testingTools[i]),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildDotIndicators(),
                      SizedBox(height: screenHeight * 0.02),
                      _buildNavigationButtons(),
                      SizedBox(height: screenHeight * 0.015),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // safe access helper for _pageController
  PageController _page_controller_safe() => _pageController;

  Widget _buildWebLayout(double screenWidth, double screenHeight) {
    double availableHeight = screenHeight;
    double topShapeHeight = availableHeight * 0.12;
    double contentHeight = availableHeight - topShapeHeight;

    double titleFontSize = screenWidth < 1000
        ? 20
        : screenWidth < 1200
        ? 24
        : 28;
    double subtitleFontSize = screenWidth < 1000
        ? 12
        : screenWidth < 1200
        ? 14
        : 16;
    double imageHeight = contentHeight * 0.30;
    double cardHeight = contentHeight * 0.25;
    double horizontalPadding = screenWidth < 1000
        ? 20
        : screenWidth < 1200
        ? 40
        : 60;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF5F299E).withOpacity(0.05),
                Colors.white,
                const Color(0xFF5F299E).withOpacity(0.02),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              height: topShapeHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5F299E),
                    Color(0xFF7B3FB8),
                    Color(0xFF9B59D1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topShapeHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: screenWidth < 1000
                            ? 10
                            : screenWidth < 1200
                            ? 15
                            : 20,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -50),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 1000 ? 20 : 30,
                            vertical: screenWidth < 1000 ? 12 : 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF5F299E).withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5F299E).withOpacity(0.1),
                                blurRadius: 25,
                                offset: const Offset(0, 15),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Select Your Testing Tools",
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Choose your preferred testing framework",
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5F299E).withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/images/tester.jpg',
                              height: imageHeight,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: screenWidth < 1000
                            ? 8
                            : screenWidth < 1200
                            ? 15
                            : 20,
                      ),
                      _buildWebLanguageRow(screenWidth, cardHeight),
                      SizedBox(
                        height: screenWidth < 1000
                            ? 10
                            : screenWidth < 1200
                            ? 15
                            : 20,
                      ),
                      _buildDotIndicators(),
                      SizedBox(
                        height: screenWidth < 1000
                            ? 20
                            : screenWidth < 1200
                            ? 25
                            : 30,
                      ),
                      _buildNavigationButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebLanguageRow(double screenWidth, double cardHeight) {
    double cardSpacing = screenWidth < 1000
        ? 8
        : screenWidth < 1200
        ? 12
        : 16;
    int cardsPerSlide = screenWidth < 1000 ? 4 : 5;
    int totalSlides = (testingTools.length / cardsPerSlide).ceil();

    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        controller: _page_controller_safe(),
        onPageChanged: _handleSlideChange,
        itemCount: totalSlides,
        itemBuilder: (context, slideIndex) {
          int startIndex = slideIndex * cardsPerSlide;
          int endIndex = (startIndex + cardsPerSlide).clamp(
            0,
            testingTools.length,
          );

          List<Widget> slideCards = [];
          for (int i = startIndex; i < endIndex; i++) {
            slideCards.add(
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: cardSpacing / 2),
                  child: _buildWebLanguageCard(testingTools[i], cardHeight),
                ),
              ),
            );
          }
          while (slideCards.length < cardsPerSlide) {
            slideCards.add(
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: cardSpacing / 2),
                ),
              ),
            );
          }
          return Row(children: slideCards);
        },
      ),
    );
  }

  Widget _buildWebLanguageCard(Map<String, dynamic> lang, double cardHeight) {
    final isSelected = _selectedLanguage == lang['name'];
    double iconSize = cardHeight * 0.25;
    double fontSize = cardHeight * 0.08;
    double padding = cardHeight * 0.08;
    double indicatorSize = cardHeight * 0.12;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _selectedLanguage = lang['name'];
            });
          },
          child: Container(
            height: cardHeight,
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: (lang['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    lang['icon'],
                    color: lang['color'],
                    size: iconSize * 0.5,
                  ),
                ),
                SizedBox(height: cardHeight * 0.08),
                Text(
                  lang['name'],
                  style: TextStyle(
                    color: const Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: cardHeight * 0.06),
                Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF5F299E)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: Colors.white,
                  ),
                  child: isSelected
                      ? Container(
                          margin: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF5F299E),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            color: Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const interest_page.InterestBasedPage(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Back",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: _selectedLanguage.isNotEmpty
                ? const LinearGradient(
                    colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                  )
                : LinearGradient(colors: [Colors.grey, Colors.grey]),
            boxShadow: _selectedLanguage.isNotEmpty
                ? [
                    BoxShadow(
                      color: const Color(0xFFF7B440).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _selectedLanguage.isNotEmpty
                  ? () {
                      Navigator.pushNamed(
                        context,
                        '/dashboard',
                        arguments: {
                          'role': 'Tester',
                          'language': _selectedLanguage,
                        },
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Next",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedLanguage.isNotEmpty
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _selectedLanguage.isNotEmpty
                          ? Colors.white
                          : Colors.grey[600],
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
