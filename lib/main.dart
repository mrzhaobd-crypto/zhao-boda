import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const ChatLabApp());

class ChatLabApp extends StatelessWidget {
  const ChatLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat — 실습 1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

/// 대화 한 줄. 서버 없이 화면만 만들기 위한 최소 모델.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;
  String _lastMessage = '';
  String _responseMode = 'success';
  bool _rateLimited = false;
  int _retrySeconds = 1;
  String _progress = '';

  // 실제 서버 대신 오류 상황을 확인하는 실습용 응답이다.
  Future<String> _request(String text, String mode) async {
    if (mode == 'timeout') {
      await Future<void>.delayed(
        const Duration(seconds: 2),
      ).timeout(const Duration(seconds: 1));
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mode == '401' || mode == '429' || mode == '500') {
      throw int.parse(mode);
    }
    return '모의 응답: $text';
  }

  Future<void> _getReply(String text, {int waitSeconds = 0}) async {
    final mode = _responseMode;
    setState(() {
      _sending = true;
      _error = null;
      _progress = waitSeconds > 0 ? '$waitSeconds초 후 다시 시도합니다…' : '응답을 기다리는 중…';
    });
    try {
      if (waitSeconds > 0) {
        await Future<void>.delayed(Duration(seconds: waitSeconds));
        if (!mounted) return;
        setState(() => _progress = '응답을 기다리는 중…');
      }
      final answer = await _request(text, mode);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: answer, isUser: false));
        _rateLimited = false;
        _retrySeconds = 1;
      });
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e == 401) {
        message = '키/권한을 확인해 주세요';
      } else if (e == 429) {
        message = '잠시 후 다시 시도해 주세요';
      } else if (e == 500) {
        message = '응답을 받지 못했습니다';
      } else if (e is TimeoutException) {
        message = '응답 시간이 초과되었습니다';
      } else {
        message = '네트워크를 확인해 주세요';
      }
      setState(() {
        _error = message;
        _rateLimited = e == 429;
        if (!_rateLimited) _retrySeconds = 1;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _retry() {
    if (_sending || _error == null) return;
    int waitSeconds = 0;
    if (_rateLimited) {
      waitSeconds = _retrySeconds;
      // 1초, 2초, 4초… 최대 8초까지 기다린다.
      _retrySeconds = (_retrySeconds * 2).clamp(1, 8);
    }
    _getReply(_lastMessage, waitSeconds: waitSeconds);
  }

  /// 실습용 가짜 대화 — API를 붙이기 전까지 이 목록으로 화면을 만든다.
  final List<ChatMessage> _messages = [
    ChatMessage(text: '오늘 뭐 배워?', isUser: true),
    ChatMessage(text: 'AI 챗봇에 움직이는 응답을 붙입니다.', isUser: false),
    ChatMessage(text: '타이핑 점은 왜 필요해요?', isUser: true),
    ChatMessage(text: '응답이 1초를 넘으면 앱이 멈춘 것처럼 보이기 때문입니다.', isUser: false),
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _controller.clear();
    _lastMessage = text;
    _retrySeconds = 1;
    _rateLimited = false;
    _getReply(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('AI Chat — 실습 1')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text('모의 응답: '),
                  DropdownButton<String>(
                    value: _responseMode,
                    items: const [
                      DropdownMenuItem(value: 'success', child: Text('성공')),
                      DropdownMenuItem(value: '401', child: Text('401 권한 오류')),
                      DropdownMenuItem(value: '429', child: Text('429 요청 제한')),
                      DropdownMenuItem(value: '500', child: Text('500 서버 오류')),
                      DropdownMenuItem(value: 'timeout', child: Text('시간 초과')),
                    ],
                    onChanged: _sending
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _responseMode = value);
                            }
                          },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      return _Bubble(message: message);
                    },
                  ),
                  if (_messages.isEmpty)
                    const Center(child: Text('무엇이든 물어보세요')),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _sending
                  ? Padding(
                      key: const ValueKey('sending'),
                      padding: const EdgeInsets.all(12),
                      child: Text(_progress),
                    )
                  : _error != null
                  ? Align(
                      key: const ValueKey('error'),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                            TextButton(
                              onPressed: _retry,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) {
                        _send();
                      },
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: '전송',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사용자 메시지는 오른쪽, AI 메시지는 왼쪽에 표시한다.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
