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

class Typewriter extends StatefulWidget {
  final String text;

  Typewriter(this.text);

  @override
  _TypewriterState createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter> with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<int> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    animation = StepTween(begin: 0, end: widget.text.length).animate(controller)
      ..addListener(() {
        setState(() {});
      });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, animation.value),
      style: TextStyle(
        color: Colors.white,
        fontSize: 20.0,
      ),
    );
  }
}

class _AssistantPageState extends State<AssistantPage>
    with TickerProviderStateMixin {
  final speechToText = SpeechToText();
  bool aisListening = false;
  bool isThinking = false;
  String lastWords = '';
  String vervolgText = '';
  String nextQuestion = '';
  final OpenAIService openAISerice = OpenAIService();
  late AnimationController _controller;
  Widget dynamicText = Container();

  Widget getDynamicText(dynamic input) {
    if (input is String) {
      return Text(
        input,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
        ),
      );
    } else {
      return Container();
    }
  }

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    dynamicText =
        getDynamicText('Klik op de microfoon om te beginnen met praten.');
  }

  Future<void> initSpeechToText() async {
    speechToText.initialize();
    setState(() {});
  }

  void startListening() async {
    await speechToText.listen(
      onResult: onSpeechResult,
      pauseFor: Duration(seconds: 2),
      localeId: 'nl_NL',
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
    setState(() {
      isThinking = true;
      dynamicText = getDynamicText('Aan het denken...');
    });
    try {
      final response = await openAISerice.getResponse(lastWords);
      final content = jsonDecode(response);
      if (content['error'] != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(content['error']),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }
      nextQuestion = content['next_question'] ?? '';
      final res = content['answer'] ?? '';

      setState(() {
        dynamicText = Typewriter(res);
        vervolgText = nextQuestion;
        isThinking = false;
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
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

  void updateText() {
    setState(() {
      dynamicText = getDynamicText("aan het luisteren...");
    });
  }

  void createNextQuestion() async {
    setState(() {
      isThinking = true;
      dynamicText = getDynamicText('Aan het denken...');
    });
    final response = await openAISerice.getResponse(vervolgText);
    final content = jsonDecode(response);
    if (content['error'] != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(content['error']),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    nextQuestion = content['next_question'] ?? '';
    final res = content['answer'] ?? '';

    setState(() {
      dynamicText = Typewriter(res);
      vervolgText = nextQuestion;
      isThinking = false;
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
                  onTap: isThinking
                      ? null // Als de AI aan het denken is, gebeurt er niks on tap
                      : () async {
                          if (aisListening == true) {
                            stopListening(); // Als de AI al luistert, stop dan met luisteren
                          } else if (await speechToText.hasPermission) {
                            updateText(); // Als de AI toestemming heeft om te luisteren, voer de functie uit
                            startListening(); // en start met luisteren
                          } else {
                            initSpeechToText(); // Als de assistent geen toestemming heeft, initialiseer dan de spraak-naar-tekst functionaliteit
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
                    child: dynamicText,
                  ),
                ),
              ),
              SizedBox(height: 100.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.0),
                child: vervolgText.isEmpty || isThinking
                    ? Container() // Als er geen vervolgtekst is of als de assistent aan het denken is, toon dan een lege container
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Color.fromARGB(50, 0, 0, 0),
                        ),
                        onPressed: () {
                          createNextQuestion(); // Wanneer de knop wordt ingedrukt, maak de vervolg vraag
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            vervolgText, // De tekst van de knop is de vervolgtekst
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
