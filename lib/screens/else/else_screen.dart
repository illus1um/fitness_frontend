// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/screens/reglog/login_screen.dart';
import 'package:fitness_app/screens/else/myprofilegoal_screen.dart';
import 'package:fitness_app/screens/workout/workout_history_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitness_app/utils/theme_constants.dart';
import 'change_password.dart';


class ElseScreen extends StatefulWidget {
  @override
  _ElseScreenState createState() => _ElseScreenState();
}

class _ElseScreenState extends State<ElseScreen> {
  Map<String, dynamic>? userData;
  final Color goldAccent = Color(0xFFC7A97F);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() {
      userData = null; // Обнуляем перед загрузкой для принудительного обновления UI
    });
    
    var data = await ApiService.getUserProfile();
    if (data != null) {
      print("ElseScreen: loaded user data with avatar_url: ${data['avatar_url']}");
      
      // Для очистки кэша изображений при необходимости
      if (data['avatar_url'] != null && data['avatar_url'].toString().isNotEmpty) {
        final fullUrl = ApiService.fixAvatarUrl(data['avatar_url']);
        if (fullUrl.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(fullUrl);
          data['avatar_url'] = fullUrl;
        }
      }
      
      setState(() {
        userData = data;
      });
    } else {
      print("ElseScreen: failed to load user data");
    }
  }

  void _logout() async {
    bool success = await ApiService.logout();
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF8FAFF);
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? [Color(0xFF121212), Color(0xFF1E1E1E)]
                : [Color(0xFFF9F9F9), Color(0xFFF4F4F4)],
          ),
        ),
        child: userData == null
            ? Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(goldAccent),
              ))
            : SafeArea(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Profile header with improved avatar
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode 
                                  ? Colors.black.withOpacity(0.3) 
                                  : Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Avatar with gradient border
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [goldAccent, goldAccent.withOpacity(0.5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: goldAccent.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(3), // Border thickness
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[200],
                                    child: ClipOval(
                                      child: userData != null && userData!["avatar_url"] != null && userData!["avatar_url"].isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: userData!["avatar_url"],
                                            placeholder: (context, url) => CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(goldAccent),
                                              strokeWidth: 2.0,
                                            ),
                                            errorWidget: (context, url, error) => Icon(
                                              Icons.person, 
                                              size: 50, 
                                              color: isDarkMode ? Colors.white70 : Colors.white,
                                            ),
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          )
                                        : Icon(
                                            Icons.person, 
                                            size: 50, 
                                            color: isDarkMode ? Colors.white70 : Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Welcome, ${userData!["first_name"]}!",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Keep up your fitness journey",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        /// General settings card
                        _buildCard(
                          title: "General",
                          icon: Icons.settings,
                          isDarkMode: isDarkMode,
                          cardColor: cardColor,
                          children: [
                            _buildListTile(
                              Icons.person_outline_rounded,
                              "My Profile & Goal",
                              () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyProfileGoalScreen()),
                                );
                                // Reload user data when returning from MyProfileGoalScreen
                                _loadUserData();
                              },
                              isDarkMode: isDarkMode,
                            ),

                            _buildListTile(
                              Icons.history_rounded, 
                              "My Workouts", 
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => WorkoutHistoryScreen()),
                              ),
                              isDarkMode: isDarkMode,
                            ),

                            _buildListTile(
                              Icons.settings_rounded,
                              "Settings",
                              () => Navigator.pushNamed(context, '/settings'),
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        /// Account card
                        _buildCard(
                          title: "Account",
                          icon: Icons.account_circle_rounded,
                          isDarkMode: isDarkMode,
                          cardColor: cardColor,
                          children: [
                            _buildInfoTile(
                              Icons.email_rounded, 
                              userData!["email"],
                              isDarkMode: isDarkMode
                            ),
                            _buildListTile(
                              Icons.lock_rounded, 
                              "Change Password", 
                              () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => ChangePasswordScreen())
                                );
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildListTile(
                              Icons.exit_to_app_rounded, 
                              "Logout from Account", 
                              _logout, 
                              color: Colors.red[400],
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Redesigned card with title icon
  Widget _buildCard({
    required String title, 
    required List<Widget> children,
    required IconData icon,
    required bool isDarkMode,
    required Color cardColor,
  }) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withOpacity(0.3) 
              : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon, 
                  color: goldAccent,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Improved list tile with theming
  Widget _buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    required bool isDarkMode,
  }) {
    final iconColor = color ?? (isDarkMode ? Colors.white70 : Colors.black87);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color != null 
                ? color.withOpacity(0.1) 
                : goldAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            color: color ?? goldAccent,
            size: 22,
          ),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: iconColor,
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.black12
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded, 
            size: 14, 
            color: iconColor,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text, {required bool isDarkMode}) {
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: goldAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            color: goldAccent,
            size: 22,
          ),
        ),
        title: Text(
          text, 
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
