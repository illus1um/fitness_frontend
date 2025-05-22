import 'package:flutter/material.dart';
import '../../utils/exercise_data_fixer.dart';
import '../../services/plan_cache.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseDataFixScreen extends StatefulWidget {
  const ExerciseDataFixScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseDataFixScreen> createState() => _ExerciseDataFixScreenState();
}

class _ExerciseDataFixScreenState extends State<ExerciseDataFixScreen> {
  bool _isFixing = false;
  bool _isFixComplete = false;
  bool _isApplying = false;
  bool _isApplyComplete = false;
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color(0xFFC7A97F);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Fix Exercise Data'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Information card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What does this tool do?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This tool automatically fixes exercise metadata:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildFeatureItem('Removes "At home" tag for gym-required exercises'),
                  _buildFeatureItem('Adds "At home" tag to home-friendly exercises'),
                  _buildFeatureItem('Fixes difficulty levels for advanced exercises'),
                  _buildFeatureItem('Adds "Beginner" tag to basic exercises'),
                  SizedBox(height: 15),
                  Text(
                    'After fixing, exercises will be properly filtered when creating workout plans.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Progress bar
            if (_isFixing || _isApplying)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            
            // Completion message
            if (_isFixComplete && !_isApplying && !_isApplyComplete)
              Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Data successfully fixed! Click "Apply Fixes" to update the database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
            if (_isApplyComplete)
              Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Fixes successfully applied! Please restart the app to see the changes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Buttons
            ElevatedButton(
              onPressed: (_isFixing || _isApplying || _isFixComplete) ? null : _startFixing,
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                'Fix Exercise Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: 15),
            
            ElevatedButton(
              onPressed: (_isFixing || _isApplying || !_isFixComplete || _isApplyComplete) ? null : _applyFixes,
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                'Apply Fixes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  
  Future<void> _startFixing() async {
    setState(() {
      _isFixing = true;
      _statusMessage = 'Analyzing exercise database...';
      _progress = 0.1;
    });
    
    // Simulate progress
    for (double i = 0.2; i <= 0.8; i += 0.1) {
      await Future.delayed(Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _progress = i;
        _statusMessage = 'Fixing exercise metadata...';
      });
    }
    
    // Start fixing
    final result = await ExerciseDataFixer.fixExerciseData();
    
    if (!mounted) return;
    
    setState(() {
      _isFixing = false;
      _isFixComplete = result;
      _progress = 1.0;
      _statusMessage = result 
          ? 'Data successfully fixed!' 
          : 'Error fixing data';
    });
    
    // Small delay for animation
    await Future.delayed(Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      _progress = 0;
    });
  }
  
  Future<void> _applyFixes() async {
    setState(() {
      _isApplying = true;
      _statusMessage = 'Applying fixes...';
      _progress = 0.3;
    });
    
    // Simulate progress
    await Future.delayed(Duration(milliseconds: 500));
    
    if (!mounted) return;
    setState(() {
      _progress = 0.6;
    });
    
    // Apply fixes
    final result = await ExerciseDataFixer.applyFixedData();
    
    if (result) {
      // After successful application of fixes, clear workout plan cache,
      // so that new data is used when next plan is created
      await PlanCache.clearPlan();
      
      // Clear cache on server as well
      await ApiService.clearPlan();
      
      // Reset flag that user doesn't have a generated plan
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_generated_plan', false);
    }
    
    if (!mounted) return;
    
    setState(() {
      _isApplying = false;
      _isApplyComplete = result;
      _progress = 1.0;
      _statusMessage = result 
          ? 'Fixes successfully applied!' 
          : 'Error applying fixes';
    });
    
    // Small delay for animation
    await Future.delayed(Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      _progress = 0;
    });
  }
} 