import 'package:flutter/material.dart';

class TodoPage extends StatefulWidget {
  final String uid;

  TodoPage({
    required this.uid,
  });

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<String> todoItems = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ]; // replace with your todo items
  List<bool> isChecked = [
    false,
    false,
    false,
    false,
    false,
  ]; // replace with your initial checkbox states

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/background.jpg'), // replace with your image asset path
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                      20.0, 75.0, 20.0, 20.0), // keep top margin at 150

                  width: double.infinity, // set width to full screen width
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'assets/images/todoheader.png', // replace with your image asset path
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 50.0), // add top margin
                    child: ListView.builder(
                      itemCount: todoItems.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Checkbox(
                            value: isChecked[index],
                            onChanged: (bool? value) {
                              setState(() {
                                isChecked[index] = value!;
                              });
                            },
                            visualDensity: VisualDensity
                                .adaptivePlatformDensity, // adjust the size of the checkbox
                          ),
                          title: Container(
                            padding: EdgeInsets.all(8.0), // add padding
                            decoration: BoxDecoration(
                              color: Color.fromARGB(
                                  152, 17, 17, 17), // add background color
                              borderRadius: BorderRadius.circular(
                                  10.0), // add border radius
                            ),
                            child: Text(
                              todoItems[index],
                              style: TextStyle(
                                color: Colors.white, // set text color to white
                                decoration: isChecked[index]
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
