

import 'package:flutter/material.dart';

class ImageTextFormField extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController? controller;
  final bool isReadyOnly;
  final void Function(String) onFieldSubmitted;
  final void Function() onPickImage;

  const ImageTextFormField(
      {super.key,
      required this.focusNode,
      this.controller,
      this.isReadyOnly = false,
      required this.onPickImage,
      required this.onFieldSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        autofocus: true,
        autocorrect: false,
        focusNode: focusNode,
        controller: controller,
        readOnly: isReadyOnly,
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(16),
          hintText: "Enter your prompt",
          suffixIcon: IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: onPickImage,
          ),
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
