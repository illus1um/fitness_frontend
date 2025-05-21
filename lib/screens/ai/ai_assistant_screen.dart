import 'package:flutter/material.dart';
import 'package:fitness_app/services/ai_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AIAssistantScreen extends StatefulWidget {
  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  static final Color goldColor = Color.fromARGB(255, 199, 169, 127);
  final TextEditingController _textController = TextEditingController();
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  static const String chatHistoryKey = 'ai_chat_history';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getString(chatHistoryKey);
    if (history != null) {
      final List<dynamic> decoded = jsonDecode(history);
      setState(() {
        _messages.clear();
        _messages.addAll(decoded.map((item) => ChatMessage.fromJson(item)));
        if (_messages.isEmpty || !_messages.first.text.startsWith("Hello! I'm your fitness assistant")) {
          _messages.insert(0, ChatMessage(
            text: "Hello! I'm your fitness assistant. Ask me about workouts, nutrition, exercises or hydration.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }
      });
      _saveChatHistory();
    } else {
      _addInitialMessage();
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(chatHistoryKey, encoded);
  }

  void _addInitialMessage() {
    _messages.add(ChatMessage(
      text: "Hello! I'm your fitness assistant. Ask me about workouts, nutrition, exercises or hydration.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _saveChatHistory();
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

  String _formatText(String text) {
    // Простая обработка форматирования, убираем звездочки
    text = text.replaceAll('**', '');
    text = text.replaceAll('*', '');
    text = text.replaceAll('__', '');
    return text;
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
        title: Text(
          'Fitness Assistant', 
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: isDarkMode ? Color(0xFF23242B) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
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
                  valueColor: AlwaysStoppedAnimation<Color>(goldColor),
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
                          fontSize: 15, 
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: goldColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 22,
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

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _saveChatHistory();
    _scrollToBottom();
  }

  void _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _aiService.getResponse(text);
      if (mounted) {
        _addMessage(ChatMessage(
          text: _formatText(response),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _addMessage(ChatMessage(
          text: "Sorry, an error occurred: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        setState(() {
          _isLoading = false;
        });
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  String _formatTime() {
    return DateFormat.Hm().format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goldColor = Color.fromARGB(255, 199, 169, 127);
    
    // Цвета для пользовательских сообщений
    final userBgColor = goldColor;
    final userTextColor = Colors.white;
    
    // Цвета для сообщений ассистента
    final assistantBgColor = isDarkMode ? Color(0xFF23242B) : Colors.white;
    final assistantTextColor = isDarkMode ? Colors.white : Colors.black87;
    final timeColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    
    final bgColor = isUser ? userBgColor : assistantBgColor;
    final textColor = isUser ? userTextColor : assistantTextColor;
    
    final radius = isUser
        ? BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
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
                    backgroundColor: goldColor,
                    child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
                    radius: 14,
                  ),
                ),
              Flexible(
                child: ExpandableMessageWidget(
                  text: text,
                  isUser: isUser,
                  textColor: textColor,
                  bgColor: bgColor,
                  radius: radius,
                  isDarkMode: isDarkMode,
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4),
                  child: CircleAvatar(
                    backgroundColor: goldColor,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                    radius: 14,
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 2,
              left: isUser ? 0 : 35,
              right: isUser ? 35 : 0,
            ),
            child: Text(
              _formatTime(),
              style: TextStyle(
                color: timeColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableMessageWidget extends StatefulWidget {
  final String text;
  final bool isUser;
  final Color textColor;
  final Color bgColor;
  final BorderRadius radius;
  final bool isDarkMode;

  ExpandableMessageWidget({
    required this.text,
    required this.isUser,
    required this.textColor,
    required this.bgColor,
    required this.radius,
    required this.isDarkMode,
  });

  @override
  _ExpandableMessageWidgetState createState() => _ExpandableMessageWidgetState();
}

class _ExpandableMessageWidgetState extends State<ExpandableMessageWidget> {
  bool isExpanded = false;
  static const int maxCharsToShow = 300;
  bool get isLongMessage => widget.text.length > maxCharsToShow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: widget.radius,
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode 
                ? Colors.black12 
                : Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isExpanded || !isLongMessage 
                ? widget.text 
                : widget.text.substring(0, maxCharsToShow) + '...',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (isLongMessage)
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: Color.fromARGB(255, 199, 169, 127),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 