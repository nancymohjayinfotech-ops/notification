import 'package:flutter/material.dart';
import 'package:fluttertest/student/screens/categories/InterestBasedPage.dart';

class DeveloperPages extends StatefulWidget {
  const DeveloperPages({super.key});

  @override
  _DeveloperPagesState createState() => _DeveloperPagesState();
}

class _DeveloperPagesState extends State<DeveloperPages> {
  String _selectedLanguage = '';
  int _currentSlide = 0;
  late PageController _pageController;

  final List<Map<String, dynamic>> languages = [
    {'name': 'Java', 'icon': Icons.code, 'color': const Color(0xFF976600)},
    {'name': 'Kotlin', 'icon': Icons.android, 'color': const Color(0xFF7341FC)},
    {
      'name': 'Swift',
      'icon': Icons.phone_iphone,
      'color': const Color(0xFF2594B3),
    },
    {
      'name': 'MEAN',
      'icon': Icons.developer_mode,
      'color': const Color(0xFF8F001F),
    },
    {'name': 'Python', 'icon': Icons.code, 'color': const Color(0xFF3776AB)},
    {
      'name': 'React Native',
      'icon': Icons.phone_android,
      'color': const Color(0xFF61DAFB),
    },
    {
      'name': 'Flutter',
      'icon': Icons.flutter_dash,
      'color': const Color(0xFF00BCD4),
    },
    {
      'name': 'Node.js',
      'icon': Icons.settings,
      'color': const Color(0xFF689F38),
    },
    {'name': 'Django', 'icon': Icons.dns, 'color': const Color(0xFF2C3E50)},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final primaryColor = const Color(0xFF5F299E);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background: white on mobile, gradient on larger screens
          Container(
            decoration: isMobile
                ? const BoxDecoration(color: Colors.white)
                : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withOpacity(0.1),
                        Colors.white,
                        primaryColor.withOpacity(0.05),
                      ],
                    ),
                  ),
          ),

          // Top curved section
          _buildTopCurvedSection(isMobile, primaryColor),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 20
                    : MediaQuery.of(context).size.width * 0.1,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with back button
                  // _buildHeader(isMobile, primaryColor),

                  SizedBox(height: isMobile ? 70 : 20),

                  // Title section
                  _buildTitleSection(isMobile, primaryColor),

                  SizedBox(height: isMobile ? 170 : 25),

                  // Developer image
                  _buildDeveloperImage(isMobile),

                  SizedBox(height: isMobile ? 15 : 25),

                  // Language selection cards - with flexible height for better mobile experience
                  isMobile
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                          child: _buildLanguageSelection(isMobile, primaryColor),
                        )
                      : Expanded(
                          child: _buildLanguageSelection(isMobile, primaryColor),
                        ),

                  SizedBox(height: isMobile ? 10 : 15),

                  // Dot indicators
                  _buildDotIndicators((languages.length / (isMobile ? 1 : 4)).ceil(), primaryColor),

                  SizedBox(height: isMobile ? 20 : 25),

                  // Navigation Pbuttons
                  _buildNavigationButtons(primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCurvedSection(bool isMobile, Color primaryColor) {
    final height = isMobile
        ? MediaQuery.of(context).size.height * 0.22
        : MediaQuery.of(context).size.height * 0.15;

    if (isMobile) {
      // Use image-based decorative header for mobile (matches LoginPage mobile header)
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Image.asset(
                  'assets/images/shape7.png',
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                ),
              ),
              // subtle overlay to match treatment used on login header
              Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.06),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop / tablet: keep previous gradient curved design
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(isMobile ? 30 : 60),
            bottomRight: Radius.circular(isMobile ? 30 : 60),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, const Color(0xFF7B3FB8)],
          ),
        ),
        child: CustomPaint(
          painter: _TopCurvePainter(),
          size: Size(MediaQuery.of(context).size.width, height),
        ),
      ),
    );
  }

  // Widget _buildHeader(bool isMobile, Color primaryColor) {
  //   return Row(
  //     children: [
  //       Container(
  //         child: IconButton(
  //           icon: const Icon(
  //             Icons.arrow_back_ios_rounded,
  //             color: Colors.white,
  //             size: 20,
  //           ),
  //           onPressed: () => Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(builder: (_) => const InterestBasedPage()),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTitleSection(bool isMobile, Color primaryColor) {
    if (isMobile) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Select Your Programming Language",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              "Choose your preferred technology stack",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // Web layout - no container, just text
      return Column(
        children: [
          Text(
            "Select Your Programming Language",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            "Choose your preferred technology stack",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildDeveloperImage(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 15 : 20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF7B440).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 15 : 20),
        child: Image.asset(
          'assets/images/developer.png',
          height: isMobile
              ? MediaQuery.of(context).size.height * 0.15
              : MediaQuery.of(context).size.height * 0.2,
        ),
      ),
    );
  }

  Widget _buildLanguageSelection(bool isMobile, Color primaryColor) {
    final cardsPerSlide = isMobile ? 1 : 4;
    final totalSlides = (languages.length / cardsPerSlide).ceil();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: totalSlides,
            itemBuilder: (context, slideIndex) {
              return isMobile
                  ? _buildMobileLanguageCard(slideIndex, primaryColor)
                  : _buildWebLanguageRow(slideIndex, primaryColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLanguageCard(int index, Color primaryColor) {
    final lang = languages[index];
    final isSelected = _selectedLanguage == lang['name'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: isSelected
            ? LinearGradient(colors: [primaryColor, primaryColor])
            : LinearGradient(colors: [Colors.white, Colors.grey[50]!]),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? primaryColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : (lang['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            lang['icon'] as IconData,
            color: isSelected ? Colors.white : lang['color'] as Color,
          ),
        ),
        title: Text(
          lang['name'] as String,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.white : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.grey[400]!,
              width: 1.5,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check, color: primaryColor, size: 16)
              : null,
        ),
        onTap: () => setState(() => _selectedLanguage = lang['name'] as String),
      ),
    );
  }

  Widget _buildWebLanguageRow(int slideIndex, Color primaryColor) {
    final cardsPerSlide = 4;
    final startIndex = slideIndex * cardsPerSlide;
    final endIndex = (startIndex + cardsPerSlide).clamp(0, languages.length);

    return Row(
      children: List.generate(cardsPerSlide, (index) {
        if (startIndex + index >= languages.length) {
          return const Expanded(
            child: SizedBox.shrink(),
          ); // Empty space if no more languages
        }

        final lang = languages[startIndex + index];
        final isSelected = _selectedLanguage == lang['name'];

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            constraints: BoxConstraints(maxWidth: 180, maxHeight: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    setState(() => _selectedLanguage = lang['name'] as String),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (lang['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          lang['icon'] as IconData,
                          color: lang['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                          color: Colors.white,
                        ),
                        child: isSelected
                            ? Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryColor,
                                ),
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
      }),
    );
  }

  Widget _buildDotIndicators(int totalSlides, Color primaryColor) {
    if (totalSlides <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSlides, (index) {
        return GestureDetector(
          onTap: () {
            setState(() => _currentSlide = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: _currentSlide == index ? 25 : 10,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentSlide == index ? primaryColor : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text("Back"),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InterestBasedPage()),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Next button
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text("Next"),
          onPressed: _selectedLanguage.isNotEmpty
              ? () {
                  Navigator.pushNamed(
                    context,
                    '/dashboard',
                    arguments: {
                      'role': 'Developer',
                      'language': _selectedLanguage,
                    },
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            shadowColor: const Color(0xFFF7B440).withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

class _TopCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.85,
      size.width * 0.5,
      size.height * 0.9,
    );
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.95,
      0,
      size.height * 0.75,
    );
    path.close();

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, whitePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}