/// Servicio de integración directa con Google Gemini API
/// RF-25: Asistente conversacional IA
library;

import 'package:dio/dio.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.0-flash';

  final Dio _dio = Dio();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Returns true if a Gemini API key was provided at compile time.
  static bool get hasApiKey => _apiKey.isNotEmpty;

  /// Sends a message to Gemini and returns the response text.
  /// [message] - the user's message
  /// [history] - conversation history as list of {role, content} maps
  /// [systemPrompt] - optional system context prompt
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>> history = const [],
    String? systemPrompt,
  }) async {
    final apiKey = _apiKey;
    final contents = <Map<String, dynamic>>[];

    // Add history
    for (final h in history) {
      contents.add({
        'role': h['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': h['content']},
        ],
      });
    }

    // Add current message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': message},
      ],
    });

    final body = <String, dynamic>{
      'contents': contents,
      if (systemPrompt != null)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      'generationConfig': {'temperature': 0.75, 'maxOutputTokens': 768},
    };

    final response = await _dio.post(
      '$_baseUrl/models/$_model:generateContent',
      queryParameters: {'key': apiKey},
      data: body,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    final candidates = response.data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }
    final parts = candidates[0]['content']['parts'] as List;
    return parts[0]['text'] as String;
  }
}
