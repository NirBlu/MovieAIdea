

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_aidea/screens/all_in_one_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:movie_aidea/widget/script_button.dart';

Future<List<ScriptButton>> loadScripts(
    BuildContext context,
    User userCredentials,
    String id,
    VoidCallback refresh,
    DocumentReference<Map<String, dynamic>> collectionRef) async {
  //final response = await collectionRef.collection('Scripts').get();
  //final Map<String, dynamic> scriptList = json.decode(response);
  QuerySnapshot querySnapshot = await collectionRef.collection('Scripts').get();
  final scriptList = querySnapshot.docs.map((doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    id = doc.id;
    return data;
  }).toList();
  // Use map() with null-aware operators to handle potential null values
  return scriptList.map((item) {
    final title = item['title'] as String?;
    final id = item['id'] as String?;
    //print(id);
    //final moviekey = item.value['name'] as String?;
    return ScriptButton(
      title: title ?? 'No Title', // Default to 'No Title' if title is null
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AllInOneScreen(userCredentials: userCredentials, id: id!)));
        // Define the action when the script button is pressed
      },
      onDeleted: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Are you sure?'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('You are about to completely delete this script.'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                ),
                TextButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    var dataRef = collectionRef.collection('Scripts');
                    dataRef.doc(id).delete();

                    // Perform your action here
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }).toList();
}
