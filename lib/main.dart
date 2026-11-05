// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const BasimAIApp());
}

class AppThemes {
  static final ThemeData classicLeather = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A0F0A),
    primaryColor: const Color(0xFF8B0000), // جلد محروق / أحمر داكن
    cardColor: const Color(0xFF2C1810),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B0000),
      secondary: Color(0xFFD4AF37),
      surface: Color(0xFF24130B),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF140B07), elevation: 0),
  );

  static final ThemeData luxuryDark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    primaryColor: const Color(0xFF6200EE),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFF181818),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212), elevation: 0),
  );

  static final ThemeData pureWhite = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    primaryColor: const Color(0xFF2563EB),
    cardColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF10B981),
      surface: Color(0xFFFFFFFF),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFFFFF), foregroundColor: Colors.black, elevation: 1),
  );
}

class BasimAIApp extends StatefulWidget {
  const BasimAIApp({super.key});

  @override
  State<BasimAIApp> createState() => _BasimAIAppState();
}

class _BasimAIAppState extends State<BasimAIApp> {
  ThemeData _currentTheme = AppThemes.classicLeather;
  String _currentThemeName = 'جلد كلاسيكي';
  String? _loggedInUser;

  void _changeTheme(ThemeData theme, String name) {
    setState(() {
      _currentTheme = theme;
      _currentThemeName = name;
    });
  }

  void _setLoggedInUser(String username) {
    setState(() {
      _loggedInUser = username;
    });
  }

  void _logout() {
    setState(() {
      _loggedInUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BASIM AI',
      debugShowCheckedModeBanner: false,
      theme: _currentTheme,
      home: _loggedInUser == null
          ? AuthScreen(onLoginSuccess: _setLoggedInUser)
          : ChatScreen(
              username: _loggedInUser!,
              currentThemeName: _currentThemeName,
              onThemeChanged: _changeTheme,
              onLogout: _logout,
            ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final Function(String) onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  final String baseUrl = 'http://localhost:8080';

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final endpoint = _isLogin ? '/api/login' : '/api/signup';
      final body = _isLogin
          ? {'email': _emailController.text.trim(), 'password': _passwordController.text}
          : {
              'name': _nameController.text.trim(),
              'username': _usernameController.text.trim(),
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            };

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (_isLogin) {
          widget.onLoginSuccess(data['user']['username'] ?? 'مستخدم');
        } else {
          setState(() {
            _isLogin = true;
            _errorMessage = 'تم إنشاء الحساب بنجاح! يرجى تسجيل الدخول الآن.';
          });
        }
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'حدث خطأ غير متوقع';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالخادم. تحقق من تشغيل الـ Back-end.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BASIM AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_isLogin ? 'تسجيل الدخول الحقيقي' : 'إنشاء حساب جديد حقيقي', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                if (!_isLogin) ...[
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'اسم المستخدم', prefixIcon: Icon(Icons.alternate_email))),
                  const SizedBox(height: 12),
                ],
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 12),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'دخول' : 'إنشاء الحساب', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _errorMessage = ''; }),
                  child: Text(_isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final String username;
  final String currentThemeName;
  final Function(ThemeData, String) onThemeChanged;
  final VoidCallback onLogout;

  const ChatScreen({
    super.key,
    required this.username,
    required this.currentThemeName,
    required this.onThemeChanged,
    required this.onLogout,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final String baseUrl = 'http://localhost:8080';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    try {
      // إرسال الطلب لنقطة الذكاء الاصطناعي الحقيقية في السيرفر
      final response = await http.post(
        Uri.parse('$baseUrl/v1/responses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: data['response'], isUser: false));
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: 'خطأ الذكاء الاصطناعي: ${errorData['error'] ?? response.body}', isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'تعذر الاتصال بـ Back-end الذكاء الاصطناعي.', isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // تجميع ونسخ الأكواد المقسمة بضغطة زر
  void _assembleAndCopyCode(String fullText) {
    final RegExp regExp = RegExp(r'```[\w]*\n([\s\S]*?)```');
    final matches = regExp.allMatches(fullText);
    
    StringBuffer assembledCode = StringBuffer();
    for (var match in matches) {
      if (match.group(1) != null) {
        assembledCode.write(match.group(1)!);
        assembledCode.write('\n\n');
      }
    }

    final codeToCopy = assembledCode.isNotEmpty ? assembledCode.toString().trim() : fullText;
    Clipboard.setData(ClipboardData(text: codeToCopy));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ تم تجميع ونسخ الكود الكامل (Assemble & Copy) بنجاح!')),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إعدادات الثيمات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.palette, color: Color(0xFF8B0000)),
                title: const Text('جلد طبيعي كلاسيكي'),
                onTap: () { widget.onThemeChanged(AppThemes.classicLeather, 'جلد كلاسيكي'); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode, color: Colors.purpleAccent),
                title: const Text('مظلم فاخر (Cyberpunk)'),
                onTap: () { widget.onThemeChanged(AppThemes.luxuryDark, 'مظلم فاخر'); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode, color: Colors.blue),
                title: const Text('أبيض ناصع حديث'),
                onTap: () { widget.onThemeChanged(AppThemes.pureWhite, 'أبيض ناصع'); Navigator.pop(context); },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(context); widget.onLogout(); },
              ),
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
        title: Text('BASIM AI - مرحباً ${widget.username}'),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsModal)],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, size: 30, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('BASIM AI Assistant', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.username, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.chat), title: const Text('محادثة جديدة'), onTap: () { setState(() => _messages.clear()); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); widget.onLogout(); }),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 60, color: Theme.of(context).primaryColor),
                        const SizedBox(height: 16),
                        const Text('مرحباً بك في BASIM AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('اطرح أي سؤال برمجي وسأقوم بالرد واكتشاف اللغة تلقائياً.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: msg.isUser ? Theme.of(context).primaryColor.withOpacity(0.85) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: msg.isUser ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(msg.text, style: const TextStyle(fontSize: 15, height: 1.4)),
                              if (!msg.isUser && msg.text.contains('```')) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.copy_all, size: 14),
                                    label: const Text('تجميع ونسخ الكود الكامل (Assemble & Copy)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => _assembleAndCopyCode(msg.text),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'اكتب سؤالك الذكي هنا...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
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
