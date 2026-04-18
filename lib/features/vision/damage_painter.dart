import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  final Rect? boundingBox;
  final String? label;

  DamagePainter({this.boundingBox, this.label});

  @override
  void paint(Canvas canvas, Size size) {
    if (boundingBox == null) return;

    final paintColor = label?.contains("D40") == true ? Colors.red : Colors.yellow;

    final paint = Paint()
      ..color = paintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(boundingBox!, paint);

    // HOMEWORK: Efek Kosmetik Teks dengan Shadow
    final textPainter = TextPainter(
      text: TextSpan(
        text: label ?? "Unknown",
        style: TextStyle(
          color: Colors.white, 
          backgroundColor: paintColor, 
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 3.0,
              color: Colors.black87, // Bayangan hitam agar kontras
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Mencegah teks terpotong di atas layar
    double textY = boundingBox!.top - 20;
    if (textY < 0) textY = boundingBox!.top + boundingBox!.height + 5;

    textPainter.paint(canvas, Offset(boundingBox!.left, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}