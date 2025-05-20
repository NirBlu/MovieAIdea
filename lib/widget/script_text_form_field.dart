

import 'package:flutter/material.dart';

class ScriptTextFormField extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController? controller;
  final bool isReadyOnly;
  final void Function(String) onFieldSubmitted;

  const ScriptTextFormField({
    super.key,
    required this.focusNode,
    this.controller,
    this.isReadyOnly = false,
    required this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        autofocus: true,
        autocorrect: false,
        focusNode: focusNode,
        controller: controller,
        readOnly: isReadyOnly,
        //minLines: 2,
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          labelStyle: TextStyle(
            fontSize: MediaQuery.of(context).size.width *
                0.04, // Responsive font size
          ),
          contentPadding: EdgeInsets.all(16),
          hintText: 'Enter Your Movie Idea',
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter some prompt';
          } else {
            return null;
          }
        });
  }
}
