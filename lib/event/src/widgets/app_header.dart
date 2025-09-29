import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    this.title = 'Event App',
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing based on screen width
    double getTitleFontSize() {
      if (screenWidth > 900) return 20; // Reduced for web screens
      if (screenWidth > 600) return 18;
      return 16;
    }
    
    double getIconSize() {
      if (screenWidth > 900) return 20; // Reduced for web screens
      if (screenWidth > 600) return 18;
      return 16;
    }
    
    double getHeaderHeight() {
      if (screenWidth > 900) return 60;
      if (screenWidth > 600) return 55;
      return 50;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: getHeaderHeight(),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, 
            vertical: screenHeight * 0.01
          ),
          child: Row(
            children: [
              // Leading widget or back button
              if (showBackButton)
                Container(
                  margin: EdgeInsets.only(right: screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: getIconSize(),
                    ),
                    onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  ),
                )
              else if (leading != null)
                Container(
                  margin: EdgeInsets.only(right: screenWidth * 0.03),
                  child: leading,
                ),
              
              // Title section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: getTitleFontSize(),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions section
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!.map((action) {
                    if (action is IconButton) {
                      return Container(
                        margin: EdgeInsets.only(left: screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            (action.icon as Icon).icon,
                            color: Colors.white,
                            size: getIconSize(),
                          ),
                          onPressed: action.onPressed,
                        ),
                      );
                    }
                    return Container(
                      margin: EdgeInsets.only(left: screenWidth * 0.02),
                      child: action,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(104);
}
