import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/screens/drinking/history_screen.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/models/water_intake.dart';
import 'notification_settings_screen.dart';
import 'congratulation_screen.dart';

class DrinkingScreen extends StatefulWidget {
  final String username;
  DrinkingScreen({required this.username});

  @override
  _DrinkingScreenState createState() => _DrinkingScreenState();
}

class _DrinkingScreenState extends State<DrinkingScreen> with SingleTickerProviderStateMixin {
  double dailyWaterTarget = 2.0; // in liters
  double currentWaterIntake = 0.0; // in liters
  // Track the actual water intake (uncapped) for proper undo/redo
  double actualWaterIntake = 0.0; 
  List<WaterIntakeRecord> _intakeHistory = [];
  List<WaterIntakeRecord> _undoHistory = [];
  String _waterUnit = 'L';
  static const double _litersToFlOz = 33.814;
  bool _targetReachedAndCongratulated = false;
  bool _isLoading = true;
  String _today = DateTime.now().toIso8601String().substring(0, 10);
  
  // Colors
  final Color primaryColor = Color(0xFF4A6FE7); // Original blue primary
  final Color primaryLightColor = Color(0xFF6B8FF8); // Original light blue
  final Color secondaryColor = Color(0xFF2CC2EA); // Original cyan secondary
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
    setState(() {
      _isLoading = true;
    });
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final profile = await ApiService.getUserProfile();

    // Load unit
    _waterUnit = prefs.getString('water_unit') ?? 'L';

