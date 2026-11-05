import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final List> registeredUsers = [];

void main() async {
  final router = Router();

  // 1. Signup Endpoint
  router.post('/api/signup', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final String? name = payload['name'];
      final String? username = payload['username'];
      final String? email = payload['email'];
      final String? password = payload['password'];

      if (name == null || username == null || email == null || password == null) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'All fields are required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (registeredUsers.any((u) => u['email'] == email)) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'Email already exists'}),
          headers: {'content-type': 'application/json'},
        );
      }

      registeredUsers.add({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      });

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Account created successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'Server error'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // 2. Login Endpoint
  router.post('/api/login', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final String? email = payload['email'];
      final String? password = payload['password'];

      final user = registeredUsers.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );

      if (user.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'Invalid email or password'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Logged in successfully', 'username': user['username']}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'Server error'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // 3. AI Responses Endpoint (Multi-language & Code Parts)
  router.post('/v1/responses', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final String userPrompt = payload['prompt'] ?? '';

      final bool isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(userPrompt);
      final bool requestsCode = userPrompt.toLowerCase().contains('code') || 
                                 userPrompt.contains('كود') || 
                                 userPrompt.contains('script');

      Map<String, dynamic> responseData = {};

      if (requestsCode) {
        if (isArabic) {
          responseData = {
            'text': 'إليك الكود المطلوب مقسماً إلى أجزاء لتجنب الاقتطاع والتنفيذ السليم:',
            'hasCodeParts': true,
            'parts': [
              {
                'partTitle': 'Part 1: Core Setup',
                'code': '-- Part 1\nlocal Core = {}\nCore.Status = "Running"\nprint("Core initialized")'
              },
              {
                'partTitle': 'Part 2: Main Logic',
                'code': '-- Part 2\nfunction Core:Execute()\n    print("Executing pipeline...")\nend\nCore:Execute()'
              }
            ]
          };
        } else {
          responseData = {
            'text': 'Here is your requested code divided into parts for smooth execution:',
            'hasCodeParts': true,
            'parts': [
              {
                'partTitle': 'Part 1: Core Setup',
                'code': '-- Part 1: Initializing Framework\nlocal Framework = {}\nprint("Framework Ready")'
              },
              {
                'partTitle': 'Part 2: Execution Logic',
                'code': '-- Part 2: Main Functions\nfunction Framework:Run()\n    print("Running system...")\nend\nFramework:Run()'
              }
            ]
          };
        }
      } else {
        if (isArabic) {
          responseData = {
            'text': 'لقد فهمت طلبك: "$userPrompt". كيف يمكنني مساعدتك أكثر؟',
            'hasCodeParts': false
          };
        } else {
          responseData = {
            'text': 'I understand your query: "$userPrompt". How can I assist you further?',
            'hasCodeParts': false
          };
        }
      }

      return Response.ok(
        jsonEncode(responseData),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'text': 'AI Error occurred'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await io.serve(handler, 'localhost', 3000);
  print('Dart AI Server active on http://${server.address.host}:${server.port}');
}
