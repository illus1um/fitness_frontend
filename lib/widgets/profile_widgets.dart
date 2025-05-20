import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

class ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  
  const ProfileCard({
    Key? key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? ThemeConstants.darkCardBackground 
            : ThemeConstants.lightCardBackground,
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
        boxShadow: isDarkMode 
            ? ThemeConstants.darkElevation
            : ThemeConstants.lightElevation,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ThemeConstants.titleStyle(context),
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  
  const ProfileInfoTile({
    Key? key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: ThemeConstants.subtitleStyle(context),
                ),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: ThemeConstants.bodyStyle(context).copyWith(
                          color: isDarkMode 
                              ? ThemeConstants.darkSubtext 
                              : ThemeConstants.lightSubtext,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        icon ?? Icons.chevron_right,
                        size: 18,
                        color: ThemeConstants.primaryGold,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  
  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.size = 90.0,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size * 2,
        height: size * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode 
              ? ThemeConstants.darkSurface 
              : ThemeConstants.lightSurface,
          boxShadow: isDarkMode 
              ? ThemeConstants.darkElevation
              : ThemeConstants.lightElevation,
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl == null
            ? Icon(
                Icons.person,
                size: size,
                color: isDarkMode 
                    ? ThemeConstants.darkSubtext 
                    : ThemeConstants.lightSubtext,
              )
            : null,
      ),
    );
  }
}

class ProfileDivider extends StatelessWidget {
  final double height;
  final double indent;
  final double endIndent;
  
  const ProfileDivider({
    Key? key,
    this.height = 16.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height / 2),
      child: Divider(
        color: isDarkMode
            ? ThemeConstants.darkDivider
            : ThemeConstants.lightDivider,
        indent: indent,
        endIndent: endIndent,
        height: 1,
      ),
    );
  }
} 