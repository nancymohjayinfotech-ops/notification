import 'package:flutter/material.dart';
import 'package:fluttertest/student/screens/categories/InterestBasedPage.dart';

class DeveloperPagesCopy extends StatefulWidget {
  const DeveloperPagesCopy({super.key});

  @override
  _DeveloperPagesCopyState createState() => _DeveloperPagesCopyState();
}

class _DeveloperPagesCopyState extends State<DeveloperPagesCopy>
    with TickerProviderStateMixin {
  String _selectedLanguage = '';
  final List<Map<String, dynamic>> languages = [
    {'name': 'Java', 'icon': Icons.coffee, 'color': Color(0xFFED8B00)},
    {'name': 'Kotlin', 'icon': Icons.android, 'color': Color(0xFF7F52FF)},
    {'name': 'SpringBoot', 'icon': Icons.eco, 'color': Color(0xFF6DB33F)},
    {'name': 'MERN', 'icon': Icons.web, 'color': Color(0xFF61DAFB)},
    {'name': 'MEAN', 'icon': Icons.code, 'color': Color(0xFFDD0031)},
  ];

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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Enhanced top image with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/shape7.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Enhanced title
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF5F299E).withValues(alpha: 0.1),
                                const Color(0xFF5F299E).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(
                                0xFFF7B440,
                              ).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            "Select Your Programming Language",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Choose your preferred technology stack",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Enhanced developer image
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF7B440,
                                ).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/developer.png',
                              height: 150,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Enhanced Language buttons with icons
                        Expanded(
                          child: ListView.builder(
                            itemCount: languages.length,
                            itemBuilder: (context, index) {
                              final lang = languages[index];
                              final isSelected =
                                  _selectedLanguage == lang['name'];

                              return AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      (1 - _fadeAnimation.value) *
                                          30 *
                                          (index + 1),
                                    ),
                                    child: Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6.0,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFFF7B440,
                                                      ).withValues(alpha: 0.4),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        6,
                                                      ),
                                                    ),
                                                  ]
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              onTap: () {
                                                setState(() {
                                                  _selectedLanguage =
                                                      lang['name'];
                                                });
                                              },
                                              child: Container(
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  gradient: isSelected
                                                      ? const LinearGradient(
                                                          colors: [
                                                            Color(0xFF5F299E),
                                                            Color(0xFF5F299E),
                                                          ],
                                                          begin: Alignment
                                                              .centerLeft,
                                                          end: Alignment
                                                              .centerRight,
                                                        )
                                                      : LinearGradient(
                                                          colors: [
                                                            Colors.white,
                                                            Colors.grey[50]!,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFF7B440,
                                                          )
                                                        : Colors.grey[300]!,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      // Technology icon
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    )
                                                              : lang['color']
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          lang['icon'],
                                                          color: isSelected
                                                              ? Colors.white
                                                              : lang['color'],
                                                          size: 22,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),

                                                      // Language name
                                                      Expanded(
                                                        child: Text(
                                                          lang['name'],
                                                          style: TextStyle(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF2D3748,
                                                                  ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 16,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),

                                                      // Selection indicator
                                                      Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: isSelected
                                                              ? Colors.white
                                                              : Colors
                                                                    .transparent,
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors
                                                                      .grey[400]!,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: isSelected
                                                            ? Icon(
                                                                Icons.check,
                                                                color:
                                                                    const Color(
                                                                      0xFFF7B440,
                                                                    ),
                                                                size: 14,
                                                              )
                                                            : null,
                                                      ),
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
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Enhanced navigation buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
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
                                        builder: (_) =>
                                            const InterestBasedPage(),
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

                            // Next button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: _selectedLanguage.isNotEmpty
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF5F299E),
                                          Color(0xFF5F299E),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.grey[300]!,
                                          Colors.grey[400]!,
                                        ],
                                      ),
                                boxShadow: _selectedLanguage.isNotEmpty
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFF7B440,
                                          ).withValues(alpha: 0.4),
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
                                              'role': 'Developer',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
