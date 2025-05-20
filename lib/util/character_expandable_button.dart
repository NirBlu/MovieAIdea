
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:movie_aidea/util/thought_bubble_loader.dart';
import 'package:http/http.dart' as http;
import 'package:movie_aidea/util/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: must_be_immutable
class CharacterExpandableButton extends StatefulWidget {
  String id;
  String user;

  final String name;
  String backgroundStory;
  String looks;
  String imageUrl;
  //DatabaseReference currentRef;
  final Future<dynamic> Function() createImageCallback;
  final Future<void> Function(String text) speak;
  final Future<void> Function() stop;
  final ValueChanged<String> onLooksChanged;

  CharacterExpandableButton({
    super.key,
    required this.id,
    required this.user,
    required this.name,
    required this.backgroundStory,
    required this.looks,
    required this.imageUrl,
    required this.speak,
    required this.stop,
    required this.onLooksChanged,

    //required this.currentRef,
    required this.createImageCallback,
  });

  bool editText = false;
  TextEditingController controller2 = TextEditingController();
  TextEditingController bgController = TextEditingController();
  TextEditingController looksController = TextEditingController();

  @override
  State<CharacterExpandableButton> createState() =>
      _CharacterExpandableButtonState();
}

class _CharacterExpandableButtonState extends State<CharacterExpandableButton> {
  Uint8List? createdImage;
  bool imageCreated = false;
  bool isLoading = false;
  bool isReading = false;

  void _handleCreateImage() async {
    setState(() {
      isLoading = true;
    });
    Uint8List image = await widget.createImageCallback();
    setState(() {
      createdImage = image;
      imageCreated = true;
      isLoading = false;
    });
  }

  @override
  void initState() {
    getSavedImage();
    super.initState();
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
      isLoading = true;
    });

    Uint8List? imageData = await _fetchImageData();
    if (imageData != null) {
      setState(() {
        createdImage = imageData;
        imageCreated = true;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
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

  void _updateFirebase() async {
    try {
      //todo
    } catch (e) {
      print('Error updating Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var dataRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user)
        .collection('Scripts')
        .doc(widget.id)
        .collection('Characters')
        .doc(widget.name);
    return ExpansionTile(
      title: Text(widget.name),
      children: [
        const Text('Background Story:'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.editText
              ? TextField(
                  controller: widget.bgController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  minLines: 3,
                  onSubmitted: (_) async {
                    await dataRef.update({'Looks': widget.looks});
                    await dataRef.update({'BGStory': widget.backgroundStory});
                    widget.onLooksChanged(widget.looks);
                  },
                )
              : Text(widget.backgroundStory),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              if (isReading) {
                isReading = false;
                widget.stop();
              } else {
                widget.speak(widget.looks);
                isReading = true;
              }
            },
            label: isReading ? const Text('Stop') : const Text('Read'),
            icon:
                isReading ? const Icon(Icons.stop) : const Icon(Icons.speaker),
          ),
        ),
        const Divider(),
        const Text('Looks:'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.editText
              ? TextField(
                  controller: widget.looksController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  minLines: 3,
                  onSubmitted: (_) async {
                    await dataRef.update({'Looks': widget.looks});
                    await dataRef.update({'BGStory': widget.backgroundStory});
                    widget.onLooksChanged(widget.looks);
                  },
                )
              : Text(widget.looks),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              if (isReading) {
                isReading = false;
                widget.stop();
              } else {
                widget.speak(widget.looks);
                isReading = true;
              }
            },
            label: isReading ? const Text('Stop') : const Text('Read'),
            icon:
                isReading ? const Icon(Icons.stop) : const Icon(Icons.speaker),
          ),
        ),
        const Divider(),
        imageCreated
            ? ImageLoader(
                imageData: createdImage!,
                updateImageCreated: makeCreatedFalse,
              )
            : SizedBox.shrink(),
        // : isLoading
        //     ? const ThoughtBubbleLoader()
        //     : const Center(
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [

        //           ],
        //         ),
        //       ),
        widget.editText
            ? TextButton.icon(
                onPressed: () async {
                  widget.backgroundStory = widget.bgController.text;
                  widget.looks = widget.looksController.text;
                  await dataRef.update({'Looks': widget.looks});
                  await dataRef.update({'BGStory': widget.backgroundStory});
                  widget.onLooksChanged(widget.looks);
                  setState(() {
                    widget.editText = false;
                    widget.backgroundStory = widget.bgController.text;
                    widget.looks = widget.looksController.text;
                  });
                  //_updateFirebase();
                },
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              )
            : FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          widget.bgController.text = widget.backgroundStory;
                          widget.looksController.text = widget.looks;
                          widget.editText = true;
                        });
                      },
                      child: const Text('Edit Text'),
                    ),
                    imageCreated
                        ? isLoading
                            ? const ThoughtBubbleLoader()
                            : ElevatedButton(
                                onPressed: _handleCreateImage,
                                child: const Text('Regenerate Image'))
                        : isLoading
                            ? const ThoughtBubbleLoader()
                            : ElevatedButton(
                                onPressed: _handleCreateImage,
                                child: const Text('Create Image')),
                    DropdownButton<String>(
                      // itemHeight: 12,
                      value: selectedStyle,
                      items: imageStyles.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(
                            entry.key,
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedStyle = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
      ],
    );
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
