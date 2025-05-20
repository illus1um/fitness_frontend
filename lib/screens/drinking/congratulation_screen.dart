// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:math';

class CongratulationScreen extends StatelessWidget {
  final String username;
  final double dailyTarget;
  final String waterUnit;
  
  CongratulationScreen({
    required this.username,
    required this.dailyTarget,
    required this.waterUnit,
  });
  
  final List<String> _congratsMessages = [
    "Amazing job staying hydrated today!",
    "Hydration champion! Your body thanks you!",
    "Water goal achieved! Your health is winning!",
    "Fantastic! You've completed today's water goal!",
    "Hydration perfection! Keep up the good work!"
  ];
  
  final List<String> _benefitMessages = [
    "You've improved your energy levels and brain function",
    "You've helped boost your physical performance",
    "You've supported optimal kidney function",
    "You've helped maintain healthy skin",
    "You've supported your body's natural detoxification processes"
  ];
  
  String get _randomCongratsMessage => _congratsMessages[Random().nextInt(_congratsMessages.length)];
  String get _randomBenefitMessage => _benefitMessages[Random().nextInt(_benefitMessages.length)];
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF8FAFF);
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final accentColor = Color(0xFFC7A97F); // Gold accent
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy or achievement icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 70,
                    color: accentColor,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Congratulation title
                Text(
                  _randomCongratsMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Details
                Text(
                  "You've reached your daily target of ${dailyTarget.toStringAsFixed(1)} $waterUnit",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Health benefit card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Health Benefit",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        _randomBenefitMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 