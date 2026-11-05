import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const AIApp());

class AIApp extends StatelessWidget {
  const AIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Platform',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F5F0),
        primaryColor: const Color(0xFF5C3A21),
      ),
      home: const AuthScreen(),
    );
  }
}

// 1. شاشة المصادقة (تسجيل الدخول / إنشاء حساب)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final String baseUrl = 'http://localhost:3000';

  Future<void> _submit() async {
    final url = Uri.parse('$baseUrl/api/${isLogin ? 'login' : 'signup'}');
    try {
      final body = isLogin
          ? {'email': _emailController.text, 'password': _passwordController.text}
          : {
              'name': _nameController.text,
              'username': _usernameController.text,
              'email': _emailController.text,
              'password': _passwordController.text
            };

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(response.body);

      if (data['success']) {
        if (isLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(username: data['username'])),
          );
        } else {
          setState(() => isLogin = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully! Please log in.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed. Make sure Dart server is running.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF5C3A21), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? 'Welcome Back' : 'Create Account',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5C3A21)),
                ),
                const SizedBox(height: 20),
                if (!isLogin) ...[
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 12),
                  TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                ],
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C3A21)),
                    onPressed: _submit,
                    child: Text(isLogin ? 'Log In' : 'Sign Up', style: const TextStyle(color: Colors.white)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 2. شاشة المحادثة الرئيسية (Chat Screen)
class ChatScreen extends StatefulWidget {
  final String username;
  const ChatScreen({super.key, required this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List> _messages = [];
  bool isLoading = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _messageController.clear();
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/v1/responses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': text}),
      );
      final data = jsonDecode(response.body);

      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': data['text'],
          'hasCodeParts': data['hasCodeParts'] ?? false,
          'parts': data['parts'] ?? [],
        });
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': 'Error connecting to AI API.'});
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Workspace (@${widget.username})'),
        backgroundColor: const Color(0xFF5C3A21),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF5C3A21) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFEAE4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg['text'], style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                        if (msg['hasCodeParts'] == true) ...[
                          const SizedBox(height: 10),
                          ...(msg['parts'] as List).map((part) => Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                color: const Color(0xFF1E1E1E),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(part['partTitle'], style: const TextStyle(color: Colors.amber, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(part['code'], style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading) const LinearProgressIndicator(color: Color(0xFF5C3A21)),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type your message or request code...', border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF5C3A21)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}