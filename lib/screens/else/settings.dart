import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  const SettingsScreen({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedWaterUnit = 'L';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _selectedTheme = prefs.getString('theme') ?? 'Light';
      _selectedWeightUnit = prefs.getString('weight_unit') ?? 'kg';
      _selectedHeightUnit = prefs.getString('height_unit') ?? 'cm';
      _selectedWaterUnit = prefs.getString('water_unit') ?? 'L';
    });
  }

  Future<void> _updateSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
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
    }
  }

  void _showOptionPicker(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...options.map((option) => ListTile(
                  title: Text(option, style: Theme.of(context).textTheme.bodyMedium),
                  trailing: option == currentValue
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 10),
          ]),
        );
      },
    );
  }

  Widget _buildListTile(
      IconData icon, String title, String value, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge!),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(title: 'General', children: [
              _buildListTile(Icons.language, 'Language', _selectedLanguage, () {
                _showOptionPicker(
                  context,
                  'Select Language',
                  ['English', 'Русский', 'Qazaqsha'],
                  _selectedLanguage,
                  (v) => _updateSetting('language', v),
                );
              }),
              const SizedBox(height: 8),
              _buildListTile(Icons.format_paint, 'Theme', _selectedTheme, () {
                _showOptionPicker(
                  context,
                  'Select Theme',
                  ['Light', 'Dark', 'System'],
                  _selectedTheme,
                  (v) => _updateSetting('theme', v),
                );
              }),
            ]),
            const SizedBox(height: 20),
            _buildCard(title: 'Units', children: [
              _buildListTile(Icons.fitness_center, 'Weight Unit', _selectedWeightUnit, () {
                _showOptionPicker(
                  context,
                  'Select Weight Unit',
                  ['kg', 'lb'],
                  _selectedWeightUnit,
                  (v) => _updateSetting('weight_unit', v),
                );
              }),
              const SizedBox(height: 8),
              _buildListTile(Icons.height, 'Height Unit', _selectedHeightUnit, () {
                _showOptionPicker(
                  context,
                  'Select Height Unit',
                  ['cm', 'inch'],
                  _selectedHeightUnit,
                  (v) => _updateSetting('height_unit', v),
                );
              }),
              const SizedBox(height: 8),
              _buildListTile(Icons.local_drink, 'Water Unit', _selectedWaterUnit, () {
                _showOptionPicker(
                  context,
                  'Select Water Unit',
                  ['L', 'fl oz'],
                  _selectedWaterUnit,
                  (v) => _updateSetting('water_unit', v),
                );
              }),
            ]),
          ],
        ),
      ),
    );
  }
}
