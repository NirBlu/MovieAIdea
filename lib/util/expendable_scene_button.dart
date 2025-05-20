
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:movie_aidea/screens/image_to_video.dart';

import 'package:movie_aidea/util/thought_bubble_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:movie_aidea/util/styles.dart';

class ExpandableSceneButton extends StatefulWidget {
  final String title;
  final String description;
  final String prompt;
  final DocumentReference<Map<String, dynamic>> textRef;
  final String value;
  final Future<String> Function(String text) onGoPressed;
  final Future<void> Function(String text) speak;
  final Future<void> Function() stop;
  //final Future<void> refresh;
  final ValueChanged<String> onLooksChanged;
  final Future<String> Function(String text) makeImageDescription;
  final Future<dynamic> Function() createImageCallback;
  final String imageUrl;

  const ExpandableSceneButton({
    super.key,
    required this.title,
    required this.description,
    required this.prompt,
    required this.textRef,
    required this.value,
    required this.onGoPressed,
    required this.speak,
    required this.stop,
    required this.makeImageDescription,
    required this.createImageCallback,
    required this.imageUrl,
    required this.onLooksChanged,
    //required this.refresh,
  });

  @override
  State<ExpandableSceneButton> createState() => _ExpandableSceneButtonState();
}

class _ExpandableSceneButtonState extends State<ExpandableSceneButton> {
  late Future<void> Function() stop;
  bool makeChanges = false;
  bool _isLoading = false;
  bool editText = false;
  bool editLooks = false;
  late TextEditingController controller;
  late TextEditingController changeController;
  late TextEditingController looksController;
  bool isReading = false;
  bool gotDescription = false;
  bool gotPics = false;
  List<String> urlList = [];
  bool isloading = false;
  String make = '';
  Uint8List? createdImage;
  bool imageCreated = false;
  String description = '';
  String looks = '';

  void updateDescription(String text) {
    setState(() {
      description = text;
    });
  }

  void updateLooks(String text) {
    setState(() {
      looks = text;
    });
  }

  void _handleCreateImage() async {
    setState(() {
      isloading = true;
    });
    Uint8List image = await widget.createImageCallback();
    setState(() {
      createdImage = image;
      imageCreated = true;
      isloading = false;
    });
  }

