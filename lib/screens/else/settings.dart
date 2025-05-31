// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  const SettingsScreen({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedWaterUnit = 'L';
  bool _workoutNotificationsEnabled = true;
  
  // Константы для цветов
  final Color goldAccent = Color(0xFFC7A97F);
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _selectedTheme = prefs.getString('theme') ?? 'Light';
      _selectedWeightUnit = prefs.getString('weight_unit') ?? 'kg';
      _selectedHeightUnit = prefs.getString('height_unit') ?? 'cm';
      _selectedWaterUnit = prefs.getString('water_unit') ?? 'L';
      _workoutNotificationsEnabled = prefs.getBool('workout_notifications_enabled') ?? true;
    });
  }

  Future<void> _updateSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    
    // Небольшая анимация при обновлении настроек
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    setState(() {
      if (key == 'language') _selectedLanguage = value;
      if (key == 'theme') _selectedTheme = value;
      if (key == 'weight_unit') _selectedWeightUnit = value;
      if (key == 'height_unit') _selectedHeightUnit = value;
      if (key == 'water_unit') _selectedWaterUnit = value;
    });
    
    if (key == 'theme') {
      final mode = value == 'Dark'
          ? ThemeMode.dark
          : value == 'System'
              ? ThemeMode.system
              : ThemeMode.light;
      widget.onThemeChanged(mode);
      
      // Показать уведомление о смене темы
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Theme updated to $value mode'),
            ],
          ),
          backgroundColor: goldAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showOptionPicker(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    ValueChanged<String> onSelected,
    IconData sectionIcon,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Полоска для перетаскивания
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Заголовок
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: goldAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      sectionIcon,
                      color: goldAccent,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(color: dividerColor, height: 1),
            
            // Список опций
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == currentValue;
                  
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isDarkMode ? goldAccent.withOpacity(0.2) : goldAccent.withOpacity(0.1))
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: dividerColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? goldAccent : textColor,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: goldAccent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: goldAccent,
                                size: 18,
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
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isDarkMode,
    String? description,
    bool isDisabled = false,
  }) {
    final cardColor = isDarkMode ? Color(0xFF252A36) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final disabledColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Иконка в цветном круге
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDisabled 
                        ? (isDarkMode ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.1))
                        : goldAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled ? disabledColor : goldAccent,
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),
                
                // Заголовок и описание
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDisabled ? disabledColor : textColor,
                        ),
                      ),
                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDisabled 
                                  ? (isDarkMode ? Colors.grey[600] : Colors.grey[400])
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Текущее значение и стрелка
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? (isDarkMode ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.1))
                            : (isDarkMode ? Colors.black26 : goldAccent.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDisabled ? disabledColor : goldAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDisabled ? Icons.lock_outline : Icons.arrow_forward_ios,
                        size: isDisabled ? 14 : 12,
                        color: isDisabled
                            ? disabledColor
                            : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: goldAccent,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF8FAFF);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
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
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                color: _animationController.value > 0
                    ? goldAccent.withOpacity(_animationController.value * 0.1)
                    : Colors.transparent,
                child: child,
              );
            },
            child: ListView(
              padding: EdgeInsets.all(20),
              physics: BouncingScrollPhysics(),
              children: [
                // Персональные настройки
                _buildSectionHeader('Appearance', Icons.color_lens_outlined, isDarkMode: isDarkMode),
                _buildSettingTile(
                  icon: Icons.format_paint,
                  title: 'Theme',
                  value: _selectedTheme,
                  description: 'Light, dark or follow system theme',
                  onTap: () {
                    _showOptionPicker(
                      context,
                      'Select Theme',
                      ['Light', 'Dark', 'System'],
                      _selectedTheme,
                      (v) => _updateSetting('theme', v),
                      Icons.dark_mode_outlined,
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
                _buildSettingTile(
                  icon: Icons.language,
                  title: 'Language',
                  value: _selectedLanguage,
                  description: 'Localization is coming soon',
                  onTap: () {
                    // Показываем уведомление вместо открытия модального окна
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text('Localization is not implemented yet. Coming soon!'),
                            ),
                          ],
                        ),
                        backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blueGrey,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: EdgeInsets.all(10),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  isDarkMode: isDarkMode,
                  isDisabled: true,
                ),
                
                // Добавляем новую секцию уведомлений
                _buildSectionHeader('Notifications', Icons.notifications_outlined, isDarkMode: isDarkMode),
                _buildNotificationToggle(
                  icon: Icons.fitness_center,
                  title: 'Workout Reminders',
                  description: 'Get notified on workout days',
                  value: _workoutNotificationsEnabled,
                  onChanged: _toggleWorkoutNotifications,
                  isDarkMode: isDarkMode,
                ),
                
                // Настройки единиц измерения
                _buildSectionHeader('Units', Icons.straighten_outlined, isDarkMode: isDarkMode),
                _buildSettingTile(
                  icon: Icons.fitness_center,
                  title: 'Weight Unit',
                  value: _selectedWeightUnit,
                  description: 'Used for body weight and exercises',
                  onTap: () {
                    _showOptionPicker(
                      context,
                      'Select Weight Unit',
                      ['kg', 'lb'],
                      _selectedWeightUnit,
                      (v) => _updateSetting('weight_unit', v),
                      Icons.fitness_center,
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
                _buildSettingTile(
                  icon: Icons.height,
                  title: 'Height Unit',
                  value: _selectedHeightUnit,
                  description: 'Used for body measurements',
                  onTap: () {
                    _showOptionPicker(
                      context,
                      'Select Height Unit',
                      ['cm', 'inch'],
                      _selectedHeightUnit,
                      (v) => _updateSetting('height_unit', v),
                      Icons.height,
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
                _buildSettingTile(
                  icon: Icons.water_drop,
                  title: 'Water Unit',
                  value: _selectedWaterUnit,
                  description: 'Used in water tracking',
                  onTap: () {
                    _showOptionPicker(
                      context,
                      'Select Water Unit',
                      ['L', 'fl oz'],
                      _selectedWaterUnit,
                      (v) => _updateSetting('water_unit', v),
                      Icons.water_drop,
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
                
                // Информация о приложении (опционально)
                _buildSectionHeader('About', Icons.info_outline, isDarkMode: isDarkMode),
                _buildSettingTile(
                  icon: Icons.info,
                  title: 'App Version',
                  value: '1.0.0',
                  description: 'Current installed version',
                  onTap: () {
                    // Здесь можно добавить показ информации о приложении
                  },
                  isDarkMode: isDarkMode,
                ),
                
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Добавляем метод для построения переключателя уведомлений
  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) {
    final cardColor = isDarkMode ? Color(0xFF252A36) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Иконка в цветном круге
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: goldAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: goldAccent,
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            
            // Заголовок и описание
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Переключатель
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: goldAccent,
              activeTrackColor: goldAccent.withOpacity(0.3),
              inactiveThumbColor: isDarkMode ? Colors.grey[300] : Colors.grey[400],
              inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
  
  // Метод для переключения уведомлений тренировок
  Future<void> _toggleWorkoutNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('workout_notifications_enabled', value);
    
    setState(() {
      _workoutNotificationsEnabled = value;
    });
    
    if (value) {
      // Показать уведомление о включении
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white),
              SizedBox(width: 10),
              Text('Workout notifications enabled'),
            ],
          ),
          backgroundColor: goldAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Отменяем все уведомления о тренировках
      await NotificationService.cancelAllWorkoutNotifications();
      
      // Показать уведомление о выключении
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.notifications_off, color: Colors.white),
              SizedBox(width: 10),
              Text('Workout notifications disabled'),
            ],
          ),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
