import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linqapp/services/openai_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AssistantPage extends StatefulWidget {
  @override
  _AssistantPageState createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage>
    with TickerProviderStateMixin {
  final speechToText = SpeechToText();
  bool aisListening = false;
  String lastWords = '';
  String vervolgText = '';
  String nextQuestion = '';
  final OpenAISerice openAISerice = OpenAISerice();
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> initSpeechToText() async {
    speechToText.initialize();
    setState(() {});
  }

  void startListening() async {
    await speechToText.listen(
      onResult: onSpeechResult,
      pauseFor: Duration(seconds: 2),
      localeId: 'nl_NL', // Stel de taal in op Nederlands
    );
    aisListening = true;

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!speechToText.isListening) {
        stopListening();
        timer.cancel();
      }
    });
  }

  void stopListening() async {
    aisListening = false;
    speechToText.stop();
    final response = await openAISerice.getResponse(lastWords);
    final content = jsonDecode(response);
    nextQuestion = content['next_question'] ?? '';
    final res = content['answer'] ?? '';

    setState(() {
      dynamicText = res;
      vervolgText = nextQuestion;
    });
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
  }

  String dynamicText = 'Klik op de rechterknop om een vraag te stellen!';

  void updateText() {
    setState(() {
      dynamicText = 'Aan het luisteren';
    });
  }

  void vervolgVraag() async {
    final response = await openAISerice.getResponse(vervolgText);

    final content = jsonDecode(response);
    nextQuestion = content['next_question'] ?? '';
    final res = content['answer'] ?? '';

    setState(() {
      dynamicText = res;
      vervolgText = nextQuestion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: Center(
                  child: SvgPicture.asset('assets/images/foto2.svg'),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 125.0),
                child: GestureDetector(
                  onTap: () async {
                    if (aisListening == true) {
                      stopListening();
                    } else if (await speechToText.hasPermission) {
                      updateText();
                      startListening();
                    } else {
                      initSpeechToText();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _controller,
                    child: SvgPicture.asset('assets/images/Mic.svg'),
                    builder: (BuildContext context, Widget? child) {
                      return Transform.scale(
                        scale: aisListening ? _controller.value + 0.9 : 1.0,
                        child: child,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 50.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.0),
                child: Container(
                  height: 150.0,
                  child: SingleChildScrollView(
                    child: Text(
                      dynamicText,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 100.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.0),
                child: vervolgText.isEmpty
                    ? Container() // Toon een lege container als vervolgText leeg is
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          primary: Color.fromARGB(50, 0, 0, 0),
                        ),
                        onPressed: () {
                          vervolgVraag();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            vervolgText,
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                            // Center the text
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
