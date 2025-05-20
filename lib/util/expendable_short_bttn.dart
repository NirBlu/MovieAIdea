

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class ExpandableShortButton extends StatefulWidget {
  final String title;
  String description;
  final Future<void> Function(String text) speak;
  final Future<void> Function() stop;
  //DatabaseReference currentRef;

  ExpandableShortButton({
    super.key,
    required this.title,
    required this.description,
    required this.speak,
    required this.stop,
    //required this.currentRef,
  });
  bool editText = false;
  TextEditingController controller = TextEditingController();

  @override
  State<ExpandableShortButton> createState() => _ExpandableShortButtonState();
}

class _ExpandableShortButtonState extends State<ExpandableShortButton> {
  bool isReading = false;
  @override
  Widget build(BuildContext context) {
    //bool editText = false;
    return ExpansionTile(
      title: Text(
        widget.title,
        // textAlign: TextAlign.center,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.editText
              ? Scrollbar(
                  thickness: 5,
                  child: SingleChildScrollView(
                    child: TextField(
                      textAlign: TextAlign.center,
                      style: GoogleFonts.merriweather(),
                      controller: widget.controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        //labelText: 'Description',
                      ),
                      maxLines: null,
                      minLines: 1,
                      onSubmitted: (_) => <void>{},
                    ),
                  ),
                )
              : Scrollbar(
                  thickness: 5,
                  child: SingleChildScrollView(
                      child: Text(
                    textAlign: TextAlign.center,
                    widget.description,
                    style: GoogleFonts.merriweather(),
                  ))),
        ),
        widget.editText
            ? TextButton.icon(
                onPressed: () {
                  setState(() {
                    widget.editText = false;
                    widget.description = widget.controller.text;
                    // widget.currentRef.set(widget.controller.text);
                  });
                },
                label: const Icon(Icons.check))
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        widget.controller.text = widget.description;
                        widget.editText = true;
                      });

                      // Handle button press
                    },
                    child: const Text('Edit Text'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (isReading) {
                        isReading = false;
                        widget.stop();
                      } else {
                        widget.speak(widget.description);
                        isReading = true;
                      }
                    },
                    label: isReading ? const Text('Stop') : const Text('Read'),
                    icon: isReading
                        ? const Icon(Icons.stop)
                        : const Icon(Icons.speaker),
                  ),
                ],
              ),
      ],
    );
  }
}
