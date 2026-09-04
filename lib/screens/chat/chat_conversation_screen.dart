// screens/chat/chat_conversation_screen.dart
//
// ✅ شاشة دردشة بسيطة (placeholder) — تفتح مباشرة مع الشخص اللي عجبك
// (بعد الضغط على القلب فـ صفحة الاكتشاف).
//
// ⚠️ الرسائل هنا محفوظة محلياً فقط (في الذاكرة) — ماشي مربوطة بـ Firestore.
// TODO: ربط هاد الشاشة بـ collection 'messages' فـ Firestore (نفس الـ schema
// اللي مذكور فـ home_screen.dart: fromUserId, toUserId, text, timestamp).

import 'package:flutter/material.dart';

class _ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;

  _ChatMessage({required this.text, required this.fromMe, required this.time});
}

class ChatConversationScreen extends StatefulWidget {
  final String? personId;
  final String personName;
  final String? personCity;
  final String? personAvatarAsset;

  const ChatConversationScreen({
    super.key,
    this.personId,
    required this.personName,
    this.personCity,
    this.personAvatarAsset,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // TODO: كتب الرسالة فـ Firestore (collection 'messages')
    // toUserId: widget.personId — fromUserId: FirebaseAuth.instance.currentUser?.uid
    setState(() {
      _messages.add(
        _ChatMessage(text: text, fromMe: true, time: DateTime.now()),
      );
    });
    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAvatar({double size = 40}) {
    if (widget.personAvatarAsset == null || widget.personAvatarAsset!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: darkGreen.withValues(alpha: 0.08),
        child: Icon(Icons.person, color: darkGreen, size: size * 0.55),
      );
    }
    return ClipOval(
      child: Image.asset(
        widget.personAvatarAsset!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stack) => CircleAvatar(
          radius: size / 2,
          backgroundColor: darkGreen.withValues(alpha: 0.08),
          child: Icon(Icons.person, color: darkGreen, size: size * 0.55),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            _buildAvatar(size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.personName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: darkGreen,
                    ),
                  ),
                  if (widget.personCity != null &&
                      widget.personCity!.isNotEmpty)
                    Text(
                      widget.personCity!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: darkGreen),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_rounded, color: gold, size: 40),
                            const SizedBox(height: 14),
                            Text(
                              'عجبتكم بعضاكم! ابدأ الحوار مع ${widget.personName} 👋',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return Align(
                          alignment: msg.fromMe
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              color: msg.fromMe ? darkGreen : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: msg.fromMe
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: darkGreen.withValues(alpha: 0.12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: darkGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
