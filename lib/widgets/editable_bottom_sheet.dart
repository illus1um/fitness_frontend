import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

class EditableBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onSave;
  final String buttonText;
  final bool isScrollable;

  const EditableBottomSheet({
    Key? key,
    required this.title,
    required this.content,
    required this.onSave,
    this.buttonText = "Save",
    this.isScrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
          
          // Title
          Text(
            title,
            style: ThemeConstants.headlineStyle(context).copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Content
          if (isScrollable)
            Flexible(
              child: SingleChildScrollView(child: content),
            )
          else
            content,
            
          const SizedBox(height: 24),
          
          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ThemeConstants.primaryButtonStyle,
              onPressed: () {
                onSave();
                Navigator.pop(context);
              },
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

class PickerBottomSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String initialValue;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onSave;
  final String buttonText;

  const PickerBottomSheet({
    Key? key,
    required this.title,
    required this.options,
    required this.initialValue,
    required this.onValueChanged,
    required this.onSave,
    this.buttonText = "Save",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int initialIndex = options.indexOf(initialValue);
    if (initialIndex < 0) initialIndex = 0;
    
    return EditableBottomSheet(
      title: title,
      buttonText: buttonText,
      onSave: onSave,
      content: SizedBox(
        height: 180,
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: initialIndex),
          itemExtent: 40,
          magnification: 1.2,
          squeeze: 1.0,
          useMagnifier: true,
          looping: false,
          onSelectedItemChanged: (index) => onValueChanged(options[index]),
          children: options.map((option) => Center(
            child: Text(
              option,
              style: ThemeConstants.bodyStyle(context).copyWith(fontSize: 18),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class NumberPickerBottomSheet extends StatelessWidget {
  final String title;
  final int minValue;
  final int maxValue;
  final int initialValue;
  final ValueChanged<int> onValueChanged;
  final VoidCallback onSave;
  final String buttonText;
  final String? suffix;

  const NumberPickerBottomSheet({
    Key? key,
    required this.title,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onValueChanged,
    required this.onSave,
    this.buttonText = "Save",
    this.suffix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int initialItem = initialValue - minValue;
    initialItem = initialItem.clamp(0, maxValue - minValue);
    
    return EditableBottomSheet(
      title: title,
      buttonText: buttonText,
      onSave: onSave,
      content: SizedBox(
        height: 180,
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: initialItem),
          itemExtent: 40,
          magnification: 1.2,
          squeeze: 1.0,
          useMagnifier: true,
          looping: false,
          onSelectedItemChanged: (index) => onValueChanged(minValue + index),
          children: List.generate(maxValue - minValue + 1, (index) => Center(
            child: Text(
              suffix != null ? "${minValue + index} $suffix" : "${minValue + index}",
              style: ThemeConstants.bodyStyle(context).copyWith(fontSize: 18),
            ),
          )),
        ),
      ),
    );
  }
}

class TextFieldBottomSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onSave;
  final String buttonText;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;

  const TextFieldBottomSheet({
    Key? key,
    required this.title,
    required this.initialValue,
    required this.onValueChanged,
    required this.onSave,
    this.buttonText = "Save",
    this.hintText = "",
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  State<TextFieldBottomSheet> createState() => _TextFieldBottomSheetState();
}

class _TextFieldBottomSheetState extends State<TextFieldBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      widget.onValueChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return EditableBottomSheet(
      title: widget.title,
      buttonText: widget.buttonText,
      onSave: widget.onSave,
      content: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        style: ThemeConstants.bodyStyle(context),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: ThemeConstants.bodyStyle(context).copyWith(
            color: isDarkMode 
                ? ThemeConstants.darkSubtext 
                : ThemeConstants.lightSubtext,
          ),
          filled: true,
          fillColor: isDarkMode 
              ? ThemeConstants.darkCardBackground 
              : ThemeConstants.lightCardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeConstants.primaryGold, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class RadioSelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String initialValue;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onSave;
  final String buttonText;

  const RadioSelectionBottomSheet({
    Key? key,
    required this.title,
    required this.options,
    required this.initialValue,
    required this.onValueChanged,
    required this.onSave,
    this.buttonText = "Save",
  }) : super(key: key);

  @override
  State<RadioSelectionBottomSheet> createState() => _RadioSelectionBottomSheetState();
}

class _RadioSelectionBottomSheetState extends State<RadioSelectionBottomSheet> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return EditableBottomSheet(
      title: widget.title,
      buttonText: widget.buttonText,
      onSave: widget.onSave,
      isScrollable: true,
      content: Column(
        children: widget.options.map((option) => RadioListTile<String>(
          title: Text(
            option,
            style: ThemeConstants.subtitleStyle(context),
          ),
          value: option,
          groupValue: _selectedValue,
          activeColor: ThemeConstants.primaryGold,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedValue = value;
                widget.onValueChanged(value);
              });
            }
          },
        )).toList(),
      ),
    );
  }
} 