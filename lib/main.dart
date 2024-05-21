import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:linqapp/pages/home.dart';
import 'services/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Numpad(),
    );
  }
}

class Numpad extends StatefulWidget {
  const Numpad({Key? key}) : super(key: key);

  @override
  _NumpadState createState() => _NumpadState();
}

class _NumpadState extends State<Numpad> {
  List<int> enteredNumbers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/background.jpg"), // Vervang dit door het pad naar uw afbeelding
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
              top: 150.0, left: 30, right: 30), // Add top margin
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.end, // Move the content to the bottom
            children: [
              Text(
                'Voer uw pincode in',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                  height:
                      20), // Add some space between the text and the numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < enteredNumbers.length
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : Color.fromARGB(102, 249, 249, 249),
                    ),
                  );
                }),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: <Widget>[
                    for (var i = 1; i <= 9; i++) buildButton(i),
                    Container(), // Empty space
                    buildButton(0),
                    TextButton(
                      onPressed: () {
                        if (enteredNumbers.isNotEmpty) {
                          setState(() {
                            enteredNumbers.removeLast();
                          });
                        }
                      },
                      child: Text(
                        'Verwijder',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void login() async {
    final enteredPin = 3678;

    final users = FirebaseFirestore.instance.collection('users');
    final querySnapshot =
        await users.where('code', isEqualTo: enteredPin).get();

    if (querySnapshot.docs.isNotEmpty) {
      print('User found, logging in...');
      final uid = querySnapshot.docs.first['uid'];
      print(uid); // Get the uid
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomePage(uid: uid), // Pass the uid to the next page
        ),
      );
      enteredNumbers.clear();
    } else {
      // User not found
      print('User not found');
      print('You have entered ${enteredNumbers.join()}');
    }
  }

  Widget buildButton(int number) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width *
            0.7, // Set the width to 70% of the screen width
        child: InkWell(
          onTap: () {
            if (enteredNumbers.length > 3) {
              login();
            } else {
              setState(() {
                enteredNumbers.add(number);
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color:
                  Color.fromARGB(255, 60, 167, 255), // Change the color to blue
              borderRadius: BorderRadius.circular(10), // Add a border radius
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white), // Change the text color to white
            ),
          ),
        ),
      ),
    );
  }
}
