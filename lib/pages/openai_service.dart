import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

class OpenAISerice {
  List<Map<String, String>> messageHistory = [];

  Future<String> getResponse(String message) async {
    final doc = await rootBundle.loadString('assets/documenten/inwerkmap.txt');

    if (message.isEmpty) {
      message = 'Kan je mij helpen met het inwerkproces?';
    } else {
      message = message;
    }

    messageHistory.add({
      'role': 'user',
      'content':
          'Je krijgt ook een document te zien waar je informatie uit kan halen $doc. . Je bent een inwerkhulp voor een zorg instelling, Je helpt met het inwerken van het persoon, dit doe je in stappen. Ik ga je zometeen vragen stellen. Ik verwacht een antwoord en vervolg vraag. Dit moet in het volgende format geschreven worden. {"answer": "<antwoord van de vraag hier>","next_question": "<Vervolg vraag hier>"} het is van belang dat je een JSON format aanhoud en dat je "answer" en "next_question" niet veranderd. De vraag is: $message.',
    });

    String apiKey = dotenv.env['OPENAI_KEY']!;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo-0125",
          "messages": messageHistory,
          "max_tokens": 2000,
          "temperature": 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        messageHistory.add({
          'role': 'assistant',
          'content': data['choices'][0]['message']['content'],
        });

        print(data['choices'][0]['message']['content']);

        return data['choices'][0]['message']['content'];
      }
      return jsonEncode({'error': 'Er is iets fout gegaan'});
    } catch (e) {
      print(e);
      return jsonEncode({'error': 'Er is iets fout gegaan'});
    }
  }
}
