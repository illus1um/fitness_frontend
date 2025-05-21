import 'package:flutter/material.dart';
import 'package:fitness_app/services/ai_service.dart';
import 'package:intl/intl.dart';

class AIAssistantScreen extends StatefulWidget {
  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addInitialMessage() {
    _messages.add(ChatMessage(
      text: "Hello! I'm your fitness assistant. Ask me about workouts, nutrition, exercises or hydration.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Color(0xFF181A20) : Color(0xFFF6F6F6);
    final inputBg = isDarkMode ? Color(0xFF23242B) : Colors.white;
    final borderColor = isDarkMode ? Color(0xFF35363B) : Color(0xFFE0E0E0);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Fitness Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? Color(0xFF23242B) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: bgColor,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemBuilder: (context, index) => _messages[index],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                  backgroundColor: isDarkMode ? Color(0xFF23242B) : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDarkMode ? Color(0xFF35363B) : Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(
                          fontSize: 16, 
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask about exercises, nutrition, hydration...',
                          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Color(0xFF23242B) : Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _handleSubmit(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleSubmit,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _aiService.getResponse(text);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Sorry, an error occurred: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  String _formatTime() {
    return DateFormat.Hm().format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Цвета для пользовательских сообщений
    final userBgColor = isDarkMode ? Color(0xFF1976D2) : Color(0xFF2196F3);
    final userTextColor = Colors.white;
    
    // Цвета для сообщений ассистента
    final assistantBgColor = isDarkMode ? Color(0xFF23242B) : Colors.white;
    final assistantTextColor = isDarkMode ? Colors.white : Colors.black87;
    final timeColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    
    final bgColor = isUser ? userBgColor : assistantBgColor;
    final textColor = isUser ? userTextColor : assistantTextColor;
    
    final radius = isUser
        ? BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );
          
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 4),
                  child: CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 199, 169, 127),
                    child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
                    radius: 16,
                  ),
                ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                            ? Colors.black12 
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                    radius: 16,
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 40,
              right: isUser ? 40 : 0,
            ),
            child: Text(
              _formatTime(),
              style: TextStyle(
                color: timeColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 