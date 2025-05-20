
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:movie_aidea/util/thought_bubble_loader.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpandableButton extends StatefulWidget {
  final String title;
  final String description;
  final DocumentReference<Map<String, dynamic>> textRef;
  final String value;
  final Future<String> Function(String text) onGoPressed;
  final Future<void> Function(String text) speak;
  final Future<void> Function() stop;
  final ValueChanged<String> refresh;

  const ExpandableButton({
    super.key,
    required this.title,
    required this.description,
    required this.textRef,
    required this.value,
    required this.onGoPressed,
    required this.speak,
    required this.stop,
    required this.refresh,
  });

  @override
  State<ExpandableButton> createState() => _ExpandableButtonState();
}

class _ExpandableButtonState extends State<ExpandableButton> {
  late Future<void> Function() stop;
  bool makeChanges = false;
  bool _isLoading = false;
  bool editText = false;
  late TextEditingController controller;
  late TextEditingController changeController;
  bool isReading = false;
  String description = '';

  void updateDescription(String text) {
    setState(() {
      description = text;
    });
  }

  @override
  void initState() {
    super.initState();
    updateDescription(widget.description);
    stop = widget.stop;
    stop;
    controller = TextEditingController(text: description);
    changeController = TextEditingController(text: '');
  }

  void _submitText(String text) {
    setState(() {
      widget.textRef.update({widget.value: text});
    });
  }

  @override
  Widget build(BuildContext context) {
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
            ? ThoughtBubbleLoader()
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
        editText
            ? TextButton.icon(
                onPressed: () {
                  _submitText(controller.text);
                  setState(() {
                    editText = false;
                    updateDescription(controller.text);
                    // widget.description = controller.text;
                  });
                },
                label: const Text('Save'),
                icon: const Icon(Icons.check),
              )
            : FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _isLoading
                        ? ThoughtBubbleLoader()
                        : TextButton(
                            onPressed: () {
                              setState(() {
                                controller.text = description;
                                editText = true;
                              });
                            },
                            child: const Text('Edit Text'),
                          ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          makeChanges = !makeChanges;
                        });
                      },
                      child: const Text('Make changes'),
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
                      label:
                          isReading ? const Text('Stop') : const Text('Read'),
                      icon: isReading
                          ? const Icon(Icons.stop)
                          : const Icon(Icons.speaker),
                    ),
                  ],
                ),
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
                            borderRadius:
                                const BorderRadius.all(Radius.circular(32)),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
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
                        String response = await widget.onGoPressed(
                          'I want to replace $description and make the following changes ${changeController.text}. make it full and complete',
                        );
                        print('Response is: $response');

                        //widget.description = response;
                        setState(() {
                          updateDescription(response);
                          //widget.description = response;
                          controller.text = response;
                          changeController.text = '';
                          _isLoading = false;
                          makeChanges = false;
                          widget.refresh(controller.text);
                        });
                        _submitText(
                            response); // Ensure the new description is saved to Firestore
                      },
                      child: const Text('Go'),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
