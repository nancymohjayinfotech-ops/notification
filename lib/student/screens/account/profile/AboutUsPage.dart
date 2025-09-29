import 'package:flutter/material.dart';
import '../../../services/content_service.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F299E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth = 1000.0;
          final horizontalPadding = constraints.maxWidth > 900 ? 32.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5F299E), Color(0xFF5F299E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5F299E).withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.school,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Mi Skills',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Empowering Learning Through Technology',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dynamic About Content from API
                    FutureBuilder<String?>(
                      future: ContentService().fetchContent('about'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final text = snapshot.data;
                        return _buildSection(
                          context,
                          'About',
                          (text == null || text.isEmpty)
                              ? 'Unable to load content. Please try again later.'
                              : text,
                          Icons.info_outline,
                          isDark,
                        );
                      },
                    ),

                    _buildSection(
                      context,
                      'Our Mission',
                      'We are dedicated to making quality education accessible to everyone, everywhere. Our platform connects learners with expert instructors and cutting-edge content to help them achieve their goals.',
                      Icons.flag_outlined,
                      isDark,
                    ),

                    _buildSection(
                      context,
                      'Our Story',
                      'Founded in 2020, Mi Skillsstarted with a simple vision: to democratize education and make learning more engaging and effective. Today, we serve millions of learners worldwide across various disciplines.',
                      Icons.history,
                      isDark,
                    ),

                    _buildSection(
                      context,
                      'What We Offer',
                      '• Expert-led courses in technology, business, and creative fields\n• Interactive learning experiences with hands-on projects\n• Personalized learning paths tailored to your goals\n• Community support and peer-to-peer learning\n• Certificates and credentials recognized by industry leaders',
                      Icons.star_outline,
                      isDark,
                    ),

                    _buildSection(
                      context,
                      'Our Values',
                      '• Excellence: We strive for the highest quality in everything we do\n• Accessibility: Education should be available to everyone\n• Innovation: We embrace new technologies to enhance learning\n• Community: Learning is better when we support each other\n• Growth: We believe in continuous improvement and lifelong learning',
                      Icons.favorite_outline,
                      isDark,
                    ),

                    // Team Section
                    // Container(
                    //   width: double.infinity,
                    //   padding: EdgeInsets.all(20),
                    //   decoration: BoxDecoration(
                    //     color: isDark ? Colors.grey[850] : Colors.white,
                    //     borderRadius: BorderRadius.circular(12),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: isDark
                    //             ? Colors.black.withOpacity(0.12)
                    //             : Colors.grey.withOpacity(0.1),
                    //         spreadRadius: 1,
                    //         blurRadius: 3,
                    //         offset: Offset(0, 1),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Row(
                    //         children: [
                    //           const Icon(
                    //             Icons.people_outline,
                    //             color: Color(0xFF5F299E),
                    //             size: 24,
                    //           ),
                    //           const SizedBox(width: 12),
                    //           const Text(
                    //             'Our Team',
                    //             style: TextStyle(
                    //               fontSize: 18,
                    //               fontWeight: FontWeight.bold,
                    //               color: Color(0xFF5F299E),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       const SizedBox(height: 16),
                    //       LayoutBuilder(
                    //         builder: (context, teamConstraints) {
                    //           final isWide = teamConstraints.maxWidth > 700;
                    //           final itemsPerRow = isWide ? 2 : 1;
                    //           final horizontalSpacing = 16.0;
                    //           final itemWidth =
                    //               (teamConstraints.maxWidth -
                    //                   (itemsPerRow - 1) * horizontalSpacing) /
                    //               itemsPerRow;

                    //           return Wrap(
                    //             spacing: horizontalSpacing,
                    //             runSpacing: 16,
                    //             children: [
                    //               SizedBox(
                    //                 width: itemWidth,
                    //                 child: _buildTeamMember(
                    //                   'Sarah Johnson',
                    //                   'CEO & Founder',
                    //                   'assets/images/instructor1.png',
                    //                   isDark: isDark,
                    //                 ),
                    //               ),
                    //               SizedBox(
                    //                 width: itemWidth,
                    //                 child: _buildTeamMember(
                    //                   'Mike Chen',
                    //                   'CTO',
                    //                   'assets/images/instructor2.png',
                    //                   isDark: isDark,
                    //                 ),
                    //               ),
                    //               SizedBox(
                    //                 width: itemWidth,
                    //                 child: _buildTeamMember(
                    //                   'Emily Davis',
                    //                   'Head of Education',
                    //                   'assets/images/instructor3.png',
                    //                   isDark: isDark,
                    //                 ),
                    //               ),
                    //               SizedBox(
                    //                 width: itemWidth,
                    //                 child: _buildTeamMember(
                    //                   'Alex Rodriguez',
                    //                   'Lead Developer',
                    //                   'assets/images/homescreen.png',
                    //                   isDark: isDark,
                    //                 ),
                    //               ),
                    //             ],
                    //           );
                    //         },
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 20),

                    _buildSection(
                      context,
                      'Get in Touch',
                      'Have questions or suggestions? We\'d love to hear from you!\n\nEmail: support@mohjayinfotech.com\nPhone: +1 (555) 123-4567\nAddress: Ludhiana, Punjab, India - 141001\n\nFollow us on social media for updates and learning tips!',
                      Icons.contact_mail_outlined,
                      isDark,
                    ),

                    const SizedBox(height: 20),

                    // App Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Mi Skills Version 1.0.0',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2024 Mi Skills All rights reserved.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.12)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5F299E), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5F299E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.85) : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(
    String name,
    String role,
    String imagePath, {
    double avatarRadius = 30,
    bool isDark = false,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: AssetImage(imagePath),
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        Text(
          role,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
