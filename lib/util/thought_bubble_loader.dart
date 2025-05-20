

import 'package:flutter/material.dart';
import 'dart:math';

class ThoughtBubbleLoader extends StatefulWidget {
  const ThoughtBubbleLoader({super.key});

  @override
  State<ThoughtBubbleLoader> createState() => _ThoughtBubbleLoaderState();
}

class _ThoughtBubbleLoaderState extends State<ThoughtBubbleLoader>
    with TickerProviderStateMixin {
  late AnimationController _mainBubbleController;
  late Animation<double> _mainBubbleAnimation;
  late AnimationController _smallBubbleController;
  late Animation<double> _smallBubbleAnimation;
  late AnimationController _smallBubble2Controller;
  late Animation<double> _smallBubble2Animation;

  late Animation<Color?> _mainBubbleColorAnimation;
  late Animation<Color?> _smallBubbleColorAnimation;
  late Animation<Color?> _smallBubble2ColorAnimation;

  @override
  void initState() {
    super.initState();

    // Random durations for the animations
    final random = Random();

    _mainBubbleController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 800 + random.nextInt(400)), // 0.8 to 1.2 seconds
    )..repeat(reverse: true);
    _mainBubbleAnimation = CurvedAnimation(
      parent: _mainBubbleController,
      curve: Curves.easeInOut,
    );

    _smallBubbleController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 800 + random.nextInt(400)), // 0.8 to 1.2 seconds
    )..repeat(reverse: true);
    _smallBubbleAnimation = CurvedAnimation(
      parent: _smallBubbleController,
      curve: Curves.easeInOut,
    );

    _smallBubble2Controller = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 800 + random.nextInt(400)), // 0.8 to 1.2 seconds
    )..repeat(reverse: true);
    _smallBubble2Animation = CurvedAnimation(
      parent: _smallBubble2Controller,
      curve: Curves.easeInOut,
    );

    // Color animations
    _mainBubbleColorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(_mainBubbleController);

    _smallBubbleColorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.green,
    ).animate(_smallBubbleController);

    _smallBubble2ColorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.yellow,
    ).animate(_smallBubble2Controller);
  }

  @override
  void dispose() {
    _mainBubbleController.dispose();
    _smallBubbleController.dispose();
    _smallBubble2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainBubbleAnimation,
          _smallBubbleAnimation,
          _smallBubble2Animation,
          _mainBubbleColorAnimation,
          _smallBubbleColorAnimation,
          _smallBubble2ColorAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: ThoughtBubblePainter(
              mainScale: _mainBubbleAnimation.value,
              smallScale: _smallBubbleAnimation.value,
              smallScale2: _smallBubble2Animation.value,
              mainBubbleColor: _mainBubbleColorAnimation.value ?? Colors.blue,
              smallBubbleColor: _smallBubbleColorAnimation.value ?? Colors.blue,
              smallBubble2Color:
                  _smallBubble2ColorAnimation.value ?? Colors.blue,
            ),
            child: const SizedBox(
              height: 100,
              width: 100,
            ),
          );
        },
      ),
    );
  }
}

class ThoughtBubblePainter extends CustomPainter {
  final double mainScale;
  final double smallScale;
  final double smallScale2;
  final Color mainBubbleColor;
  final Color smallBubbleColor;
  final Color smallBubble2Color;

  ThoughtBubblePainter({
    required this.mainScale,
    required this.smallScale,
    required this.smallScale2,
    required this.mainBubbleColor,
    required this.smallBubbleColor,
    required this.smallBubble2Color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = mainBubbleColor
      ..style = PaintingStyle.fill;

    final smallPaint = Paint()
      ..color = smallBubbleColor
      ..style = PaintingStyle.fill;

    final smallPaint2 = Paint()
      ..color = smallBubble2Color
      ..style = PaintingStyle.fill;

    double mainBubbleRadius = 30 * mainScale;
    double smallBubbleRadius = 10 * smallScale;
    double smallBubbleRadius2 = 8 * smallScale2;

    Offset mainBubbleCenter = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(mainBubbleCenter, mainBubbleRadius, mainPaint);

    Offset smallBubbleCenter = Offset(
      size.width / 2 - mainBubbleRadius * 1.2,
      size.height / 2 + mainBubbleRadius * 0.5,
    );
    canvas.drawCircle(smallBubbleCenter, smallBubbleRadius, smallPaint);

    Offset smallBubbleCenter2 = Offset(
      size.width / 2 - mainBubbleRadius * 1.5,
      size.height / 2 + mainBubbleRadius * 1.5,
    );
    canvas.drawCircle(smallBubbleCenter2, smallBubbleRadius2, smallPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: ThoughtBubbleLoader(),
    ),
  ));
}
