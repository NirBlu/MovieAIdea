

import 'package:flutter/material.dart';

class ScriptButton extends ElevatedButton {
  final String title;
  final VoidCallback onPressed;
  final VoidCallback onDeleted;

  final Color backgroundColor;
  final Color textColor;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  ScriptButton({
    required this.title,
    required this.onPressed,
    required this.onDeleted,
    this.backgroundColor = Colors.blue,
    this.textColor = const Color.fromARGB(179, 255, 255, 255),
    this.elevation = 2.0,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
    super.key,
  }) : super(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            //primary: backgroundColor,
            // onPrimary: textColor,

            textStyle: const TextStyle(color: Colors.amber),
            backgroundColor: Color.fromARGB(179, 62, 62, 62),
            foregroundColor: Color.fromARGB(179, 255, 255, 255),
            shadowColor: const Color.fromARGB(255, 255, 255, 255),
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: const BorderSide(color: Colors.black),
            ),
            padding: padding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
              IconButton(onPressed: onDeleted, icon: const Icon(Icons.delete)),
            ],
          ),
        );
}
