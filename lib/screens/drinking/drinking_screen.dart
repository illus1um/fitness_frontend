import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/screens/drinking/history_screen.dart';
import 'package:fitness_app/services/api_service.dart';
import 'notification_settings_screen.dart';

class DrinkingScreen extends StatefulWidget {
  final String username;
  DrinkingScreen({required this.username});

  @override
  _DrinkingScreenState createState() => _DrinkingScreenState();
}

class _DrinkingScreenState extends State<DrinkingScreen> with SingleTickerProviderStateMixin {
  double dailyWaterTarget = 2.0; // in liters
  double currentWaterIntake = 0.0; // in liters
  List<double> _intakeHistory = [];
  List<double> _undoHistory = [];
  String _waterUnit = 'L';
  static const double _litersToFlOz = 33.814;
  
  // Colors
  final Color primaryColor = Color(0xFF4A6FE7); // Blue primary
  final Color primaryLightColor = Color(0xFF6B8FF8); // Light blue
  final Color secondaryColor = Color(0xFF2CC2EA); // Cyan secondary
  final Color goldAccent = Color(0xFFC7A97F); // Gold accent from original design
  final Color accentColor = Color(0xFFFF6B6B); // Red accent for important actions
  
  // Animation controllers
  late AnimationController _progressController;
  bool _isAdding = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final profile = await ApiService.getUserProfile();

    // Load unit
    _waterUnit = prefs.getString('water_unit') ?? 'L';

