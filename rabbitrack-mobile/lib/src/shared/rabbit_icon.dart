import 'package:flutter/material.dart';

class RabbitIcon extends StatelessWidget {
  const RabbitIcon({
    required this.color,
    required this.size,
    this.filled = false,
    super.key,
  });

  final Color color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RabbitIconPainter(color: color, filled: filled),
      ),
    );
  }
}

class _RabbitIconPainter extends CustomPainter {
  const _RabbitIconPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(6.2 * scale, 17.8 * scale)
      ..cubicTo(
        6.2 * scale,
        13.5 * scale,
        9.4 * scale,
        10.2 * scale,
        13.6 * scale,
        10.2 * scale,
      )
      ..cubicTo(
        17.8 * scale,
        10.2 * scale,
        20.4 * scale,
        13.1 * scale,
        20.4 * scale,
        17.5 * scale,
      )
      ..cubicTo(
        20.4 * scale,
        20.2 * scale,
        17.8 * scale,
        21.4 * scale,
        13.4 * scale,
        21.4 * scale,
      )
      ..cubicTo(
        9.2 * scale,
        21.4 * scale,
        6.2 * scale,
        20.3 * scale,
        6.2 * scale,
        17.8 * scale,
      )
      ..close();

    final head = Path()
      ..moveTo(4.4 * scale, 14.8 * scale)
      ..cubicTo(
        3.1 * scale,
        13.6 * scale,
        3.3 * scale,
        11.5 * scale,
        4.8 * scale,
        10.4 * scale,
      )
      ..cubicTo(
        6.7 * scale,
        9.0 * scale,
        9.0 * scale,
        10.3 * scale,
        9.0 * scale,
        12.7 * scale,
      )
      ..cubicTo(
        9.0 * scale,
        14.8 * scale,
        7.1 * scale,
        16.1 * scale,
        4.4 * scale,
        14.8 * scale,
      )
      ..close();

    final earBack = Path()
      ..moveTo(7.4 * scale, 10.2 * scale)
      ..cubicTo(
        7.0 * scale,
        6.6 * scale,
        8.1 * scale,
        3.5 * scale,
        10.1 * scale,
        2.6 * scale,
      )
      ..cubicTo(
        11.6 * scale,
        5.6 * scale,
        10.7 * scale,
        8.3 * scale,
        8.6 * scale,
        10.6 * scale,
      );

    final earFront = Path()
      ..moveTo(9.7 * scale, 10.4 * scale)
      ..cubicTo(
        10.1 * scale,
        6.6 * scale,
        12.0 * scale,
        3.8 * scale,
        14.3 * scale,
        3.2 * scale,
      )
      ..cubicTo(
        15.1 * scale,
        7.1 * scale,
        13.7 * scale,
        9.6 * scale,
        11.3 * scale,
        11.0 * scale,
      );

    final tail = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(20.0 * scale, 15.3 * scale),
          radius: 2.0 * scale,
        ),
      );

    if (filled) {
      canvas.drawPath(body, fill);
      canvas.drawPath(head, fill);
      canvas.drawPath(tail, fill);
    } else {
      canvas.drawPath(body, stroke);
      canvas.drawPath(head, stroke);
      canvas.drawPath(tail, stroke);
    }

    canvas.drawPath(earBack, stroke);
    canvas.drawPath(earFront, stroke);
    canvas.drawCircle(Offset(5.8 * scale, 12.7 * scale), 0.45 * scale, fill);
  }

  @override
  bool shouldRepaint(covariant _RabbitIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.filled != filled;
  }
}
