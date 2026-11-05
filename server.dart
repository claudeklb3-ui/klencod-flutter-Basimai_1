// server.dart
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;

// قاعدة بيانات حقيقية مؤقتة في الذاكرة لتخزين حسابات المستخدمين المسجلين
final Map<String, Map<String, String>> registeredUsers = {};

void main() async {
  final app = Router();

  // 1. مسار إنشاء حساب حقيقي (Sign Up)
  app.post('/api/signup', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final name = payload['name'];
      final username = payload['username'];
      final email = payload['email'];
      final password = payload['password'];

      if (name == null || username == null || email == null || password == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'جميع الحقول مطلوبة'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (registeredUsers.containsKey(email)) {
        return Response(400,
          body: jsonEncode({'error': 'البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // حفظ الحساب الحقيقي
      registeredUsers[email] = {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      };

      return Response.ok(
        jsonEncode({'message': 'تم إنشاء الحساب بنجاح', 'email': email}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  // 2. مسار تسجيل دخول حقيقي (Login)
  app.post('/api/login', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final email = payload['email'];
      final password = payload['password'];

      if (!registeredUsers.containsKey(email)) {
        return Response(401,
          body: jsonEncode({'error': 'البريد الإلكتروني غير مسجل'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = registeredUsers[email]!;
      if (user['password'] != password) {
        return Response(401,
          body: jsonEncode({'error': 'كلمة المرور غير صحيحة'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'message': 'تم تسجيل الدخول بنجاح',
          'user': {
            'name': user['name'],
            'username': user['username'],
            'email': user['email']
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  // 3. مسار الذكاء الاصطناعي الحقيقي (POST /v1/responses)
  app.post('/v1/responses', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final prompt = payload['prompt'] ?? '';
      
      // جلب مفتاح OpenAI الحقيقي من متغيرات النظام (Environment Variables)
      final apiKey = Platform.environment['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'مفتاح OpenAI API غير متوفر في الخادم'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // الاتصال الحقيقي بنموذج الذكاء الاصطناعي
      final aiResponse = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are BASIM AI, an elite full-stack software engineer. Automatically detect the user\'s language and respond fluently in the exact same language. If any code snippet is lengthy, explicitly split it into structured parts labeled as [Part 1], [Part 2], etc., inside markdown blocks to prevent truncation.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (aiResponse.statusCode != 200) {
        return Response(
          aiResponse.statusCode,
          body: aiResponse.body,
          headers: {'Content-Type': 'application/json'},
        );
      }

      final data = jsonDecode(aiResponse.body);
      final aiReply = data['choices'][0]['message']['content'];

      return Response.ok(
        jsonEncode({'response': aiReply}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'خطأ في معالجة طلب الذكاء الاصطناعي: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // إعدادات الـ CORS للسماح بالاتصال من تطبيقات الويب والموبايل
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware((innerHandler) {
        return (request) async {
          if (request.method == 'OPTIONS') {
            return Response.ok('', headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
            });
          }
          final response = await innerHandler(request);
          return response.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
          });
        };
      })
      .addHandler(app);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  print('🚀 خادم BASIM AI الحقيقي يعمل الآن على: http://${server.address.host}:${server.port}');
}
