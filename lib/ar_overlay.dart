import 'package:flutter/material.dart';

class ArOverlayPainter extends CustomPainter {
  final List<OverlayText> overlayTexts;
  final Size absoluteImageSize;

  ArOverlayPainter(this.overlayTexts, this.absoluteImageSize);

  @override
  void paint(Canvas canvas, Size size) {

    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final double uniformScale = scaleX > scaleY ? scaleX : scaleY;

    final double offsetX = (size.width - absoluteImageSize.width * uniformScale) / 2;
    final double offsetY = (size.height - absoluteImageSize.height * uniformScale) / 2;

    for (final text in overlayTexts) {

      final left = text.boundingBox.left * uniformScale + offsetX;
      final top = text.boundingBox.top * uniformScale + offsetY;
      final right = text.boundingBox.right * uniformScale + offsetX;
      final bottom = text.boundingBox.bottom * uniformScale + offsetY;

      final textSpan = TextSpan(
        text: text.convertedPrice,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final paddingX = 20.0;
      final paddingY = 12.0;
      final width = textPainter.width + paddingX * 2;
      final height = textPainter.height + paddingY * 2;

      final centerX = left + (right - left) / 2;
      final centerY = top + (bottom - top) / 2;

      final topRect = Rect.fromCenter(center: Offset(centerX, top - 16 - height / 2), width: width, height: height);
      final bottomRect = Rect.fromCenter(center: Offset(centerX, bottom + 16 + height / 2), width: width, height: height);
      final rightRect = Rect.fromCenter(center: Offset(right + 16 + width / 2, centerY), width: width, height: height);
      final leftRect = Rect.fromCenter(center: Offset(left - 16 - width / 2, centerY), width: width, height: height);

      Rect clampRect(Rect r) {
        double dx = 0;
        double dy = 0;
        if (r.left < 8) dx = 8 - r.left;
        if (r.right > size.width - 8) dx = (size.width - 8) - r.right;
        if (r.top < 8) dy = 8 - r.top;
        if (r.bottom > size.height - 8) dy = (size.height - 8) - r.bottom;
        return r.shift(Offset(dx, dy));
      }

      final candidates = [
        {'rect': clampRect(topRect), 'pos': 'top'},
        {'rect': clampRect(rightRect), 'pos': 'right'},
        {'rect': clampRect(leftRect), 'pos': 'left'},
        {'rect': clampRect(bottomRect), 'pos': 'bottom'},
      ];

      final otherBoxes = overlayTexts
          .where((t) => t != text)
          .map((t) => Rect.fromLTRB(
                t.boundingBox.left * uniformScale + offsetX,
                t.boundingBox.top * uniformScale + offsetY,
                t.boundingBox.right * uniformScale + offsetX,
                t.boundingBox.bottom * uniformScale + offsetY,
              ))
          .toList();

      Map<String, dynamic> bestCandidate = candidates.first;
      int minCollisions = 99999;

      for (var cand in candidates) {
        int collisions = 0;
        final cRect = cand['rect'] as Rect;
        for (var ob in otherBoxes) {
          if (cRect.overlaps(ob)) collisions++;
        }
        if (collisions < minCollisions) {
          minCollisions = collisions;
          bestCandidate = cand;
        }
      }

      final bubbleRect = bestCandidate['rect'] as Rect;
      final pos = bestCandidate['pos'] as String;

      canvas.drawShadow(
        Path()..addRRect(RRect.fromRectAndRadius(bubbleRect, const Radius.circular(24))),
        Colors.greenAccent.withOpacity(0.2),
        12,
        true,
      );

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF1A1A1A).withOpacity(0.95),
            const Color(0xFF000000).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bubbleRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(bubbleRect, const Radius.circular(24)),
        paint,
      );

      final borderPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bubbleRect, const Radius.circular(24)),
        borderPaint,
      );

      final pointerPath = Path();
      if (pos == 'top') {
        pointerPath.moveTo(centerX - 10, bubbleRect.bottom);
        pointerPath.lineTo(centerX + 10, bubbleRect.bottom);
        pointerPath.lineTo(centerX, bubbleRect.bottom + 12);
      } else if (pos == 'bottom') {
        pointerPath.moveTo(centerX - 10, bubbleRect.top);
        pointerPath.lineTo(centerX + 10, bubbleRect.top);
        pointerPath.lineTo(centerX, bubbleRect.top - 12);
      } else if (pos == 'left') {
        pointerPath.moveTo(bubbleRect.right, centerY - 10);
        pointerPath.lineTo(bubbleRect.right, centerY + 10);
        pointerPath.lineTo(bubbleRect.right + 12, centerY);
      } else if (pos == 'right') {
        pointerPath.moveTo(bubbleRect.left, centerY - 10);
        pointerPath.lineTo(bubbleRect.left, centerY + 10);
        pointerPath.lineTo(bubbleRect.left - 12, centerY);
      }
      pointerPath.close();
      canvas.drawPath(pointerPath, paint);
      canvas.drawPath(pointerPath, borderPaint); 

      textPainter.paint(
        canvas,
        Offset(
          bubbleRect.left + paddingX,
          bubbleRect.top + paddingY,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArOverlayPainter oldDelegate) {
    return true; 
  }
}

class OverlayText {
  final Rect boundingBox;
  final String convertedPrice;

  OverlayText(this.boundingBox, this.convertedPrice);
}