    if (profile != null) {
      double weight = profile["weight"] ?? 70.0;
      int age = profile["age"] ?? 25;
      bool isMale = profile["gender"] ?? true;

      double calculatedWaterTarget = _calculateDailyWaterTarget(weight, age, isMale);

      String userKey = "water_${widget.username}";
      String dateKey = "date_${widget.username}";

      String today = DateTime.now().toIso8601String().substring(0, 10);
      String? savedDate = prefs.getString(dateKey);

      if (savedDate != today) {
        double yesterdayIntake = prefs.getDouble(userKey) ?? 0.0;
        await _saveToHistory(savedDate ?? today, yesterdayIntake);
        await prefs.setDouble(userKey, 0.0);
        await prefs.setString(dateKey, today);
        currentWaterIntake = 0.0;
      } else {
        currentWaterIntake = prefs.getDouble(userKey) ?? 0.0;
      }

      setState(() {
        dailyWaterTarget = calculatedWaterTarget;
      });
      
      // Initialize progress animation
      _progressController.value = currentWaterIntake / dailyWaterTarget;
    }
  }

  double _calculateDailyWaterTarget(double weight, int age, bool isMale) {
    double baseWater = isMale ? weight * 0.035 : weight * 0.031;
    if (age > 30 && age <= 55) baseWater *= 0.95;
    else if (age > 55) baseWater *= 0.90;
    return double.parse(baseWater.toStringAsFixed(2));
  }

  Future<void> _updateWaterIntake(double amountLiters) async {
    if (amountLiters <= 0) return;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userKey = "water_${widget.username}";
    
    double newIntake = min(currentWaterIntake + amountLiters, dailyWaterTarget);
    
    // Animate the progress change
    setState(() {
      _isAdding = true;
      _intakeHistory.add(amountLiters);
      _undoHistory.clear();
    });
    
    // Animate to new value
    double startValue = _progressController.value;
    double endValue = newIntake / dailyWaterTarget;
    
    Animation<double> animation = Tween<double>(
      begin: startValue,
      end: endValue,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressController.value = startValue;
    _progressController.animateTo(endValue).then((_) {
      setState(() {
        _isAdding = false;
      });
    });
    
    setState(() {
      currentWaterIntake = newIntake;
    });
    
    await prefs.setDouble(userKey, newIntake);
    
    // Also update the timestamp of the day to maintain daily history
    String dateKey = "date_${widget.username}";
    String today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(dateKey, today);
  }

  Future<void> _undoLastIntake() async {
    if (_intakeHistory.isEmpty) return;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userKey = "water_${widget.username}";
    
    // Move lastAmount declaration outside setState
    double lastAmount = _intakeHistory.removeLast();
    double newIntake = max(0, currentWaterIntake - lastAmount);
    
    // Add to undo history
    setState(() {
      _undoHistory.add(lastAmount);
    });
    
    // Animate to new value
    double startValue = _progressController.value;
    double endValue = newIntake / dailyWaterTarget;
    
    Animation<double> animation = Tween<double>(
      begin: startValue,
      end: endValue,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInCubic,
    ));
    
    _progressController.value = startValue;
    _progressController.animateTo(endValue);
    
    setState(() {
      currentWaterIntake = newIntake;
    });
    
    await prefs.setDouble(userKey, newIntake);
  }

  Future<void> _redoLastIntake() async {
    if (_undoHistory.isEmpty) return;
    
    double redoAmount = _undoHistory.removeLast();
    await _updateWaterIntake(redoAmount);
  }

  Future<void> _saveToHistory(String date, double intake) async {
    if (intake == 0.0) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String historyKey = "history_${widget.username}";

    Map<String, dynamic> history = {};
    String? historyJson = prefs.getString(historyKey);

    if (historyJson != null) {
      history = json.decode(historyJson);
    }

    history[date] = intake;
    await prefs.setString(historyKey, json.encode(history));
  }

  double _convertToDisplay(double liters) {
    return _waterUnit == 'fl oz' ? liters * _litersToFlOz : liters;
  }

  String get _unitLabel => _waterUnit;

  void _showAmountSelectionSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // Initialize with a state variable that can be referenced in callbacks
    double _selectedAmount = _waterUnit == 'L' ? 0.10 : 3.0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Make the content scrollable to avoid overflow
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              "Add Water",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Select the amount of water you drank",
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            
                            SizedBox(height: 40),
                            
                            // Amount display with animation
                            Container(
                              width: 160,
                              height: 160,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _selectedAmount.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    Text(
                                      _unitLabel,
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: primaryColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Custom amount slider
                            Text(
                              "Custom Amount",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: goldAccent,
                                inactiveTrackColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                thumbColor: goldAccent,
                                trackHeight: 8,
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                              ),
                              child: Slider(
                                value: _selectedAmount,
                                min: _waterUnit == 'L' ? 0.1 : 3.0,
                                max: _waterUnit == 'L' ? 2.0 : 64.0,
                                divisions: _waterUnit == 'L' ? 19 : 61, // 19 divisions for 0.1 increments from 0.1 to 2.0
                                onChanged: (value) {
                                  // Round to nearest 0.1
                                  double roundedValue = (_waterUnit == 'L') 
                                      ? (value * 10).round() / 10 
                                      : double.parse(value.toStringAsFixed(1));
                                      
                                  setModalState(() {
                                    _selectedAmount = roundedValue;
                                  });
                                },
                              ),
                            ),
                            
                            SizedBox(height: 40),
                            
                            // Add button using gold accent
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: goldAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  double amountLiters = _waterUnit == 'fl oz'
                                      ? _selectedAmount / _litersToFlOz
                                      : _selectedAmount;
                                  Navigator.pop(context);
                                  _updateWaterIntake(amountLiters);
                                },
                                child: Text(
                                  "Add Water",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Add extra padding at the bottom to ensure everything is visible
                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final progress = currentWaterIntake / dailyWaterTarget;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF8FAFF);
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // Display values
    final displayIntake = _convertToDisplay(currentWaterIntake).toStringAsFixed(1);
    final displayTarget = _convertToDisplay(dailyWaterTarget).toStringAsFixed(1);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Water Tracker",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: goldAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(username: widget.username),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_rounded, color: goldAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsScreen(username: widget.username),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's summary and status card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Hydration",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    displayIntake,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "/ $displayTarget $_unitLabel",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Completely redesigned percentage indicator
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  isDarkMode ? Color(0xFF2F3443) : Colors.white,
                                  isDarkMode ? Color(0xFF212730) : Color(0xFFF8F9FA),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode 
                                    ? Colors.black.withOpacity(0.2) 
                                    : Colors.grey.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(6),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Modern circular progress
                                SizedBox(
                                  width: 68,
                                  height: 68,
                                  child: AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: CircularProgressPainter(
                                          progress: _progressController.value,
                                          progressColor: primaryColor,
                                          backgroundColor: isDarkMode 
                                            ? Color(0xFF3A3F50).withOpacity(0.3) 
                                            : Colors.grey[200]!,
                                          strokeWidth: 8.0,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // Percentage text with modern styling - properly centered
                                Container(
                                  padding: EdgeInsets.all(4),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFF252A36) : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${(progress * 100).toInt()}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Water visualization - matching the screenshot
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Water fill with rounded top corners (per screenshot)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    height: 160 * _progressController.value,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          secondaryColor.withOpacity(0.8),
                                          primaryColor.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: WavePainter(
                                        _progressController.value,
                                        Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Quick actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              "Small",
                              Icons.local_drink_rounded,
                              0.2,
                              primaryLightColor,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              "Medium",
                              Icons.water_rounded,
                              0.4,
                              primaryColor,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              "Large",
                              Icons.sports_bar_rounded,
                              0.6,
                              secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Add Water button below the quick action buttons - full width matching the 3 buttons above
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _showAmountSelectionSheet,
                          child: Text(
                            "Add Water",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Health insights card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
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
                          Icon(
                            Icons.favorite_rounded,
                            color: goldAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Health Insights",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Benefits of water
                      ...List.generate(3, (index) {
                        List<String> benefits = [
                          "Proper hydration improves energy levels and brain function",
                          "Drinking water before meals can help reduce overall calorie intake",
                          "Staying hydrated may help prevent headaches and migraines",
                        ];
                        
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: goldAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: goldAccent,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  benefits[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Recent activity - Simplified and improved
                if (_intakeHistory.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Activity",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HistoryScreen(username: widget.username),
                                  ),
                                );
                              },
                              child: Text(
                                "View History",
                                style: TextStyle(
                                  color: goldAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Recent activity list
                        ...List.generate(min(3, _intakeHistory.length), (index) {
                          double amount = _intakeHistory[_intakeHistory.length - 1 - index];
                          String displayAmount = _convertToDisplay(amount).toStringAsFixed(2);
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.water_drop_rounded,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Added Water",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        "You added $displayAmount $_unitLabel",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${index == 0 ? 'Just now' : '${index * 5 + 5} min ago'}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildActionButtonBar(),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, double amount, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 110,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF252A36).withOpacity(0.5) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _updateWaterIntake(amount),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "${_convertToDisplay(amount).toStringAsFixed(1)} $_unitLabel",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtonBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF1A1A1A) : Colors.white;
    
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomBarButton(
            Icons.undo_rounded,
            "Undo",
            _undoLastIntake,
            _intakeHistory.isNotEmpty,
            goldAccent,  // Using gold accent
          ),
          SizedBox(width: 20), 
          _buildBottomBarButton(
            Icons.redo_rounded,
            "Redo",
            _redoLastIntake,
            _undoHistory.isNotEmpty,
            goldAccent,  // Using gold accent
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBarButton(IconData icon, String label, Function onTap, bool enabled, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: enabled ? () => onTap() : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: enabled 
                ? color 
                : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled 
                  ? (isDarkMode ? Colors.white70 : Colors.black87)
                  : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom wave painter to add wave effect to the water
class WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double animationValue = DateTime.now().millisecondsSinceEpoch % 2000 / 2000;
  
  WavePainter(this.progress, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    
    final path = Path();
    path.moveTo(0, height);
    
    // Smaller, more subtle wave pattern
    for (int i = 0; i < width; i++) {
      final angle = (animationValue * 2 * pi) + (i / width * 4 * pi);
      final y = height - sin(angle) * 3; // Reduced amplitude for subtler effect
      path.lineTo(i.toDouble(), y);
    }
    
    path.lineTo(width, height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom circular progress painter with rounded caps and smooth edges
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  
  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}