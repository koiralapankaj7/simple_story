import 'dart:math' as math;
import 'package:flutter/material.dart';

///
class StoryCircle extends StatelessWidget {
  ///
  const StoryCircle({
    required Widget this.child,
    super.key,
    this.strokeWidth = 3.0,
    this.space = 2.0,
    this.strokeColors,
  }) : _builder = null;

  ///
  StoryCircle.decorated({
    required DecorationImage image,
    ValueSetter<BuildContext>? onPressed,
    DecorationPosition? position,
    this.child,
    super.key,
    this.strokeWidth = 3.0,
    this.space = 2.0,
    this.strokeColors,
  }) : _builder = ((context) {
          return DecoratedBox(
            position: position ?? DecorationPosition.background,
            decoration: BoxDecoration(image: image),
            child: Material(
              type: MaterialType.transparency,
              clipBehavior: Clip.hardEdge,
              child: onPressed != null
                  ? InkWell(onTap: () => onPressed(context), child: child)
                  : child,
            ),
          );
        });

  /// Circle stroke width
  final double strokeWidth;

  /// Space between stroke and child
  final double space;

  /// Colors for gradient
  final List<Color>? strokeColors;

  ///
  final Widget? child;

  ///
  final WidgetBuilder? _builder;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CirclePainter(
        strokeWidth: strokeWidth,
        colors: strokeColors ?? [Colors.blue, Colors.green, Colors.blue],
      ),
      child: Padding(
        padding: EdgeInsets.all(space + strokeWidth),
        child: ClipOval(child: _builder?.call(context) ?? child),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    this.strokeWidth = 4.0,
    this.colors,
  });

  final double strokeWidth;
  final List<Color>? colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    if (colors?.isEmpty ?? true) {
      paint.color = Colors.black;
    } else if (colors!.length == 1) {
      paint.color = colors![0];
    } else {
      paint.shader = SweepGradient(
        colors: colors!,
        endAngle: math.pi * 2,
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }
    // canvas.drawArc(
    //   Rect.fromCenter(center: center, width: size.width, height: size.height),
    //   math.pi / 4,
    //   2 * math.pi,
    //   false,
    //   paint,
    // );
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.strokeWidth != strokeWidth;
}
