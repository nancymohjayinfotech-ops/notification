import 'package:flutter/material.dart';

class GroupInfoPage extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupInfoPage({super.key, required this.group});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage>
    with TickerProviderStateMixin {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [const Color(0xFF2D1B69), const Color(0xFF1E1B4B)]
                      : [const Color(0xFF5F299E), const Color(0xFF7C3AED)],
                ),
              ),
              child: FlexibleSpaceBar(
                title: const Text(
                  'Group Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              // decoration: BoxDecoration(
              //   color: Colors.white.withValues(alpha: 0.2),
              //   borderRadius: BorderRadius.circular(12),
              // ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // actions: [
            //   Container(
            //     margin: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: Colors.white.withValues(alpha: 0.2),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: PopupMenuButton<String>(
            //       icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            //       color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            //       onSelected: (value) {
            //         switch (value) {
            //           case 'edit_group':
            //             _showEditGroupDialog(context);
            //             break;
            //           case 'add_members':
            //             _showAddMembersDialog(context);
            //             break;
            //           case 'group_settings':
            //             _showGroupSettings(context);
            //             break;
            //         }
            //       },
            //       itemBuilder: (BuildContext context) => [
            //         _buildPopupMenuItem(Icons.edit_rounded, 'Edit group', 'edit_group', isDarkMode),
            //         _buildPopupMenuItem(Icons.person_add_rounded, 'Add members', 'add_members', isDarkMode),
            //         _buildPopupMenuItem(Icons.settings_rounded, 'Group settings', 'group_settings', isDarkMode),
            //       ],
            //     ),
            //   ),
            // ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Enhanced Group Header Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Enhanced Group Avatar with white border
                          Hero(
                            tag:
                                'group_avatar_${widget.group['id'] ?? 'default'}',
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(70),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(
                                        int.parse(
                                              (widget.group['color'] ??
                                                      '#5F299E')
                                                  .substring(1),
                                              radix: 16,
                                            ) +
                                            0xFF000000,
                                      ),
                                      Color(
                                        int.parse(
                                              (widget.group['color'] ??
                                                      '#5F299E')
                                                  .substring(1),
                                              radix: 16,
                                            ) +
                                            0xFF000000,
                                      ).withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(66),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.group['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Group Name with better typography
                          Text(
                            widget.group['name'],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Member Count with icon
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          //   decoration: BoxDecoration(
                          //     color: isDarkMode
                          //       ? Colors.black
                          //       : const Color(0xFFF1F5F9),
                          //     borderRadius: BorderRadius.circular(20),
                          //   ),
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Icon(
                          //         Icons.people_rounded,
                          //         size: 18,
                          //         color: isDarkMode
                          //           ? Colors.white.withOpacity(0.7)
                          //           : const Color(0xFF64748B),
                          //       ),
                          //       const SizedBox(width: 6),
                          //       Text(
                          //         '${widget.group['memberCount'] ?? 12} members',
                          //         style: TextStyle(
                          //           fontSize: 14,
                          //           fontWeight: FontWeight.w500,
                          //           color: isDarkMode
                          //             ? Colors.white.withOpacity(0.7)
                          //             : const Color(0xFF64748B),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // const SizedBox(height: 16),

                          // Description with better styling
                          if (widget.group['description'] != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(
                                        0xFF2D2D2D,
                                      ).withValues(alpha: 0.5)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.group['description'],
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(0xFF475569),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Enhanced Action Buttons
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //   children: [
                          //     _buildActionButton(
                          //       icon: Icons.call_rounded,
                          //       label: 'Call',
                          //       onTap: () => _showFeatureDialog(context, 'Group Call'),
                          //       isDarkMode: isDarkMode,
                          //     ),
                          //     _buildActionButton(
                          //       icon: Icons.videocam_rounded,
                          //       label: 'Video',
                          //       onTap: () => _showFeatureDialog(context, 'Video Call'),
                          //       isDarkMode: isDarkMode,
                          //     ),
                          //     _buildActionButton(
                          //       icon: Icons.search_rounded,
                          //       label: 'Search',
                          //       onTap: () => _showFeatureDialog(context, 'Search Messages'),
                          //       isDarkMode: isDarkMode,
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Enhanced Members Section
                    // Container(
                    //   margin: const EdgeInsets.symmetric(horizontal: 20),
                    //   decoration: BoxDecoration(
                    //     color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    //     borderRadius: BorderRadius.circular(20),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: isDarkMode
                    //           ? Colors.black.withOpacity(0.3)
                    //           : Colors.black.withOpacity(0.08),
                    //         blurRadius: 20,
                    //         offset: const Offset(0, 8),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Padding(
                    //         padding: const EdgeInsets.all(20),
                    //         child: Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Text(
                    //               '${widget.group['memberCount'] ?? 12} members',
                    //               style: TextStyle(
                    //                 fontSize: 20,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                    //               ),
                    //             ),
                    //             Container(
                    //               decoration: BoxDecoration(
                    //                 color: isDarkMode
                    //                   ? const Color(0xFF5F299E).withOpacity(0.2)
                    //                   : const Color(0xFF5F299E).withOpacity(0.1),
                    //                 borderRadius: BorderRadius.circular(12),
                    //               ),
                    //               child: IconButton(
                    //                 icon: const Icon(
                    //                   Icons.person_add_rounded,
                    //                   color: Color(0xFF5F299E),
                    //                   size: 22,
                    //                 ),
                    //                 onPressed: () => _showAddMembersDialog(context),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),

                    //       // Members List with enhanced design
                    //       ...List.generate(
                    //         (widget.group['memberCount'] ?? 5).clamp(0, 8),
                    //         (index) => _buildMemberTile(
                    //           name: _getMemberName(index),
                    //           role: index == 0 ? 'Admin' : 'Member',
                    //           isOnline: index < 4,
                    //           isDarkMode: isDarkMode,
                    //         ),
                    //       ),

                    //       // View All Members Button
                    //       if ((widget.group['memberCount'] ?? 5) > 8)
                    //         Container(
                    //           width: double.infinity,
                    //           margin: const EdgeInsets.all(20),
                    //           child: TextButton(
                    //             onPressed: () => _showAllMembers(context),
                    //             style: TextButton.styleFrom(
                    //               padding: const EdgeInsets.symmetric(vertical: 16),
                    //               backgroundColor: isDarkMode
                    //                 ? Colors.black
                    //                 : const Color(0xFFF1F5F9),
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(12),
                    //               ),
                    //             ),
                    //             child: Text(
                    //               'View all members',
                    //               style: TextStyle(
                    //                 color: const Color(0xFF5F299E),
                    //                 fontWeight: FontWeight.w600,
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //     ],
                    //   ),
                    // ),

                    // const SizedBox(height: 24),

                    // // Enhanced Settings Section
                    // Container(
                    //   margin: const EdgeInsets.symmetric(horizontal: 20),
                    //   decoration: BoxDecoration(
                    //     color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                    //     borderRadius: BorderRadius.circular(20),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: isDarkMode
                    //           ? Colors.black.withOpacity(0.3)
                    //           : Colors.black.withOpacity(0.08),
                    //         blurRadius: 20,
                    //         offset: const Offset(0, 8),
                    //       ),
                    //     ],
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       _buildSettingsTile(
                    //         icon: Icons.notifications_rounded,
                    //         title: 'Notifications',
                    //         subtitle: 'Enabled',
                    //         onTap: () => _showFeatureDialog(context, 'Notifications'),
                    //         isDarkMode: isDarkMode,
                    //         showBadge: true,
                    //       ),
                    //       _buildDivider(isDarkMode),
                    //       _buildSettingsTile(
                    //         icon: Icons.photo_library_rounded,
                    //         title: 'Media, links, and docs',
                    //         subtitle: '${(widget.group['mediaCount'] ?? 127)} items',
                    //         onTap: () => _showFeatureDialog(context, 'Media Gallery'),
                    //         isDarkMode: isDarkMode,
                    //       ),
                    //       _buildDivider(isDarkMode),
                    //       _buildSettingsTile(
                    //         icon: Icons.star_rounded,
                    //         title: 'Starred messages',
                    //         subtitle: '3 messages',
                    //         onTap: () => _showFeatureDialog(context, 'Starred Messages'),
                    //         isDarkMode: isDarkMode,
                    //       ),
                    //       _buildDivider(isDarkMode),
                    //       _buildSettingsTile(
                    //         icon: Icons.security_rounded,
                    //         title: 'Privacy & Security',
                    //         subtitle: 'Manage group privacy',
                    //         onTap: () => _showFeatureDialog(context, 'Privacy Settings'),
                    //         isDarkMode: isDarkMode,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build popup menu items
  // PopupMenuItem<String> _buildPopupMenuItem(
  //   IconData icon,
  //   String text,
  //   String value,
  //   bool isDarkMode
  // ) {
  //   return PopupMenuItem<String>(
  //     value: value,
  //     child: Row(
  //       children: [
  //         Icon(
  //           icon,
  //           size: 20,
  //           color: isDarkMode ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151),
  //         ),
  //         const SizedBox(width: 12),
  //         Text(
  //           text,
  //           style: TextStyle(
  //             color: isDarkMode ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF374151),
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Enhanced Action Button
  // Widget _buildActionButton({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  //   required bool isDarkMode,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //       decoration: BoxDecoration(
  //         color: isDarkMode
  //           ? Colors.black
  //           : const Color(0xFFF1F5F9),
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(
  //           color: isDarkMode
  //             ? Colors.white.withOpacity(0.1)
  //             : const Color(0xFFE2E8F0),
  //           width: 1,
  //         ),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             width: 48,
  //             height: 48,
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF5F299E).withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(24),
  //             ),
  //             child: Icon(
  //               icon,
  //               color: const Color(0xFF5F299E),
  //               size: 24,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: 13,
  //               fontWeight: FontWeight.w600,
  //               color: isDarkMode
  //                 ? Colors.white.withOpacity(0.8)
  //                 : const Color(0xFF475569),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // // Enhanced Member Tile
  // Widget _buildMemberTile({
  //   required String name,
  //   required String role,
  //   required bool isOnline,
  //   required bool isDarkMode,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  //     child: ListTile(
  //       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       leading: Stack(
  //         children: [
  //           Container(
  //             width: 48,
  //             height: 48,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               border: Border.all(
  //                 color: Colors.white,
  //                 width: 2,
  //               ),
  //               gradient: LinearGradient(
  //                 colors: [
  //                   Color(0xFF5F299E).withValues(alpha: 0.8),
  //                   Color(0xFF7C3AED).withValues(alpha: 0.6),
  //                 ],
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withValues(alpha: 0.1),
  //                   blurRadius: 8,
  //                   offset: const Offset(0, 2),
  //                 ),
  //               ],
  //             ),
  //             child: Center(
  //               child: Text(
  //                 name[0].toUpperCase(),
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 18,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           if (isOnline)
  //             Positioned(
  //               bottom: 2,
  //               right: 2,
  //               child: Container(
  //                 width: 14,
  //                 height: 14,
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFF10B981),
  //                   shape: BoxShape.circle,
  //                   border: Border.all(
  //                     color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
  //                     width: 2,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //       title: Text(
  //         name,
  //         style: TextStyle(
  //           color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
  //           fontWeight: FontWeight.w600,
  //           fontSize: 16,
  //         ),
  //       ),
  //       subtitle: Container(
  //         margin: const EdgeInsets.only(top: 4),
  //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //         decoration: BoxDecoration(
  //           color: role == 'Admin'
  //             ? const Color(0xFF5F299E).withValues(alpha: 0.1)
  //             : (isDarkMode ? Colors.black : const Color(0xFFF1F5F9)),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Text(
  //           role,
  //           style: TextStyle(
  //             color: role == 'Admin'
  //               ? const Color(0xFF5F299E)
  //               : (isDarkMode ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B)),
  //             fontSize: 12,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ),
  //       trailing: role == 'Admin'
  //           ? Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Icon(
  //                 Icons.admin_panel_settings_rounded,
  //                 color: Color(0xFF5F299E),
  //                 size: 20,
  //               ),
  //             )
  //           : (isOnline
  //               ? Container(
  //                   padding: const EdgeInsets.all(6),
  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFF10B981).withValues(alpha: 0.1),
  //                     borderRadius: BorderRadius.circular(6),
  //                   ),
  //                   child: const Icon(
  //                     Icons.circle,
  //                     color: Color(0xFF10B981),
  //                     size: 8,
  //                   ),
  //                 )
  //               : null),
  //     ),
  //   );
  // }

  // // Enhanced Settings Tile
  // Widget _buildSettingsTile({
  //   required IconData icon,
  //   required String title,
  //   required String subtitle,
  //   required VoidCallback onTap,
  //   required bool isDarkMode,
  //   bool showBadge = false,
  // }) {
  //   return ListTile(
  //     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  //     leading: Container(
  //       width: 44,
  //       height: 44,
  //       decoration: BoxDecoration(
  //         color: isDarkMode
  //           ? Colors.black
  //           : const Color(0xFFF1F5F9),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Icon(
  //         icon,
  //         color: const Color(0xFF5F299E),
  //         size: 22,
  //       ),
  //     ),
  //     title: Row(
  //       children: [
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: TextStyle(
  //               color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
  //               fontWeight: FontWeight.w600,
  //               fontSize: 16,
  //             ),
  //           ),
  //         ),
  //         if (showBadge)
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF10B981),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: const Text(
  //               'ON',
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //       ],
  //     ),
  //     subtitle: Padding(
  //       padding: const EdgeInsets.only(top: 4),
  //       child: Text(
  //         subtitle,
  //         style: TextStyle(
  //           color: isDarkMode
  //             ? Colors.white.withValues(alpha: 0.6)
  //             : const Color(0xFF64748B),
  //           fontSize: 14,
  //         ),
  //       ),
  //     ),
  //     trailing: Container(
  //       width: 32,
  //       height: 32,
  //       decoration: BoxDecoration(
  //         color: isDarkMode
  //           ? Colors.black
  //           : const Color(0xFFF1F5F9),
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Icon(
  //         Icons.chevron_right_rounded,
  //         color: isDarkMode
  //           ? Colors.white.withValues(alpha: 0.5)
  //           : const Color(0xFF9CA3AF),
  //         size: 20,
  //       ),
  //     ),
  //     onTap: onTap,
  //   );
  // }

  // // Divider widget
  // Widget _buildDivider(bool isDarkMode) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 20),
  //     height: 1,
  //     color: isDarkMode
  //       ? Colors.white.withValues(alpha: 0.1)
  //       : const Color(0xFFE2E8F0),
  //   );
  // }

  // Helper method to get member names
  // String _getMemberName(int index) {
  //   final names = [
  //     'You',
  //     'Alex Johnson',
  //     'Sarah Chen',
  //     'Mike Rodriguez',
  //     'Emma Thompson',
  //     'David Kim',
  //     'Lisa Wang',
  //     'Chris Brown',
  //     'Maya Patel',
  //     'Tom Wilson',
  //     'Anna Garcia',
  //     'Ryan Lee',
  //   ];
  //   return names[index % names.length];
  // }

  // Enhanced dialog methods
  // void _showEditGroupDialog(BuildContext context) {
  //   final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //         title: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Icon(
  //                 Icons.edit_rounded,
  //                 color: Color(0xFF5F299E),
  //                 size: 20,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Text(
  //               'Edit Group',
  //               style: TextStyle(
  //                 color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Text(
  //           'Group editing feature is coming soon! You\'ll be able to change the group name, description, and settings.',
  //           style: TextStyle(
  //             color: isDarkMode
  //               ? Colors.white.withValues(alpha: 0.8)
  //               : const Color(0xFF64748B),
  //             height: 1.5,
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             style: TextButton.styleFrom(
  //               backgroundColor: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //             ),
  //             child: const Text(
  //               'Got it',
  //               style: TextStyle(
  //                 color: Color(0xFF5F299E),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _showAddMembersDialog(BuildContext context) {
  //   final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //         title: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Icon(
  //                 Icons.person_add_rounded,
  //                 color: Color(0xFF5F299E),
  //                 size: 20,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Text(
  //               'Add Members',
  //               style: TextStyle(
  //                 color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Text(
  //           'Invite new members to join "${widget.group['name']}" group. This feature will be available soon!',
  //           style: TextStyle(
  //             color: isDarkMode
  //               ? Colors.white.withValues(alpha: 0.8)
  //               : const Color(0xFF64748B),
  //             height: 1.5,
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             style: TextButton.styleFrom(
  //               backgroundColor: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //             ),
  //             child: const Text(
  //               'Understood',
  //               style: TextStyle(
  //                 color: Color(0xFF5F299E),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  // void _showGroupSettings(BuildContext context) {
  //   final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  //   // showDialog(
  //   //   context: context,
  //   //   builder: (BuildContext context) {
  //   //     return AlertDialog(
  //   //       backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
  //   //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //   //       title: Row(
  //   //         children: [
  //   //           Container(
  //   //             padding: const EdgeInsets.all(8),
  //   //             decoration: BoxDecoration(
  //   //               color: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //   //               borderRadius: BorderRadius.circular(8),
  //   //             ),
  //   //             child: const Icon(
  //   //               Icons.settings_rounded,
  //   //               color: Color(0xFF5F299E),
  //   //               size: 20,
  //   //             ),
  //   //           ),
  //   //           const SizedBox(width: 12),
  //   //           Text(
  //   //             'Group Settings',
  //   //             style: TextStyle(
  //   //               color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
  //   //               fontWeight: FontWeight.bold,
  //   //             ),
  //   //           ),
  //   //         ],
  //   //       ),
  //   //       content: Text(
  //   //         'Advanced group settings including permissions, privacy controls, and moderation tools will be available here.',
  //   //         style: TextStyle(
  //   //           color: isDarkMode
  //   //             ? Colors.white.withValues(alpha: 0.8)
  //   //             : const Color(0xFF64748B),
  //   //           height: 1.5,
  //   //         ),
  //   //       ),
  //   //       actions: [
  //   //         TextButton(
  //   //           onPressed: () => Navigator.pop(context),
  //   //           style: TextButton.styleFrom(
  //   //             backgroundColor: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //   //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //   //           ),
  //   //           child: const Text(
  //   //             'Close',
  //   //             style: TextStyle(
  //   //               color: Color(0xFF5F299E),
  //   //               fontWeight: FontWeight.w600,
  //   //             ),
  //   //           ),
  //   //         ),
  //   //       ],
  //   //     );
  //   //   },
  //   // );
  // }

  // void _showFeatureDialog(BuildContext context, String feature) {
  //   final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //         title: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Icon(
  //                 Icons.info_rounded,
  //                 color: Color(0xFF5F299E),
  //                 size: 20,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Text(
  //               feature,
  //               style: TextStyle(
  //                 color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Text(
  //           '$feature feature is coming soon! We\'re working hard to bring you the best group chat experience.',
  //           style: TextStyle(
  //             color: isDarkMode
  //               ? Colors.white.withValues(alpha: 0.8)
  //               : const Color(0xFF64748B),
  //             height: 1.5,
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             style: TextButton.styleFrom(
  //               backgroundColor: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //             ),
  //             child: const Text(
  //               'Okay',
  //               style: TextStyle(
  //                 color: Color(0xFF5F299E),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _showAllMembers(BuildContext context) {
  //   final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //         title: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Icon(
  //                 Icons.people_rounded,
  //                 color: Color(0xFF5F299E),
  //                 size: 20,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Text(
  //               'All Members',
  //               style: TextStyle(
  //                 color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Text(
  //           'A detailed member list with search and filter options will be available here.',
  //           style: TextStyle(
  //             color: isDarkMode
  //               ? Colors.white.withValues(alpha: 0.8)
  //               : const Color(0xFF64748B),
  //             height: 1.5,
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             style: TextButton.styleFrom(
  //               backgroundColor: const Color(0xFF5F299E).withValues(alpha: 0.1),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //             ),
  //             child: const Text(
  //               'Close',
  //               style: TextStyle(
  //                 color: Color(0xFF5F299E),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}
