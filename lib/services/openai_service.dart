import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  String apiKey = dotenv.env['OPENAI_KEY'] ?? '';

  List<Map<String, String>> messageHistory = [];
  final FlutterSoundPlayer player = FlutterSoundPlayer();
  String voice = '';

  OpenAIService() {
    player.openPlayer();
  }

  bool checkJson(Map<String, dynamic> json) {
    if (json.containsKey('answer') && json.containsKey('next_question')) {
      return true;
    }
    return false;
  }

  Future<String> getResponse(String message) async {
    final doc = await rootBundle.loadString('assets/documenten/inwerkmap.txt');

    if (message.isEmpty) {
      message = 'Hallo, ik ben nieuw hier. Kan je mij helpen met inwerken?';
    }

    messageHistory.add({
      'role': 'user',
      'content':
          'Je krijgt ook een document te zien waar je informatie uit kan halen $doc. Je bent een inwerkhulp voor een zorg instelling, Je helpt met het inwerken van het persoon, dit doe je in stappen. Ik ga je zometeen vragen stellen. Ik verwacht een antwoord en vervolg vraag, BELANGRIJK: DE VERVOLGVRAAG MOET ZO OPGESTELD WORDEN DAT DE AI ASSISTENT DIE VRAAG KAN BEANTWOORDEN!. Dit moet in het volgende format geschreven worden. {"answer": "<antwoord van de vraag hier>","next_question": "<Vervolg vraag voor de AI hier>"} het is van belang dat je een JSON format aanhoud en dat je "answer" en "next_question" niet veranderd. De vraag is: $message.',
    });

    // Houd de messageHistory array op maximaal 6 items, verwijder de eerste 3 items als de lengte groter is dan 6, om te voorkomen dat de AI te veel informatie krijgt
    if (messageHistory.length > 6) {
      messageHistory = messageHistory.sublist(3);
    }

    try {
      print(apiKey);
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-4o-2024-05-13",
          "messages": messageHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        messageHistory.add({
          'role': 'assistant',
          'content': data['choices'][0]['message']['content'],
        });

        final content = data['choices'][0]['message']['content'];
        final contentMap = jsonDecode(content);

        if (!checkJson(contentMap)) {
          return jsonEncode({'error': 'Onverwachte respons van de AI'});
        }

        voice = contentMap['answer'] ?? '';

        await getSpeech(voice);

        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 503) {
        print('Error from OpenAI API: Service Unavailable');
        return jsonEncode({
          'error':
              'De service is momenteel niet beschikbaar. Probeer het over een paar minuten opnieuw.'
        });
      } else if (response.statusCode == 401) {
        print('Error from OpenAI API: Unauthorized');
        return jsonEncode(
            {'error': 'Ongeautoriseerde toegang. Controleer uw API-sleutel.'});
      } else {
        print('Error from OpenAI API: ${response.body}');
        return jsonEncode({
          'error':
              'Er is een onbekende fout opgetreden. HTTP status code: ${response.statusCode}'
        });
      }
    } catch (e) {
      print(e);
      return jsonEncode({'error': e.toString()});
    }
  }

  Future<void> getSpeech(String message) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/audio/speech'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "tts-1-hd",
          "voice": "nova",
          "input": voice,
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await player.startPlayer(
          fromDataBuffer: bytes,
          codec: Codec.aacMP4,
        );
      } else {
        print('Error from TTS API: ${response.body}');
      }
    } catch (e) {
      print(e);
    }
  }
}
