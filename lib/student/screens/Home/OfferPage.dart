import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_layout.dart';
import '../../services/offers_service.dart';
import '../../models/offer.dart';

class OfferPage extends StatefulWidget {
  const OfferPage({super.key});

  @override
  State<OfferPage> createState() => _OfferPageState();
}

class _OfferPageState extends State<OfferPage> {
  @override
  void initState() {
    super.initState();
    // Fetch offers when page loads
    debugPrint('🎯 OfferPage: initState - scheduling offers fetch...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🎯 OfferPage: Triggering offers fetch...');
      context.read<OffersService>().fetchOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppLayout(
      title: 'Special Offers',
      currentIndex: 0, // Home tab
      showBackButton: true,
      showBottomNavigation: false, // Hide bottom navigation
      showHeaderActions: false, // Hide header icons
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // Define responsive breakpoints
          bool isMobile = screenWidth <= 800;
          bool isTablet = screenWidth > 800 && screenWidth <= 1200;
          bool isDesktop = screenWidth > 1200;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark 
                  ? LinearGradient(
                      colors: [
                        Colors.grey.shade900,
                        Colors.grey.shade800,
                        Colors.grey.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.purple.shade50,
                        Colors.white,
                        Colors.blue.shade50,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Stack(
              children: [
                // 🔹 Decorative background shapes
                if (!isDark) ...[
                  Positioned(
                    top: -80,
                    right: -80,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -60,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(125),
                      ),
                    ),
                  ),
                ] else ...[
                  // Dark mode decorative elements
                  Positioned(
                    top: -80,
                    right: -80,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -60,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(10),
                        borderRadius: BorderRadius.circular(125),
                      ),
                    ),
                  ),
                ],

                // Main Content with Consumer
                Consumer<OffersService>(
                  builder: (context, offersService, child) {
                    if (offersService.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading offers...',
                              style: TextStyle(
                                fontSize: 16, 
                                color: isDark ? Colors.grey[300] : Colors.grey[600]
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (offersService.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline, 
                              size: 64, 
                              color: Colors.red[400]
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load offers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[100] : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              offersService.errorMessage!,
                              style: TextStyle(
                                fontSize: 14, 
                                color: isDark ? Colors.grey[400] : Colors.grey[600]
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => offersService.fetchOffers(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final offers = offersService.offers;

                    if (offers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No offers available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[100] : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check back later for exciting deals!',
                              style: TextStyle(
                                fontSize: 14, 
                                color: isDark ? Colors.grey[400] : Colors.grey[600]
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          if (isDesktop || isTablet) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                'Special Offers & Promotions',
                                style: TextStyle(
                                  fontSize: isDesktop ? 32 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Discover amazing discounts on our premium courses',
                                style: TextStyle(
                                  fontSize: isDesktop ? 18 : 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],

                          // Cards Grid
                          if (isMobile) ...[
                            // Mobile: Single column layout
                            _buildMobileLayout(context, offers, isDark),
                          ] else ...[
                            // Web/Desktop/Tablet: Grid layout
                            _buildWebLayout(context, screenWidth, isDesktop, offers, isDark),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Mobile Layout - Single Column
  Widget _buildMobileLayout(BuildContext context, List<Offer> offers, bool isDark) {
    return Column(
      children: [
        for (int i = 0; i < offers.length; i++) ...[
          _buildOfferCard(
            context,
            offer: offers[i],
            backgroundColor: _getOfferColor(i, isDark),
            imageAsset: _getOfferImage(i),
            isDark: isDark,
          ),
          if (i < offers.length - 1) const SizedBox(height: 16),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  /// 🔹 Web/Desktop Layout - Grid
  Widget _buildWebLayout(BuildContext context, double screenWidth, bool isDesktop, List<Offer> offers, bool isDark) {
    final cardSpacing = isDesktop ? 24.0 : 20.0;
    final cardHeight = isDesktop ? 280.0 : 260.0;

    // Create rows of 2 cards each
    List<Widget> rows = [];
    for (int i = 0; i < offers.length; i += 2) {
      if (i + 1 < offers.length) {
        // Two cards in a row
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildWebOfferCard(
                  context,
                  offer: offers[i],
                  backgroundColor: _getOfferColor(i, isDark),
                  imageAsset: _getOfferImage(i),
                  height: cardHeight,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildWebOfferCard(
                  context,
                  offer: offers[i + 1],
                  backgroundColor: _getOfferColor(i + 1, isDark),
                  imageAsset: _getOfferImage(i + 1),
                  height: cardHeight,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );
        rows.add(SizedBox(height: cardSpacing));
      } else {
        // Single card in the last row
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildWebOfferCard(
                  context,
                  offer: offers[i],
                  backgroundColor: _getOfferColor(i, isDark),
                  imageAsset: _getOfferImage(i),
                  height: cardHeight,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(child: Container(height: cardHeight)),
            ],
          ),
        );
      }
    }

    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1400 : 1200,
        ),
        child: Column(
          children: [
            ...rows,
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper methods for colors and images
  Color _getOfferColor(int index, bool isDark) {
    if (isDark) {
      final darkColors = [
        Color(0xFF6D28D9), // Darker Purple
        Color(0xFFBE185D), // Darker Pink
        Color(0xFF0891B2), // Darker Cyan
        Color(0xFFD97706), // Darker Amber
        Color(0xFF1D4ED8), // Darker Blue
        Color(0xFF047857), // Darker Emerald
        Color(0xFFDC2626), // Darker Red
        Color(0xFF78350F), // Darker Brown
      ];
      return darkColors[index % darkColors.length];
    } else {
      final lightColors = [
        Color(0xFF8B5CF6), // Purple
        Color(0xFFEC4899), // Pink
        Color(0xFF06B6D4), // Cyan
        Color(0xFFF59E0B), // Amber
        Color(0xFF3B82F6), // Blue
        Color(0xFF10B981), // Emerald
        Color(0xFFEF4444), // Red
        Color(0xFF8B5A2B), // Brown
      ];
      return lightColors[index % lightColors.length];
    }
  }

  String _getOfferImage(int index) {
    final images = [
      'assets/images/developer.png',
      'assets/images/tester.jpg',
      'assets/images/devop.jpg',
      'assets/images/splash1.png',
      'assets/images/homescreen.png',
    ];
    return images[index % images.length];
  }

  /// 🔹 Mobile Offer Card
  Widget _buildOfferCard(
    BuildContext context, {
    required Offer offer,
    required Color backgroundColor,
    required String imageAsset,
    required bool isDark,
  }) {
    final isExpired = !offer.isValid;
    final cardColor = isExpired 
        ? (isDark ? Colors.grey[800]! : Colors.grey[600]!)
        : backgroundColor;

    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(isDark ? 0.4 : 0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background decorative circle
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Expired overlay
            if (isExpired)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.3),
                ),
              ),

            // Expired badge
            if (isExpired)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'EXPIRED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Left side - Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer.discountText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offer.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          offer.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.detailedValidityText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Code: ${offer.code}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Coupon button
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: backgroundColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Use Coupon: ${offer.code}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side - Image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Web/Desktop Offer Card
  Widget _buildWebOfferCard(
    BuildContext context, {
    required Offer offer,
    required Color backgroundColor,
    required String imageAsset,
    required double height,
    required bool isDark,
  }) {
    final isExpired = !offer.isValid;
    final cardColor = isExpired 
        ? (isDark ? Colors.grey[800]! : Colors.grey[600]!)
        : backgroundColor;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(isDark ? 0.4 : 0.3),
            spreadRadius: 0,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.03 : 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Expired overlay
            if (isExpired)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.3),
                ),
              ),

            // Expired badge
            if (isExpired)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'EXPIRED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Left side - Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer.discountText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          offer.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          offer.detailedValidityText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Code: ${offer.code}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Coupon button
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: backgroundColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            "Use Coupon: ${offer.code}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right side - Image
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
