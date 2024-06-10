import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linqapp/pages/assistent.dart';
import 'package:linqapp/pages/todo.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  final String uid;

  HomePage({required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String naam = '';

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  Future<void> getUserName() async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          naam = userDoc['naam'];
        });
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 125.0, left: 75.0, right: 75.0),
              padding: EdgeInsets.all(16.0),
              width: double.infinity,
              height: 90.0,
              decoration: BoxDecoration(
                color: Color.fromARGB(73, 0, 0, 0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                'Welkom, $naam! Hoe kan ik je helpen?',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 250.0,
                    margin: EdgeInsets.only(top: 100.0),
                    child: Image.asset(
                      'assets/images/T-shirt.png', // replace with your image asset path
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        print('Image clickedsdf!');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodoPage(uid: widget.uid),
                          ),
                        ); // replace 'your-uid' with the actual uid // replace TodoPage() with your Todo page widget
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 100.0), // set top margin
                        width: 100.0,
                        height: 100.0,
                        child: SvgPicture.asset(
                          'assets/images/todo.svg', // replace with your SVG asset path
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 100.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AssistantPage()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(32, 87, 117, 0),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child:
                                  SvgPicture.asset('assets/images/AI_hulp.svg'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(child: Center()),
          ],
        ),
      ),
    );
  }
}
