import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:linqapp/services/secrets.dart';
import 'package:flutter_sound/flutter_sound.dart';

class OpenAIService {
  String apiKey = OPENAI_KEY;
  List<Map<String, String>> messageHistory = [];
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  String voice = '';

  OpenAIService() {
    _player.openPlayer();
  }

  bool checkJson(Map<String, dynamic> json) {
    if (json.containsKey('answer') && json.containsKey('next_question')) {
      return true;
    }
    return false;
  }

  Future<String> getResponse(String message) async {
    final doc = await rootBundle.loadString('assets/documenten/inwerkmap.txt');

    if (messageHistory.isEmpty) {
      message = 'Hallo, ik ben nieuw hier. Kan je mij helpen met inwerken?';
    }

    messageHistory.add({
      'role': 'user',
      'content':
          'Je krijgt ook een document te zien waar je informatie uit kan halen $doc. Je bent een inwerkhulp voor een zorg instelling, Je helpt met het inwerken van het persoon, dit doe je in stappen. Ik ga je zometeen vragen stellen. Ik verwacht een antwoord en vervolg vraag. Dit moet in het volgende format geschreven worden. {"answer": "<antwoord van de vraag hier>","next_question": "<Vervolg vraag hier>"} het is van belang dat je een JSON format aanhoud en dat je "answer" en "next_question" niet veranderd. De vraag is: $message.',
    });

    if (messageHistory.length > 5) {
      messageHistory = messageHistory.sublist(messageHistory.length - 5);
    }

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

//checkt of de json response van de AI voldoet aan de verwachtingen
        if (!checkJson(contentMap)) {
          return jsonEncode({'error': 'Onverwachte respons van de AI'});
        }

        voice = contentMap['answer'] ?? '';

        await getSpeech(voice);

        return data['choices'][0]['message']['content'];
      }

      print('Error from OpenAI API: ${response.body}');
      return jsonEncode({'error': 'Er is iets fout gegaan'});
    } catch (e) {
      print(e);
      return jsonEncode({'error': 'Er is iets fout gegaan'});
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
        print('Bytes length: ${bytes.length}');
        await _player.startPlayer(
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
