import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/theme_helper.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        backgroundColor: ThemeHelper.getPrimaryColor(context),
        foregroundColor: Colors.white,
      ),
      backgroundColor: ThemeHelper.getBackgroundColor(context),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your preferred theme mode',
                  style: TextStyle(
                    fontSize: 16,
                    color: ThemeHelper.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Light Theme Option
                _buildThemeOption(
                  context: context,
                  title: 'Light Mode',
                  subtitle: 'Classic light theme',
                  icon: Icons.light_mode,
                  isSelected: themeProvider.isLightMode,
                  onTap: () => themeProvider.setLightTheme(),
                ),
                
                const SizedBox(height: 16),
                
                // Dark Theme Option
                _buildThemeOption(
                  context: context,
                  title: 'Dark Mode',
                  subtitle: 'Easy on the eyes in low light',
                  icon: Icons.dark_mode,
                  isSelected: themeProvider.isDarkMode,
                  onTap: () => themeProvider.setDarkTheme(),
                ),
                
                const SizedBox(height: 16),
                
                // System Theme Option
                _buildThemeOption(
                  context: context,
                  title: 'System Mode',
                  subtitle: 'Follow device system settings',
                  icon: Icons.settings_system_daydream,
                  isSelected: themeProvider.isSystemMode,
                  onTap: () => themeProvider.setSystemTheme(),
                ),
                
                const SizedBox(height: 32),
                
                // Current Theme Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeHelper.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ThemeHelper.getBorderColor(context),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Theme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeHelper.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${themeProvider.currentThemeName} Mode',
                        style: TextStyle(
                          fontSize: 14,
                          color: ThemeHelper.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeHelper.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? ThemeHelper.getPrimaryColor(context)
                : ThemeHelper.getBorderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ThemeHelper.getPrimaryColor(context).withOpacity(0.1)
                    : ThemeHelper.getBorderColor(context, opacity: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? ThemeHelper.getPrimaryColor(context)
                    : ThemeHelper.getSecondaryTextColor(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeHelper.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ThemeHelper.getPrimaryColor(context),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
