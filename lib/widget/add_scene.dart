

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:movie_aidea/util/parse_character.dart';
import 'package:movie_aidea/util/parse_scenes.dart';
import 'package:movie_aidea/util/thought_bubble_loader.dart';

class AddSceneButton extends StatefulWidget {
  final int index;
  final String synopsis;
  final String textBefore;
  final String textAfter;
  final Future<String> Function(String text) onGoPressed;
  final String userId;
  final String currentId;
  final List<Character> characters;
  final DocumentReference<Map<String, dynamic>> sceneRef;
  final ValueChanged<List<SceneParsing>> updateScenes;

  const AddSceneButton({
    super.key,
    required this.index,
    required this.synopsis,
    required this.textBefore,
    required this.textAfter,
    required this.onGoPressed,
    required this.userId,
    required this.currentId,
    required this.characters,
    required this.sceneRef,
    required this.updateScenes,
  });

  @override
  _AddSceneButtonState createState() => _AddSceneButtonState();
}

class _AddSceneButtonState extends State<AddSceneButton> {
  bool _isExpanded = false;
  final TextEditingController _textController = TextEditingController();
  bool isLoading = false;
  String prompt = '';
  String text = '';

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _sendText() async {
    // widget.onSend(_textController.text);
  }

  void updateSceneByNumber(
      String sceneNumberString, String newPrompt, String newText) async {
    try {
      // Convert the scene number string to an integer, subtract one
      int sceneNumber = int.parse(sceneNumberString) - 1;

      // Reference to the specific document in the correct path
      DocumentReference docRef =
          widget.sceneRef.collection('Scenes').doc('Scenes');

      // Fetch the current document
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Get the current data
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        // Check if the 'Scenes' field exists and is a list
        if (data.containsKey('Scenes') && data['Scenes'] is List) {
          List<dynamic> scenes =
              List.from(data['Scenes']); // Clone the list to modify it

          // Insert the new scene at the specified index
          scenes.insert(sceneNumber + 1, {
            'Number': sceneNumber + 2, // Correctly assign the new scene number
            'Prompt': newPrompt,
            'Text': newText,
            'imageUrl': '' // Initialize the new scene with an empty imageUrl
          });

          // Increment the "Number" field for all scenes after the inserted one
          for (int i = sceneNumber + 2; i < scenes.length; i++) {
            if (scenes[i] != null && scenes[i].containsKey('Number')) {
              scenes[i]['Number'] = i + 1;
            } else if (scenes[i] == null || scenes[i].isEmpty) {
              scenes[i] = {
                'Number': i + 1
              }; // Initialize the map if it's null or empty
            }
          }

          // Update the 'Scenes' field in the document
          data['Scenes'] = scenes;
        } else {
          // If the 'Scenes' field doesn't exist, create it as a list
          data['Scenes'] = [
            {
              'Number': sceneNumber + 1,
              'Prompt': newPrompt,
              'Text': newText,
              'imageUrl': ''
            }
          ];
        }
        List<SceneParsing> sortedScenes = data['Scenes']
            .map((entry) => SceneParsing.fromMap({
                  "Number": entry['Number'].toString(),
                  "Text": entry['Text'],
                  "Prompt": entry['Prompt'],
                  "imageUrl": '',
                }))
            .toList()
            .cast<SceneParsing>();

        widget.updateScenes(sortedScenes);
        // Update the entire document with the modified data
        await docRef.set(data);

        print("Field updated successfully with parsed data");
      } else {
        print("Document does not exist");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _submitText(String newPrompt, String newText) {
    setState(() {
      updateSceneByNumber(widget.index.toString(), newPrompt, newText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          key: ValueKey(widget.index),
          onPressed: _toggleExpanded,
          label: const Text('Add Scene'),
          icon: const Icon(Icons.add),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
                ? const ThoughtBubbleLoader()
                : Row(
                    children: [
                      Flexible(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            labelText: 'Optional comments',
                          ),
                        ),
                      ),
                      const SizedBox(
                          width:
                              8.0), // Optional: add spacing between the TextField and the button
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });

                          String response = await widget.onGoPressed(
                              'write a scene that would go between these two scenes 1: ${widget.textBefore} and 2:${widget.textAfter} make sure it follow the synopsis: ${widget.synopsis} and uses these characters: ${widget.characters} ${_textController.text} make sure to write in json format that includes Text and Prompt, Text should have the scene and Prompt should have the description of the scene to generate an image, both with first letter capital');
                          String trimmedText = response
                              .replaceAll('</center>', '')
                              .replaceAll('<center>', '')
                              .replaceAll("json", '')
                              .replaceAll("```JSON", '')
                              .replaceAll('**', '')
                              .replaceAll('*', '')
                              .replaceAll('\n', '')
                              .replaceAll('/n', '')
                              .replaceAll('```', '')
                              .trim();
                          Map<String, dynamic> parseResponse =
                              jsonDecode(trimmedText);
                          prompt = parseResponse['Prompt'];
                          text = parseResponse['Text'];
                          print('Prompt: $prompt Text: $text');
                          _submitText(prompt, text);

                          setState(() {
                            isLoading = false;
                          });
                          _textController.clear();
                          _toggleExpanded();
                        },
                        child: const Text('Go'),
                      ),
                    ],
                  ),
          )
      ],
    );
  }
}
