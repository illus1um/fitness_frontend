import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/api_service.dart';
import 'package:fitness_app/services/plan_cache.dart';
import 'package:fitness_app/utils/theme_constants.dart';
import 'package:fitness_app/widgets/profile_widgets.dart';
import 'package:fitness_app/widgets/editable_bottom_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyProfileGoalScreen extends StatefulWidget {
  const MyProfileGoalScreen({Key? key}) : super(key: key);

  @override
  _MyProfileGoalScreenState createState() => _MyProfileGoalScreenState();
}

class _MyProfileGoalScreenState extends State<MyProfileGoalScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _loadUnits();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightUnit = prefs.getString('weight_unit') ?? 'kg';
      _heightUnit = prefs.getString('height_unit') ?? 'cm';
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    // Очистка предыдущих данных для сброса кеша
    if (userData != null && userData!["avatar_url"] != null) {
      await CachedNetworkImage.evictFromCache(userData!["avatar_url"]);
    }
    
    final data = await ApiService.getUserProfile();
    if (data != null) {
      print("MyProfileGoalScreen: loaded user data with avatar_url: ${data['avatar_url']}");
      setState(() {
        userData = data;
        _isLoading = false;
      });
      _animationController.forward();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    }
  }

  void _updateField(String field, dynamic newValue) async {
    setState(() {
      userData![field] = newValue;
    });

    bool success = await ApiService.updateUserProfile({field: newValue});
    if (success) {
      // If training-related settings change, clear the plan cache
      if (field == 'training_program' ||
          field == 'training_location' ||
          field == 'training_experience') {
        await PlanCache.clearPlan();
        _showSuccessSnackbar('Settings updated. Plan will be recreated.');
      } else {
        _showSuccessSnackbar('${_formatFieldName(field)} successfully updated');
      }
    } else {
      _showErrorSnackbar('Error updating ${_formatFieldName(field)}');
    }
  }

  void _showSuccessSnackbar(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDarkMode ? ThemeConstants.darkText : ThemeConstants.lightText,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDarkMode 
            ? ThemeConstants.darkCardBackground 
            : ThemeConstants.lightCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        action: SnackBarAction(
          label: 'OK',
          textColor: ThemeConstants.primaryGold,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ThemeConstants.errorRed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Unit-conversion helpers
  double get _displayWeight {
    if (userData == null) return 0;
    final kg = (userData!['weight'] ?? 0.0) as double;
    return _weightUnit == 'lb' ? kg * 2.20462 : kg;
  }

  String get _displayHeight {
    if (userData == null) return '';
    final cm = (userData!['height'] ?? 0.0) as double;
    if (_heightUnit == 'inch') {
      final totalInches = (cm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet ft $inches in";
    }
    return "${cm.toStringAsFixed(0)} cm";
  }

  void _confirmDeleteAccount() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
            color: isDarkMode ? ThemeConstants.darkSurface : ThemeConstants.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? ThemeConstants.darkDivider : ThemeConstants.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.warning_amber_rounded,
                size: 60,
                color: ThemeConstants.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                "Delete Account",
                style: ThemeConstants.headlineStyle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to delete your account? All your data will be permanently removed. This action cannot be undone.",
                style: ThemeConstants.bodyStyle(context),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
                Row(
                  children: [
                  Expanded(
                    child: OutlinedButton(
                      style: ThemeConstants.secondaryButtonStyle(context),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.errorRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ThemeConstants.buttonBorderRadius),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        _deleteAccount();
                        Navigator.pop(context);
                      },
                      child: const Text("DELETE"),
                    ),
                    ),
                  ],
                ),
              ],
          ),
        );
      },
    );
  }

  void _deleteAccount() async {
    setState(() => _isLoading = true);
    bool success = await ApiService.deleteAccount();
    setState(() => _isLoading = false);
    
    if (success) {
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      _showErrorSnackbar('Failed to delete account');
    }
  }

  void _editWeight() {
    final displayed = _displayWeight;
    final min = _weightUnit == 'kg' ? 30.0 : 66.0;
    final max = _weightUnit == 'kg' ? 200.0 : 440.0;
    String selectedValue = displayed.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EditableBottomSheet(
          title: 'Weight ($_weightUnit)',
          onSave: () {
            final newValue = double.parse(selectedValue);
            final newKg = _weightUnit == 'lb' ? newValue / 2.20462 : newValue;
            _updateField('weight', newKg);
          },
          content: SizedBox(
            height: 180,
                child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: (displayed - min).round(),
              ),
              itemExtent: 40,
              magnification: 1.2,
              squeeze: 1.0,
              useMagnifier: true,
              onSelectedItemChanged: (index) {
                selectedValue = (min + index).toStringAsFixed(0);
              },
              children: List.generate(
                (max - min).round() + 1,
                (index) => Center(
                  child: Text(
                    "${(min + index).toStringAsFixed(0)} $_weightUnit",
                    style: ThemeConstants.bodyStyle(context).copyWith(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _editHeight() {
    if (_heightUnit == 'inch') {
      final cmValue = (userData!['height'] ?? 0.0) as double;
      final totalInches = (cmValue / 2.54).round();
      int selectedFeet = totalInches ~/ 12;
      int selectedInches = totalInches % 12;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return EditableBottomSheet(
            title: 'Height (ft/in)',
            onSave: () {
              final total = selectedFeet * 12 + selectedInches;
              final newCm = total * 2.54;
              _updateField('height', newCm);
            },
            content: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: selectedFeet),
                    itemExtent: 40,
                    magnification: 1.2,
                    squeeze: 1.0,
                    useMagnifier: true,
                    onSelectedItemChanged: (index) => selectedFeet = index,
                    children: List.generate(8, (i) => Center(
                      child: Text(
                        '$i ft',
                        style: ThemeConstants.bodyStyle(context).copyWith(fontSize: 18),
                      ),
                    )),
                  ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(initialItem: selectedInches),
                    itemExtent: 40,
                    magnification: 1.2,
                    squeeze: 1.0,
                    useMagnifier: true,
                    onSelectedItemChanged: (index) => selectedInches = index,
                    children: List.generate(12, (i) => Center(
                      child: Text(
                        '$i in',
                        style: ThemeConstants.bodyStyle(context).copyWith(fontSize: 18),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final cm = (userData!['height'] ?? 0.0) as double;
      final min = 100.0;
      final max = 220.0;
      double selectedValue = cm;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return EditableBottomSheet(
            title: 'Height (cm)',
            onSave: () {
              _updateField('height', selectedValue);
            },
            content: SizedBox(
              height: 180,
                  child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: (cm - min).round(),
                ),
                itemExtent: 40,
                magnification: 1.2,
                squeeze: 1.0,
                useMagnifier: true,
                onSelectedItemChanged: (index) {
                  selectedValue = min + index.toDouble();
                },
                children: List.generate(
                  (max - min).round() + 1,
                  (index) => Center(
                    child: Text(
                      "${(min + index).round()} cm",
                      style: ThemeConstants.bodyStyle(context).copyWith(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  void _editNumberPicker(String field, int min, int max) {
    int selectedValue = int.parse(userData![field].toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NumberPickerBottomSheet(
          title: _formatFieldName(field),
          minValue: min,
          maxValue: max,
          initialValue: selectedValue,
          onValueChanged: (value) => selectedValue = value,
          onSave: () => _updateField(field, selectedValue),
        );
      },
    );
  }

  void _editTextField(String field) {
    String selectedValue = userData![field];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TextFieldBottomSheet(
          title: _formatFieldName(field),
          initialValue: selectedValue,
          hintText: "Enter ${_formatFieldName(field)}",
          onValueChanged: (value) => selectedValue = value,
          onSave: () => _updateField(field, selectedValue),
        );
      },
    );
  }

  void _editPicker(String field, List<String> options) {
    String selectedValue = userData![field];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PickerBottomSheet(
          title: _formatFieldName(field),
          options: options,
          initialValue: selectedValue,
          onValueChanged: (value) => selectedValue = value,
          onSave: () => _updateField(field, selectedValue),
        );
      },
    );
  }

  void _editGenderPicker(String field) {
    bool isMale = userData![field];
    String selectedValue = isMale ? "Male" : "Female";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RadioSelectionBottomSheet(
          title: "Gender",
          options: const ["Male", "Female"],
          initialValue: selectedValue,
          onValueChanged: (value) => selectedValue = value,
          onSave: () => _updateField(field, selectedValue == "Male"),
        );
      },
    );
  }

  void _editTrainingLocationPicker(String field) {
    String selectedValue = userData![field];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RadioSelectionBottomSheet(
          title: "Training Location",
          options: const ["At home", "In the gym"],
          initialValue: selectedValue,
          onValueChanged: (value) => selectedValue = value,
          onSave: () => _updateField(field, selectedValue),
        );
      },
    );
  }

  String _formatFieldName(String field) {
    return field.split('_').map((word) => 
      word.isEmpty ? '' : 
      '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
    ).join(' ');
  }

  // Метод для выбора и загрузки аватара из галереи
  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final bool hasAvatar = userData != null && 
                          userData!["avatar_url"] != null && 
                          userData!["avatar_url"].toString().isNotEmpty;
    
    // Показываем модальное окно выбора источника изображения
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? ThemeConstants.darkSurface : ThemeConstants.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? ThemeConstants.darkDivider : ThemeConstants.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text(
                "Profile Picture",
                style: ThemeConstants.headlineStyle(context).copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Выбор из галереи
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: ThemeConstants.primaryGold),
                ),
                title: Text("Gallery", style: ThemeConstants.subtitleStyle(context)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    _uploadAvatar(File(image.path));
                  }
                },
              ),
              
              // Камера
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: ThemeConstants.primaryGold),
                ),
                title: Text("Camera", style: ThemeConstants.subtitleStyle(context)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    preferredCameraDevice: CameraDevice.front,
                    imageQuality: 80,
                  );
                  if (photo != null) {
                    _uploadAvatar(File(photo.path));
                  }
                },
              ),

              // Добавляем разделитель и опцию удаления только если есть аватар
              if (hasAvatar) ...[
                const Divider(height: 32),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeConstants.errorRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever, color: ThemeConstants.errorRed),
                  ),
                  title: Text(
                    "Delete Profile Picture",
                    style: ThemeConstants.subtitleStyle(context).copyWith(
                      color: ThemeConstants.errorRed,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteAvatar();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Метод для подтверждения удаления аватара
  void _confirmDeleteAvatar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? ThemeConstants.darkSurface : ThemeConstants.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Profile Picture",
            style: ThemeConstants.headlineStyle(context),
          ),
          content: Text(
            "Are you sure you want to delete your profile picture? This action cannot be undone.",
            style: ThemeConstants.bodyStyle(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: TextStyle(
                  color: isDarkMode ? ThemeConstants.darkSubtext : ThemeConstants.lightSubtext,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAvatar();
              },
              child: const Text(
                "DELETE",
                style: TextStyle(color: ThemeConstants.errorRed),
              ),
            ),
          ],
        );
      },
    );
  }

  // Метод для удаления аватара
  Future<void> _deleteAvatar() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await ApiService.deleteAvatar();
      
      if (success) {
        // Обновляем данные пользователя после удаления
        await _loadUserData();
        _showSuccessSnackbar('Profile picture successfully deleted');
      } else {
        _showErrorSnackbar('Failed to delete profile picture');
      }
    } catch (e) {
      print("Error deleting avatar: $e");
      _showErrorSnackbar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Метод для загрузки аватара на сервер
  Future<void> _uploadAvatar(File imageFile) async {
    setState(() => _isLoading = true);
    
    try {
      // Check if file has valid extension
      final String fileName = imageFile.path.toLowerCase();
      if (!fileName.endsWith('.jpg') && !fileName.endsWith('.jpeg') && 
          !fileName.endsWith('.png') && !fileName.endsWith('.webp')) {
        _showErrorSnackbar('Invalid image format. Use JPEG, PNG, or WebP.');
        setState(() => _isLoading = false);
        return;
      }
      
      // Загрузка изображения
      final success = await ApiService.uploadAvatar(imageFile);
      
      if (success) {
        // Если загрузка успешна, обновляем данные пользователя
        await _loadUserData();
        _showSuccessSnackbar('Avatar successfully updated');
      } else {
        _showErrorSnackbar('Failed to upload avatar. Only JPEG, PNG and WebP images are allowed.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error uploading avatar: $e");
      _showErrorSnackbar('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _isLoading 
          ? _buildLoadingView() 
          : _buildMainContent(isDarkMode),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ThemeConstants.primaryGold,
          ),
          SizedBox(height: 16),
          Text("Loading profile..."),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return userData == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: ThemeConstants.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  "Failed to load profile",
                  style: ThemeConstants.headlineStyle(context),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ThemeConstants.primaryButtonStyle,
                  onPressed: _loadUserData,
                  child: const Text("Retry"),
                ),
              ],
            ),
          )
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDarkMode),
              SliverFadeTransition(
                opacity: _fadeAnimation,
                sliver: SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          _buildPersonalInfoCard(),
                          _buildGoalSettingsCard(),
                          const SizedBox(height: 16),
                          ProfileDivider(
                            height: 32,
                            indent: 32,
                            endIndent: 32,
                          ),
                          _buildDeleteAccountButton(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 100,
      elevation: 0,
      backgroundColor: isDarkMode 
          ? ThemeConstants.darkBackground 
          : ThemeConstants.lightBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Text(
          "My Profile & Goal",
          style: TextStyle(
            color: isDarkMode ? ThemeConstants.darkText : ThemeConstants.lightText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          color: ThemeConstants.primaryGold,
          onPressed: _loadUserData,
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        ProfileAvatar(
          imageUrl: userData?["avatar_url"],
          size: 60,
          onTap: _pickAvatar,
        ),
        const SizedBox(height: 16),
        Text(
          userData?["username"] ?? '',
          style: ThemeConstants.headlineStyle(context),
        ),
        const SizedBox(height: 4),
        Text(
          "${userData?["first_name"] ?? ''} ${userData?["last_name"] ?? ''}",
          style: ThemeConstants.subtitleStyle(context),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return ProfileCard(
      title: "Personal Information",
      children: [
        ProfileInfoTile(
          label: "First Name",
          value: userData!["first_name"] ?? '',
          onTap: () => _editTextField("first_name"),
        ),
        ProfileDivider(),
        ProfileInfoTile(
          label: "Last Name",
          value: userData!["last_name"] ?? '',
          onTap: () => _editTextField("last_name"),
        ),
        ProfileDivider(),
        ProfileInfoTile(
          label: "Age",
          value: "${userData!["age"]} years",
          onTap: () => _editNumberPicker("age", 12, 80),
        ),
        ProfileDivider(),
        ProfileInfoTile(
          label: "Gender",
          value: userData!["gender"] ? "Male" : "Female",
          onTap: () => _editGenderPicker("gender"),
        ),
        ProfileDivider(),
        ProfileInfoTile(
          label: "Weight",
          value: "${_displayWeight.toStringAsFixed(1)} $_weightUnit",
          onTap: _editWeight,
        ),
        ProfileDivider(),
        ProfileInfoTile(
          label: "Height",
          value: _displayHeight,
          onTap: _editHeight,
        ),
      ],
    );
  }

  Widget _buildGoalSettingsCard() {
    return ProfileCard(
      title: "Goal Settings",
      children: [
        ProfileInfoTile(
          label: "Fitness Goal",
          value: userData!["training_program"] ?? '',
          onTap: () => _editPicker("training_program", fitnessGoals),
        ),
        ProfileDivider(),
        ProfileInfoTile(
          label: "Training Location",
          value: userData!["training_location"] ?? '',
          onTap: () => _editTrainingLocationPicker("training_location"),
        ),
        ProfileDivider(),
        ProfileInfoTile(
          label: "Experience Level",
          value: userData!["training_experience"] ?? '',
          onTap: () => _editPicker("training_experience", experienceLevels),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final softRedColor = isDarkMode 
        ? Color(0xFFAA5555) // Более мягкий красный для темной темы
        : Color(0xFFDD7777); // Более мягкий красный для светлой темы
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 0,
        color: isDarkMode 
            ? Color(0xFF352525) // Очень темный мягкий красный для фона в темной теме
            : Color(0xFFF8E8E8), // Очень светлый мягкий красный для фона в светлой теме
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
          side: BorderSide(
            color: softRedColor.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
          onTap: _confirmDeleteAccount,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: softRedColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: softRedColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Delete Account",
                        style: ThemeConstants.subtitleStyle(context).copyWith(
                          color: softRedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Permanently delete your account and all your data",
                        style: ThemeConstants.captionStyle(context).copyWith(
                          color: isDarkMode 
                              ? ThemeConstants.darkSubtext 
                              : ThemeConstants.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: softRedColor.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const List<String> fitnessGoals = [
  "Weight Loss",
  "Endurance",
  "Full Body", 
  "Gain Muscle Mass",
  "Legs",
  "Wide Back"
];

const List<String> experienceLevels = [
  "No experience",
  "Beginner",
  "Experienced",
  "Pro"
];