import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/screens/drinking/history_screen.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
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
  String _waterUnit = 'L'; // added
  static const double _litersToFlOz = 33.814;
  final Color goldAccent = Color(0xFFC7A97F);
  bool _animateWater = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Start animation after a short delay to ensure proper rendering
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _animateWater = true;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final profile = await ApiService.getUserProfile();

    // load unit
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
        _animateWater = true;
      });
    }
  }

  double _calculateDailyWaterTarget(double weight, int age, bool isMale) {
    double baseWater = isMale ? weight * 0.035 : weight * 0.031;
    if (age > 30 && age <= 55) baseWater *= 0.95;
    else if (age > 55) baseWater *= 0.90;
    return double.parse(baseWater.toStringAsFixed(2));
  }

  Future<void> _updateWaterIntake(double amountLiters) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userKey = "water_${widget.username}";

    setState(() {
      _intakeHistory.add(amountLiters);
      currentWaterIntake = min(currentWaterIntake + amountLiters, dailyWaterTarget);
      _undoHistory.clear();
      _animateWater = false;
    });

    await prefs.setDouble(userKey, currentWaterIntake);
    
    // Trigger animation after a short delay
    Future.delayed(Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _animateWater = true;
        });
      }
    });
  }

  Future<void> _undoLastIntake() async {
    if (_intakeHistory.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userKey = "water_${widget.username}";

      setState(() {
        double lastAmount = _intakeHistory.removeLast();
        _undoHistory.add(lastAmount);
        currentWaterIntake = max(0, currentWaterIntake - lastAmount);
        _animateWater = false;
      });

      await prefs.setDouble(userKey, currentWaterIntake);
      
      // Trigger animation after a short delay
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _animateWater = true;
          });
        }
      });
    }
  }

  Future<void> _redoLastIntake() async {
    if (_undoHistory.isNotEmpty) {
      double redoAmount = _undoHistory.removeLast();
      await _updateWaterIntake(redoAmount);
    }
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

  void _showCustomWaterDialog() {
    TextEditingController customController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // Initial slider value (in liters or fl oz depending on user's preference)
    double sliderValue = _waterUnit == 'L' ? 0.5 : 16.0;
    double minValue = _waterUnit == 'L' ? 0.1 : 3.0;
    double maxValue = _waterUnit == 'L' ? 1.5 : 50.0;
    int divisions = _waterUnit == 'L' ? 14 : 47;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode 
                    ? [Color(0xFF2D2D2D), Color(0xFF1A1A1A)]
                    : [Colors.white, Color(0xFFF5F5F5)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Add Custom Amount",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Slide to select the amount of water",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  
                  // Water amount display
                  Text(
                    "${sliderValue.toStringAsFixed(1)} $_unitLabel",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: goldAccent,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Water drop icon that changes size based on slider value
                  Icon(
                    Icons.water_drop,
                    color: goldAccent,
                    size: 24 + (sliderValue / maxValue) * 40,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Slider for selecting water amount
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: goldAccent,
                      inactiveTrackColor: isDarkMode 
                        ? Colors.grey[800] 
                        : Colors.grey[300],
                      thumbColor: goldAccent,
                      overlayColor: goldAccent.withOpacity(0.2),
                      trackHeight: 8,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
                    ),
                    child: Slider(
                      value: sliderValue,
                      min: minValue,
                      max: maxValue,
                      divisions: divisions,
                      onChanged: (newValue) {
                        setState(() {
                          sliderValue = double.parse(newValue.toStringAsFixed(1));
                        });
                      },
                    ),
                  ),
                  
                  // Min and max labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${minValue.toStringAsFixed(1)} $_unitLabel",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          "${maxValue.toStringAsFixed(1)} $_unitLabel",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("CANCEL", style: TextStyle(fontSize: 16, letterSpacing: 1)),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            double amountLiters = _waterUnit == 'fl oz'
                                ? sliderValue / _litersToFlOz
                                : sliderValue;
                            if (amountLiters > 0) {
                              _updateWaterIntake(amountLiters);
                            }
                            Navigator.pop(context);
                          },
                          child: Text("ADD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  double _convertToDisplay(double liters) {
    return _waterUnit == 'fl oz' ? liters * _litersToFlOz : liters;
  }

  String get _unitLabel => _waterUnit;

  Widget _buildQuickAddButton(String label, double amountLiters, IconData icon, {Color? color}) {
    final displayValue = _convertToDisplay(amountLiters).toStringAsFixed(1);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _updateWaterIntake(amountLiters),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (color ?? goldAccent).withOpacity(0.8),
              (color ?? goldAccent),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (color ?? goldAccent).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            SizedBox(height: 8),
            Text(
              '$displayValue $_unitLabel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Function onTap, IconData icon, {bool isUndo = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF2D2D2D) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUndo ? Colors.red.withOpacity(0.1) : goldAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isUndo ? Colors.red : goldAccent,
                size: 28,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header row with goal info and percentage
  Widget _buildHeaderRow(bool isDarkMode, String displayTarget, double progress, Color textColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: goldAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.water_drop,
            color: goldAccent,
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Daily Goal",
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              "$displayTarget $_unitLabel",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        Spacer(),
        Text(
          "${(progress * 100).toInt()}%",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: goldAccent,
          ),
        ),
      ],
    );
  }

  // Water bottle visualization
  Widget _buildWaterBottle(double screenHeight, double progress, bool isDarkMode, String displayIntake, Color textColor) {
    return Container(
      height: screenHeight * 0.35,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Bottle outline
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 2,
              ),
            ),
          ),
          
          // Water wave animation
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                height: _animateWater ? (screenHeight * 0.35) * min(progress, 1.0) : 0,
                width: double.infinity,
                child: WaveWidget(
                  config: CustomConfig(
                    gradients: [
                      [Color(0xFF5AA9E6), Color(0xFF7FC8F8)],
                      [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                    ],
                    durations: [7000, 5000],
                    heightPercentages: [0.65, 0.66],
                    gradientBegin: Alignment.bottomLeft,
                    gradientEnd: Alignment.topRight,
                  ),
                  waveAmplitude: 20,
                  size: Size(double.infinity, double.infinity),
                ),
              ),
            ),
          ),
          
          // Water amount indicator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$displayIntake",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "$_unitLabel consumed",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Measurement marks on the bottle
          ...List.generate(5, (index) {
            return Positioned(
              left: 0,
              right: 0,
              bottom: (screenHeight * 0.35) * (index / 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${(dailyWaterTarget * (index / 4)).toStringAsFixed(1)}",
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 10,
                    height: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final displayIntake = _convertToDisplay(currentWaterIntake).toStringAsFixed(1);
    final displayTarget = _convertToDisplay(dailyWaterTarget).toStringAsFixed(1);
    final progress = currentWaterIntake / dailyWaterTarget;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF5F7FA);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Water Tracker",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: goldAccent),
            tooltip: "Notification Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsScreen(username: widget.username),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.history, color: goldAccent),
            tooltip: "History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(username: widget.username),
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header and goal info
                _buildHeaderRow(isDarkMode, displayTarget, progress, textColor),
                
                SizedBox(height: 30),
                
                // Water bottle visualization
                _buildWaterBottle(screenHeight, progress, isDarkMode, displayIntake, textColor),
                
                SizedBox(height: 30),
                
                // Quick add section title
                Center(
                  child: Text(
                    "Quick Add",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Quick add buttons - centered in a Column with Wrap
                Center(
                  child: Column(
                    children: [
                      // First row - water amount buttons
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildQuickAddButton("Small Cup", 0.1, Icons.local_cafe, color: Color(0xFF5AA9E6)),
                          _buildQuickAddButton("Glass", 0.3, Icons.local_drink, color: Color(0xFF56CCF2)),
                          _buildQuickAddButton("Bottle", 0.5, Icons.sports_bar, color: Color(0xFF2F80ED)),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Second row - action buttons
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildActionButton("Custom", _showCustomWaterDialog, Icons.add),
                          _buildActionButton("Undo", _undoLastIntake, Icons.undo, isUndo: true),
                          _buildActionButton("Redo", _redoLastIntake, Icons.redo),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Tips section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: goldAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: goldAccent,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hydration Tip",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Drinking water before meals can help reduce your overall calorie intake and support weight management.",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}