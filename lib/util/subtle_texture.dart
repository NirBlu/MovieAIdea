

import 'package:flutter/material.dart';
import 'dart:math';

//Circles:
class SubtleTexturePainter extends CustomPainter {
  final Brightness brightness;

  SubtleTexturePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw subtle texture
    for (double y = 0; y < size.height; y += 20) {
      for (double x = 0; x < size.width; x += 20) {
        canvas.drawCircle(Offset(x, y), 5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleTexturePainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Dots
class SubtleDotsPainter extends CustomPainter {
  final Brightness brightness;

  SubtleDotsPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // Draw subtle dots
    for (double y = 0; y < size.height; y += 5) {
      for (double x = 0; x < size.width; x += 5) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleDotsPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Crosses
class SubtleCrosshatchPainter extends CustomPainter {
  final Brightness brightness;

  SubtleCrosshatchPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SubtleCrosshatchPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Noise
class SubtleNoisePainter extends CustomPainter {
  final Brightness brightness;
  final Random random = Random();

  SubtleNoisePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // Draw organic noise
    for (double y = 0; y < size.height; y += 5) {
      for (double x = 0; x < size.width; x += 5) {
        if (random.nextDouble() > 0.8) {
          canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleNoisePainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//WaveyLines
class SubtleWavyLinesPainter extends CustomPainter {
  final Brightness brightness;

  SubtleWavyLinesPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw wavy lines
    for (double y = 0; y < size.height; y += 50) {
      Path path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 10) {
        path.lineTo(x, y + 5 * sin(x / 10));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SubtleWavyLinesPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Diagonal Lines
class SubtleDiagonalLinesPainter extends CustomPainter {
  final Brightness brightness;

  SubtleDiagonalLinesPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw diagonal lines
    for (double y = -size.height; y < size.height * 2; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SubtleDiagonalLinesPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Noisier Organic noise
class NoisierNoisePainter extends CustomPainter {
  final Brightness brightness;
  final Random random = Random();

  NoisierNoisePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // Draw noisier organic noise
    for (double y = 0; y < size.height; y += 3) {
      for (double x = 0; x < size.width; x += 3) {
        if (random.nextDouble() > 0.5) {
          canvas.drawCircle(Offset(x, y), random.nextDouble() * 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant NoisierNoisePainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Fixed Noisier

class FixedNoisierNoisePainter extends CustomPainter {
  final Brightness brightness;
  final List<Offset> noisePoints;
  final List<double> radii;

  FixedNoisierNoisePainter(this.brightness)
      : noisePoints = _generateNoisePoints(),
        radii = _generateRadii();

  static List<Offset> _generateNoisePoints() {
    List<Offset> points = [];
    final Random random = Random(0); // Fixed seed for consistent noise
    for (double y = 0; y < 1000; y += 3) {
      for (double x = 0; x < 1000; x += 3) {
        if (random.nextDouble() > 0.5) {
          points.add(Offset(x, y));
        }
      }
    }
    return points;
  }

  static List<double> _generateRadii() {
    List<double> radii = [];
    final Random random = Random(0); // Fixed seed for consistent radii
    for (int i = 0; i < 1000 * 1000 / 9; i++) {
      // Assuming 1000x1000 area with 3x3 spacing
      if (random.nextDouble() > 0.5) {
        radii.add(random.nextDouble() * 2);
      }
    }
    return radii;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < noisePoints.length; i++) {
      canvas.drawCircle(noisePoints[i], radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant FixedNoisierNoisePainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Random Rectangles
class SubtleRandomRectanglesPainter extends CustomPainter {
  final Brightness brightness;
  final Random random = Random();

  SubtleRandomRectanglesPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw random small rectangles
    for (double y = 0; y < size.height; y += 10) {
      for (double x = 0; x < size.width; x += 10) {
        if (random.nextDouble() > 0.7) {
          canvas.drawRect(
              Rect.fromLTWH(
                  x, y, random.nextDouble() * 5, random.nextDouble() * 5),
              paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleRandomRectanglesPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Diamond
class SubtleDiamondPainter extends CustomPainter {
  final Brightness brightness;

  SubtleDiamondPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw diamond shapes
    for (double y = 0; y < size.height; y += 40) {
      for (double x = 0; x < size.width; x += 40) {
        Path path = Path();
        path.moveTo(x, y);
        path.lineTo(x + 20, y + 20);
        path.lineTo(x, y + 40);
        path.lineTo(x - 20, y + 20);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleDiamondPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//DifferentWave
class SubtleDifferentWavePainter extends CustomPainter {
  final Brightness brightness;

  SubtleDifferentWavePainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw different wave lines
    for (double y = 0; y < size.height; y += 20) {
      Path path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 20) {
        path.quadraticBezierTo(x + 10, y + 10, x + 20, y);
        path.quadraticBezierTo(x + 30, y - 10, x + 40, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SubtleDifferentWavePainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Jagged Lines
class SubtleJaggedLinesPainter extends CustomPainter {
  final Brightness brightness;

  SubtleJaggedLinesPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw jagged lines
    for (double y = 0; y < size.height; y += 20) {
      Path path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 20) {
        path.lineTo(x + 10, y + 10);
        path.lineTo(x + 20, y - 10);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SubtleJaggedLinesPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Bigger Rectangles
class SubtleBiggerRectanglesPainter extends CustomPainter {
  final Brightness brightness;
  final Random random = Random();

  SubtleBiggerRectanglesPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw bigger rectangles
    for (double y = 0; y < size.height; y += 30) {
      for (double x = 0; x < size.width; x += 30) {
        if (random.nextDouble() > 0.7) {
          canvas.drawRect(Rect.fromLTWH(x, y, 20, 20), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleBiggerRectanglesPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Bigger Rectangles With shading
class SubtleBiggerRectanglesPainterShade extends CustomPainter {
  final Brightness brightness;
  final Random random = Random();

  SubtleBiggerRectanglesPainterShade(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw bigger rectangles with random brightness
    for (double y = 0; y < size.height; y += 30) {
      for (double x = 0; x < size.width; x += 30) {
        if (random.nextDouble() > 0.7) {
          final double opacity =
              random.nextDouble() * 0.03; // Random opacity between 0 and 0.1
          final Paint paint = Paint()
            ..color = brightness == Brightness.dark
                ? Colors.white.withOpacity(opacity)
                : Colors.black.withOpacity(opacity)
            ..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromLTWH(x, y, 18, 18), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SubtleBiggerRectanglesPainterShade oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}

//Fixed rectangles
class SubtleFixedBiggerRectanglesPainter extends CustomPainter {
  final Brightness brightness;
  final Random random = Random();
  final List<Rect> rectangles;
  final List<double> opacities;

  SubtleFixedBiggerRectanglesPainter(this.brightness)
      : rectangles = _generateRectangles(),
        opacities = _generateOpacities();

  static List<Rect> _generateRectangles() {
    List<Rect> rects = [];
    for (double y = 0; y < 1000; y += 30) {
      // Assuming a height of 1000 for example
      for (double x = 0; x < 1000; x += 30) {
        // Assuming a width of 1000 for example
        if (Random().nextDouble() > 0.7) {
          rects.add(Rect.fromLTWH(x, y, 20, 20));
        }
      }
    }
    return rects;
  }

  static List<double> _generateOpacities() {
    List<double> ops = [];
    for (int i = 0; i < 1000; i++) {
      // Assuming the same number of rectangles
      ops.add(Random().nextDouble() * 0.03);
    }
    return ops;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < rectangles.length; i++) {
      paint.color = brightness == Brightness.dark
          ? Colors.white.withOpacity(opacities[i])
          : Colors.black.withOpacity(opacities[i]);
      canvas.drawRect(rectangles[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant SubtleFixedBiggerRectanglesPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}