    if (profile != null) {
      double weight = profile["weight"] ?? 70.0;
      int age = profile["age"] ?? 25;
      bool isMale = profile["gender"] ?? true;

      double calculatedWaterTarget = _calculateDailyWaterTarget(weight, age, isMale);
      
      // Get today's water intake from the server
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final dailyIntake = await ApiService.getDailyWaterIntake(today);
      
      if (dailyIntake != null) {
        setState(() {
          _today = today;
          currentWaterIntake = dailyIntake.totalAmount;
          actualWaterIntake = dailyIntake.totalAmount;
          _intakeHistory = dailyIntake.records;
          
          // Check if target has been reached
          _targetReachedAndCongratulated = currentWaterIntake >= calculatedWaterTarget;
        });
      } else {
        setState(() {
          _today = today;
          currentWaterIntake = 0.0;
          actualWaterIntake = 0.0;
          _intakeHistory = [];
          _undoHistory = [];
          _targetReachedAndCongratulated = false;
        });
      }

      setState(() {
        dailyWaterTarget = calculatedWaterTarget;
        _isLoading = false;
      });
      
      // Initialize progress animation
      _progressController.value = currentWaterIntake / dailyWaterTarget;
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateDailyWaterTarget(double weight, int age, bool isMale) {
    double baseWater = isMale ? weight * 0.035 : weight * 0.031;
    if (age > 30 && age <= 55) baseWater *= 0.95;
    else if (age > 55) baseWater *= 0.90;
    return double.parse(baseWater.toStringAsFixed(2));
  }

  Future<void> _updateWaterIntake(double amountLiters, {bool isRedo = false}) async {
    if (amountLiters <= 0) return;
    
    // Don't add more water if target is already reached
    if (currentWaterIntake >= dailyWaterTarget) return;
    
    // Calculate actual intake (uncapped) and displayed intake (capped at target)
    double newActualIntake = actualWaterIntake + amountLiters;
    double newDisplayedIntake = min(newActualIntake, dailyWaterTarget);
    
    // Create new record with the requested amount (for accurate undo/redo)
    WaterIntakeRecord newRecord = WaterIntakeRecord(
      amount: amountLiters, 
      timestamp: DateTime.now()
    );
    
    // First update locally for immediate UI feedback
    setState(() {
      _isAdding = true;
      _intakeHistory.add(newRecord);
      // Only clear undo history for new additions, not for redos
      if (!isRedo) {
        _undoHistory.clear();
      }
      actualWaterIntake = newActualIntake;
      currentWaterIntake = newDisplayedIntake;
    });
    
    // Animate to new value
    double startValue = _progressController.value;
    double endValue = newDisplayedIntake / dailyWaterTarget;
    
    _progressController.value = startValue;
    _progressController.animateTo(endValue).then((_) {
      setState(() {
        _isAdding = false;
      });
    });
    
    // Save to server
    bool success = await ApiService.addWaterIntake(newDisplayedIntake, records: [newRecord]);
    if (!success) {
      // If server update fails, show error and revert local changes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update water intake. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Revert local changes if server update fails
      setState(() {
        _intakeHistory.removeLast();
        actualWaterIntake = actualWaterIntake - amountLiters;
        currentWaterIntake = min(actualWaterIntake, dailyWaterTarget);
      });
      
      // Also revert animation
      _progressController.animateTo(currentWaterIntake / dailyWaterTarget);
      return;
    }
    
    // Check if target is reached for the first time and show congratulation screen
    if (newDisplayedIntake >= dailyWaterTarget && !_targetReachedAndCongratulated && !isRedo) {
      // Update state to disable undo
      setState(() {
        _targetReachedAndCongratulated = true;
      });
      
      // Show congratulation screen with a small delay to allow animation to finish
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CongratulationScreen(
              username: widget.username,
              dailyTarget: dailyWaterTarget,
              waterUnit: _waterUnit,
            ),
          ),
        );
      });
    }
  }

  Future<void> _undoLastIntake() async {
    // Don't allow undo if target has been reached and congratulated
    if (_targetReachedAndCongratulated) return;
    
    if (_intakeHistory.isEmpty) return;
    
    // Get the last record
    WaterIntakeRecord lastRecord = _intakeHistory.last;
    double lastAmount = lastRecord.amount;
    
    // Update actual intake
    double newActualIntake = max(0, actualWaterIntake - lastAmount);
    // Calculate new displayed intake (capped at target)
    double newDisplayedIntake = min(newActualIntake, dailyWaterTarget);
    
    // First update locally for immediate UI feedback
    setState(() {
      _intakeHistory.removeLast();
      _undoHistory.add(lastRecord);
      actualWaterIntake = newActualIntake;
      currentWaterIntake = newDisplayedIntake;
    });
    
    // Animate to new value
    double startValue = _progressController.value;
    double endValue = newDisplayedIntake / dailyWaterTarget;
    
    _progressController.value = startValue;
    _progressController.animateTo(endValue);
    
    // If the record has an ID (saved to server), delete it
    if (lastRecord.id != null) {
      bool success = await ApiService.deleteWaterRecord(lastRecord.id!);
      if (!success) {
        // If server update fails, show error and revert local changes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to undo. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Revert local changes
        setState(() {
          _undoHistory.removeLast();
          _intakeHistory.add(lastRecord);
          actualWaterIntake = actualWaterIntake + lastAmount;
          currentWaterIntake = min(actualWaterIntake, dailyWaterTarget);
        });
        
        // Also revert animation
        _progressController.animateTo(currentWaterIntake / dailyWaterTarget);
        return;
      }
    }
    
    // Update the daily total on the server
    await ApiService.addWaterIntake(newDisplayedIntake);
  }

  Future<void> _redoLastIntake() async {
    if (_undoHistory.isEmpty) return;
    
    // Get the record without removing it yet
    WaterIntakeRecord recordToRedo = _undoHistory.last;
    
    // Only remove from undo history if the add will be successful
    if (currentWaterIntake < dailyWaterTarget) {
      _undoHistory.removeLast();
      await _updateWaterIntake(recordToRedo.amount, isRedo: true);
    }
  }

  double _convertToDisplay(double liters) {
    return _waterUnit == 'fl oz' ? liters * _litersToFlOz : liters;
  }

  String get _unitLabel => _waterUnit;

  void _showAmountSelectionSheet() {
    // Don't show the sheet if target is already reached
    if (currentWaterIntake >= dailyWaterTarget) return;
    
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
    
    final isTargetReached = currentWaterIntake >= dailyWaterTarget;
    
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: goldAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(username: widget.username),
                ),
              ).then((_) => _loadUserData()); // Reload data when returning from history
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
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(goldAccent),
                ),
                SizedBox(height: 20),
                Text(
                  "Loading your water data...",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : SafeArea(
            child: RefreshIndicator(
              color: goldAccent,
              onRefresh: _loadUserData,
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
                                                progressColor: Color(0xFF4D77E8),
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
                                              color: Color(0xFF4D77E8),
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
                              child: Stack(
                                children: [
                                  AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (context, child) {
                                      return Positioned(
                                        bottom: 0,
                                        left: 0, 
                                        right: 0,
                                        height: 160 * _progressController.value,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(24),
                                            bottomRight: Radius.circular(24),
                                            topLeft: _progressController.value >= 0.99 ? Radius.circular(24) : Radius.zero,
                                            topRight: _progressController.value >= 0.99 ? Radius.circular(24) : Radius.zero,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0xFF39C2EA), // Slightly adjusted secondary
                                                  Color(0xFF4D77E8), // Matching indicator
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
                                      );
                                    },
                                  ),
                                  
                                  // Goal achieved indicator
                                  if (_targetReachedAndCongratulated || progress >= 1.0)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: goldAccent,
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(24),
                                            bottomLeft: Radius.circular(24),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.emoji_events_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "Goal Achieved!",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
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
                                  backgroundColor: isTargetReached ? Colors.grey : goldAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: isTargetReached ? null : _showAmountSelectionSheet,
                                child: Text(
                                  "Custom Add",
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Health title with icon
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.red[400],
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "Insights",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(width: 4), // Small gap
                                
                                // Achievement indicator - adapt to available space
                                if (_targetReachedAndCongratulated || progress >= 1.0)
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: goldAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: goldAccent,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              "Goal Met",
                                              style: TextStyle(
                                                color: goldAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                    "Today's Activity",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    "${_intakeHistory.length} records",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              Text(
                                "Water intake by time of day",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Показываем все интейки за день с точным временем
                              Container(
                                height: min(240, _intakeHistory.length * 70.0), // Cap height
                                child: ListView.builder(
                                  physics: BouncingScrollPhysics(),
                                  itemCount: _intakeHistory.length,
                                  reverse: true, // Newest first
                                  itemBuilder: (context, index) {
                                    // Get record in reverse order (newest first)
                                    WaterIntakeRecord record = _intakeHistory[_intakeHistory.length - 1 - index];
                                    String displayAmount = _convertToDisplay(record.amount).toStringAsFixed(1);
                                
                                    // Format time as hour:minute AM/PM
                                    String formattedTime = _formatTime(record.timestamp);
                                    
                                    // Determine icon based on time of day
                                    IconData timeIcon;
                                    Color timeColor;
                                    
                                    int hour = record.timestamp.hour;
                                    if (hour >= 5 && hour < 12) {
                                      timeIcon = Icons.wb_sunny_outlined;
                                      timeColor = Colors.amber;
                                    } else if (hour >= 12 && hour < 17) {
                                      timeIcon = Icons.wb_sunny;
                                      timeColor = Colors.orange;
                                    } else if (hour >= 17 && hour < 21) {
                                      timeIcon = Icons.wb_twilight;
                                      timeColor = Colors.deepOrange;
                                    } else {
                                      timeIcon = Icons.nights_stay;
                                      timeColor = Colors.indigo;
                                    }
                                    
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? Color(0xFF252A36).withOpacity(0.5) : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            // Time icon
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: timeColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                timeIcon,
                                                color: timeColor,
                                                size: 22,
                                              ),
                                            ),
                                            SizedBox(width: 14),
                                            
                                            // Time and amount info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    formattedTime,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "Added $displayAmount $_unitLabel",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Water drop indicator showing relative amount
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Center(
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.water_drop,
                                                      color: primaryColor,
                                                      size: min(28, 16 + (record.amount / dailyWaterTarget) * 24),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
          ),
      bottomNavigationBar: _buildActionButtonBar(),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, double amount, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTargetReached = currentWaterIntake >= dailyWaterTarget;
    
    return Container(
      height: 110,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF252A36).withOpacity(0.5) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        // Add a semi-transparent overlay when target is reached
        gradient: isTargetReached ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
            isDarkMode ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
          ],
        ) : null,
      ),
      child: InkWell(
        onTap: isTargetReached ? null : () => _updateWaterIntake(amount),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isTargetReached ? (isDarkMode ? Colors.grey[600] : Colors.grey[400]) : color, 
              size: 24
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isTargetReached 
                  ? (isDarkMode ? Colors.grey[600] : Colors.grey[400])
                  : (isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),
            SizedBox(height: 4),
            Text(
              "${_convertToDisplay(amount).toStringAsFixed(1)} $_unitLabel",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isTargetReached
                  ? (isDarkMode ? Colors.grey[700] : Colors.grey[400])
                  : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
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
    
    return SizedBox(
      height: 60, // Further reduced height
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, -2),
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
      ),
    );
  }
  
  Widget _buildBottomBarButton(IconData icon, String label, Function onTap, bool enabled, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Disable undo button if target has been reached and congratulated
    if (label == "Undo" && _targetReachedAndCongratulated) {
      enabled = false;
    }
    
    return InkWell(
      onTap: enabled ? () => onTap() : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Further reduced padding
        decoration: BoxDecoration(
          color: enabled 
            ? (isDarkMode ? Colors.grey[800] : color.withOpacity(0.1))
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: enabled 
            ? Border.all(color: color, width: 1.0) // Reduced border width
            : Border.all(color: Colors.transparent),
        ),
        child: Row(  // Changed from Column to Row layout
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled 
                ? color 
                : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
              size: 22, // Further reduced icon size
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: enabled 
                  ? (isDarkMode ? Colors.white : Colors.black87)
                  : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Функция для форматирования времени
  String _formatTime(DateTime time) {
    int hours = time.hour;
    int minutes = time.minute;
    String period = hours >= 12 ? "PM" : "AM";
    hours = hours % 12;
    hours = hours == 0 ? 12 : hours;
    String minuteStr = minutes < 10 ? "0$minutes" : "$minutes";
    return "$hours:$minuteStr $period";
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
    // Start at the top left instead of bottom
    path.moveTo(0, 0);
    
    // Draw waves at the top of the water
    for (int i = 0; i < width; i++) {
      final angle = (animationValue * 2 * pi) + (i / width * 4 * pi);
      // Waves at the top (0 + wave height)
      final y = sin(angle) * 3; // Reduced amplitude for subtler effect
      path.lineTo(i.toDouble(), y);
    }
    
    // Complete the path by going around the bottom of the container
    path.lineTo(width, 0);
    path.lineTo(width, height);
    path.lineTo(0, height);
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