  Future<Uint8List?> _fetchImageData() async {
    try {
      if (widget.imageUrl != '') {
        final response = await http.get(Uri.parse(widget.imageUrl));
        createdImage = response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching data: $e');
      imageCreated = false;
    }
    setState(() {});
    return createdImage;
  }

  void getSavedImage() async {
    setState(() {
      isloading = true;
    });

    Uint8List? imageData = await _fetchImageData();
    if (imageData != null) {
      setState(() {
        createdImage = imageData;
        imageCreated = true;
        isloading = false;
      });
    } else {
      setState(() {
        isloading = false;
        imageCreated = false;
      });
    }
  }

  void makeCreatedFalse(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          imageCreated = value;
        });
      }
    });
  }

  @override
  void initState() {
    getSavedImage();
    super.initState();
    updateDescription(widget.description);
    updateLooks(widget.prompt);
    stop = widget.stop;
    stop;
    controller = TextEditingController(text: description);
    changeController = TextEditingController(text: '');
    looksController = TextEditingController(text: looks);
  }

  void _submitText(String text) {
    description = text;
    setState(() {
      updateSceneByNumber(widget.title, text);
    });
  }

  void _submitLooksText(String text) {
    setState(() {
      looks = text;
      updateSceneByNumber(widget.title, text);
    });
    widget.onLooksChanged(looks);
  }

  void updateSceneByNumber(String sceneNumberString, String newPrompt) async {
    try {
      // Convert the scene number string to an integer, subtract one
      int sceneNumber = int.parse(sceneNumberString) - 1;

      // Reference to the specific document in the correct path
      DocumentReference docRef =
          widget.textRef.collection('Scenes').doc('Scenes');

      // Fetch the current document
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Get the current data
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        // Check if the 'Scenes' field exists and is a list
        if (data.containsKey('Scenes') && data['Scenes'] is List) {
          List<dynamic> scenes =
              List.from(data['Scenes']); // Clone the list to modify it

          // Ensure the list is large enough to hold the scene at the desired index
          if (scenes.length > sceneNumber) {
            scenes[sceneNumber] = {
              "Number": widget.title,
              "Prompt": looks,
              "Text": description
            };
          } else {
            // Add empty scenes if necessary to reach the correct index
            while (scenes.length <= sceneNumber) {
              scenes.add({});
            }
            scenes[sceneNumber] = {
              'Number': widget.title,
              'Prompt': newPrompt,
              "Text": description
            };
          }

          // Update the 'Scenes' field in the document
          data['Scenes'] = scenes;
        } else {
          // If the 'Scenes' field doesn't exist, create it as a list
          data['Scenes'] = [
            {
              'Number': widget.title,
              'Prompt': newPrompt,
              "Text": description,
            }
          ];
        }

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

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    stop();
  }

  @override
  Widget build(BuildContext context) {
    //widget.stop;
    final availableHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final remainingHeight = availableHeight - keyboardHeight - kToolbarHeight;

    return ExpansionTile(
      title: Text(
        widget.title,
        textAlign: TextAlign.center,
      ),
      children: [
        _isLoading
            ? const ThoughtBubbleLoader()
            : Container(
                constraints: BoxConstraints(
                  maxHeight: remainingHeight * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: editText
                        ? Container(
                            constraints: BoxConstraints(
                              minHeight: availableHeight * 0.1,
                              maxHeight: availableHeight * 0.2,
                            ),
                            child: Scrollbar(
                              thickness: 5,
                              child: SingleChildScrollView(
                                child: TextField(
                                  style: GoogleFonts.merriweather(),
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: null,
                                  minLines: 1,
                                  onSubmitted: (_) {
                                    _submitText(controller.text);
                                  },
                                ),
                              ),
                            ),
                          )
                        : Container(
                            constraints: BoxConstraints(
                              minHeight: availableHeight * 0.1,
                              maxHeight: availableHeight * 0.2,
                            ),
                            child: Scrollbar(
                              thickness: 5,
                              child: SingleChildScrollView(
                                child: Text(
                                  description,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.merriweather(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
        const Divider(),
        editLooks
            ? Container(
                constraints: BoxConstraints(
                  minHeight: availableHeight * 0.1,
                  maxHeight: availableHeight * 0.2,
                ),
                child: Scrollbar(
                  thickness: 5,
                  child: SingleChildScrollView(
                    child: TextField(
                      style: GoogleFonts.merriweather(),
                      controller: looksController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      minLines: 1,
                      onSubmitted: (_) {
                        _submitLooksText(looksController.text);
                      },
                    ),
                  ),
                ),
              )
            : Text('Looks Description: $looks'),
        editLooks
            ? TextButton.icon(
                onPressed: () {
                  _submitLooksText(looksController.text);
                  setState(() {
                    editLooks = false;
                    updateLooks(looksController.text);
                  });
                },
                label: const Text('Save'),
                icon: const Icon(Icons.check),
              )
            : editText
                ? TextButton.icon(
                    onPressed: () {
                      _submitText(controller.text);
                      setState(() {
                        editText = false;
                        updateDescription(controller.text);
                      });
                    },
                    label: const Text('Save'),
                    icon: const Icon(Icons.check),
                  )
                : Column(
                    children: [
                      FittedBox(
                        child: Row(
                          children: [
                            isloading
                                ? const ThoughtBubbleLoader()
                                : ElevatedButton(
                                    onPressed: _handleCreateImage,
                                    child: Text(imageCreated
                                        ? 'Regenerate Image'
                                        : 'Create Image'),
                                  ),
                            TextButton.icon(
                              onPressed: () {
                                if (isReading) {
                                  isReading = false;
                                  widget.stop();
                                } else {
                                  widget.speak(description);
                                  isReading = true;
                                }
                              },
                              label: isReading
                                  ? const Text('Stop')
                                  : const Text('Read'),
                              icon: isReading
                                  ? const Icon(Icons.stop)
                                  : const Icon(Icons.speaker),
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _isLoading
                                ? const ThoughtBubbleLoader()
                                : FittedBox(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          controller.text = description;
                                          editText = true;
                                        });
                                      },
                                      child: const Text('Edit Scene'),
                                    ),
                                  ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  looksController.text = looks;
                                  editLooks = true;
                                });
                              },
                              child: const Text('Edit Look'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  makeChanges = !makeChanges;
                                });
                              },
                              child: const Text('Make changes'),
                            ),
                          ],
                        ),
                      ),
                      ///////Expensive Video Generation ////////////////////
                      // imageCreated
                      //     ? ElevatedButton(
                      //         onPressed: () {
                      //           Navigator.push(
                      //               context,
                      //               MaterialPageRoute(
                      //                 builder: (_) => VideoGenerationScreen(
                      //                   imageUrl: widget.imageUrl,
                      //                   dataReference: widget.textRef,
                      //                 ),
                      //               ));
                      //         },
                      //         child: const Icon(Icons.video_camera_back))
                      //     : const SizedBox.shrink(),
                      ////////////End of Expensive Video Generation thats not good atm////////
                      Row(
                        children: [
                          Flexible(
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              return FittedBox(
                                child: DropdownButton<String>(
                                  // itemHeight: 12,
                                  value: selectedStyle,
                                  items: imageStyles.entries.map((entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.value,
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedStyle = newValue!;
                                    });
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      makeChanges
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      style: GoogleFonts.merriweather(),
                                      controller: changeController,
                                      onFieldSubmitted: (value) {
                                        // Handle field submission if needed
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(16),
                                        hintText: 'Enter Changes',
                                        border: OutlineInputBorder(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(32)),
                                          borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      String response =
                                          await widget.onGoPressed(
                                        'I want to take this scene $description and make the following changes ${changeController.text}. make it full and complete',
                                      );
                                      print('Response is: $response');
                                      _submitText(response);

                                      setState(() {
                                        updateDescription(response);
                                        controller.text = response;
                                        _isLoading = false;
                                        makeChanges = false;
                                      });

                                      // widget.refresh;

                                      // Ensure the new description is saved to Firestore
                                    },
                                    child: const Text('Go'),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      imageCreated
                          ? ImageLoader(
                              imageData: createdImage!,
                              updateImageCreated: makeCreatedFalse,
                            )
                          : isloading
                              ? const ThoughtBubbleLoader()
                              : const Center(
                                  child: Text('No image available'),
                                ),
                    ],
                  ),
      ],
    );
  }

  Future<void> makePhotoDescription() async {
    make = await widget.makeImageDescription(
        'take this scene $description and describe it as a single photo prompt for an AI image generator');
    if (make != '') {
      print('make : $make');
      isloading = false;
      gotDescription = true;
    } else {
      isloading = false;
    }
  }
}

class ImageLoader extends StatefulWidget {
  final Uint8List imageData;
  final Function(bool) updateImageCreated;

  ImageLoader({required this.imageData, required this.updateImageCreated});

  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader> {
  @override
  Widget build(BuildContext context) {
    return Image.memory(widget.imageData);
  }

  @override
  void initState() {
    super.initState();
    widget.updateImageCreated(true);
  }
}
