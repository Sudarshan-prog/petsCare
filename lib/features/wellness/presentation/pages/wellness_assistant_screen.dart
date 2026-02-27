import 'package:flutter/material.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/services/ai_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class WellnessAssistantScreen extends StatefulWidget {
  const WellnessAssistantScreen({super.key});

  @override
  State<WellnessAssistantScreen> createState() =>
      _WellnessAssistantScreenState();
}

class _WellnessAssistantScreenState extends State<WellnessAssistantScreen> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          'Hello! I am Paw-Assist 🐾. How can I help your pet stay healthy today?'
    },
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiWellnessService _aiService = AiWellnessService();
  bool _isTyping = false;

  void _handleSend() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isTyping = true;
      _controller.clear();
    });

    _scrollToBottom();

    // Get AI Advice (Simulated or Real later)
    final aiResponse = await _aiService.getAiAdvice(userText);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'ai', 'text': aiResponse});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildChatList()),
            if (_isTyping) _buildTypingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'AI Wellness',
                style: TextStyle(
                  color: AppTheme.brandBlueGreen,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              Text(
                'Paw-Assist',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.psychology_outlined,
                color: AppTheme.brandBlueGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isAi = msg['role'] == 'ai';

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment:
                isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAi)
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.brandBlueGreen,
                  child: Icon(Icons.pets, size: 14, color: Colors.white),
                ),
              if (isAi) const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAi ? Colors.white : AppTheme.brandBlueGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isAi ? 0 : 20),
                      bottomRight: Radius.circular(isAi ? 20 : 0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    msg['text']!,
                    style: TextStyle(
                      color: isAi ? Colors.black87 : Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (!isAi) const SizedBox(width: 12),
              if (!isAi)
                const CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      NetworkImage('https://images.pravatar.cc/150?img=11'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 60, bottom: 20),
      child: Row(
        children: const [
          SpinKitThreeBounce(
            color: AppTheme.brandBlueGreen,
            size: 20,
          ),
          SizedBox(width: 10),
          Text('Paw-Assist is thinking...',
              style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.softCream,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'Type a symptom or health query...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.brandBlueGreen,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
