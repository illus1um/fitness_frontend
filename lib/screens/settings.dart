import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = "English";
  String _selectedTheme = "System";
  String _selectedWeightUnit = "kg";
  String _selectedHeightUnit = "cm";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString("language") ?? "English";
      _selectedTheme = prefs.getString("theme") ?? "Light";
      _selectedWeightUnit = prefs.getString("weight_unit") ?? "kg";
      _selectedHeightUnit = prefs.getString("height_unit") ?? "cm";
    });
  }

  Future<void> _updateSetting(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    setState(() {
      if (key == "language") _selectedLanguage = value;
      if (key == "theme") _selectedTheme = value;
      if (key == "weight_unit") _selectedWeightUnit = value;
      if (key == "height_unit") _selectedHeightUnit = value;
    });
  }

  void _showOptionPicker(BuildContext context, String title, List<String> options, String currentValue, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...options.map((option) => ListTile(
                    title: Text(option),
                    trailing: option == currentValue ? Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                  )),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 📌 **Карточка "General"**
            _buildCard(
              title: "General",
              children: [
                _buildListTile(Icons.language, "Language", _selectedLanguage, () {
                  _showOptionPicker(context, "Select Language", ["English", "Русский", "Qazaqsha"], _selectedLanguage, (value) {
                    _updateSetting("language", value);
                  });
                }),
                _buildListTile(Icons.format_paint, "Theme", _selectedTheme, () {
                  _showOptionPicker(context, "Select Theme", ["Light", "Dark", "System"], _selectedTheme, (value) {
                    _updateSetting("theme", value);
                  });
                }),
              ],
            ),
            SizedBox(height: 20),

            /// 📌 **Карточка "Units"**
            _buildCard(
              title: "Units",
              children: [
                _buildListTile(Icons.fitness_center, "Weight Unit", _selectedWeightUnit, () {
                  _showOptionPicker(context, "Select Weight Unit", ["kg", "lb"], _selectedWeightUnit, (value) {
                    _updateSetting("weight_unit", value);
                  });
                }),
                _buildListTile(Icons.height, "Height Unit", _selectedHeightUnit, () {
                  _showOptionPicker(context, "Select Height Unit", ["cm", "inch"], _selectedHeightUnit, (value) {
                    _updateSetting("height_unit", value);
                  });
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📌 **Карточка с настройками**
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 199, 169, 127))),
          SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  /// 📌 **Элемент списка с настройкой**
  Widget _buildListTile(IconData icon, String title, String value, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        ],
      ),
      onTap: onTap,
    );
  }
}
