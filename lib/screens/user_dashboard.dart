

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:movie_aidea/screens/all_in_one_screen.dart';
//import 'package:movie_aidea/screens/write_my_synopsis_screen.dart';
import 'package:movie_aidea/util/scripts_loader.dart';
import 'package:movie_aidea/util/subtle_texture.dart';
import 'package:movie_aidea/util/thought_bubble_loader.dart';
import 'package:movie_aidea/widget/script_button.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key, required this.userCredentials});
  final User userCredentials;

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late Future<List<ScriptButton>> _scriptButtonsFuture;
  late var collectionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userCredentials.uid);
  @override
  void initState() {
    super.initState();
    // _scriptButtonsFuture =
    //    loadScripts(context, widget.userCredentials, '', collectionRef);
    _fetchData();
  }

  Future<void> _refresh() async {
    _fetchData;
    setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() {
      _scriptButtonsFuture = loadScripts(
          context, widget.userCredentials, '', _refresh, collectionRef);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Image.asset(
            'assets/images/MovieAIdea.png', // Replace with the path to your image
            // fit: BoxFit.fitHeight,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shadowColor: Colors.red,
                      buttonPadding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        side: const BorderSide(
                            color: Color.fromARGB(255, 189, 47, 37),
                            width: 6.0),
                      ),
                      title: const Text('Logging out'),
                      content: const Text('Do you want to continue?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Dismiss the dialog
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              FirebaseAuth.instance.signOut();
                            });
                          },
                          child: const Text('Continue'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(
                Icons.exit_to_app_outlined,
                color: Theme.of(context).colorScheme.primary,
              ))
        ],
        automaticallyImplyLeading: false,
        title: const Center(
            child: Column(
          children: [
            Text('Movie AIdea',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(height: 5),
            Text('List of scripts',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ))
          ],
        )),
      ),
      body: CustomPaint(
        painter:
            SubtleBiggerRectanglesPainterShade(Theme.of(context).brightness),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FutureBuilder<List<ScriptButton>>(
                  future: _scriptButtonsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: ThoughtBubbleLoader());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text(
                              'No scripts were found, click the "+" to start'));
                    } else {
                      // Reverse the list to show the most recent scripts first
                      final reversedScripts = snapshot.data!.reversed.toList();
                      return ListView(
                          padding: const EdgeInsets.all(5),
                          shrinkWrap: true,
                          children: reversedScripts);
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(const Color
                      .fromARGB(255, 158, 203,
                      229)), // Change the color to your desired background color
                ),
                onPressed: () {
                  print('add button pressed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AllInOneScreen(
                            userCredentials: widget.userCredentials, id: '')),
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(Color.fromARGB(
                      255,
                      173,
                      173,
                      173)), // Change the color to your desired background color
                ),
                onPressed: _fetchData,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
