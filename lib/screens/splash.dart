
import 'package:flutter/material.dart';
import 'package:movie_aidea/util/thought_bubble_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ThoughtBubbleLoader(),
    );
  }
}
