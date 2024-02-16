import 'package:flutter/material.dart';
import 'package:simple_utils/simple_utils.dart';
import 'widgets.dart';

///
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    required this.player,
    this.height = 3.0,
    this.padding,
    // this.axis = Axis.horizontal,
    super.key,
  });

  final StoryPlayer player;
  final double height;
  final EdgeInsetsGeometry? padding;
  // final Axis axis;

  @override
  Widget build(BuildContext context) {
    final count = player.length;
    final spacing = (count > 15) ? 1.0 : ((count > 10) ? 2.0 : 4.0);

    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: player.animation,
          builder: (context, child) {
            return Row(
              children: List.generate(
                count,
                (index) {
                  final progress = index == player.currentIndex
                      ? player.animation.value
                      : index < player.currentIndex
                          ? 1.0
                          : 0.0;
                  return Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: height,
                      backgroundColor: Colors.white.withOpacity(0.4),
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  );
                },
              ).paddedX(space: spacing),
            );
          },
        ),
      ),
    );
  }
}


// ///
// class CustomProgressbar extends StatelessWidget {
//   ///
//   const CustomProgressbar({
//     required this.progress,
//     super.key,
//     this.height,
//     this.width,
//     this.margin,
//     this.trackColor,
//     this.progressColors,
//     this.child,
//     this.progressRadius,
//     this.trackRadius,
//     this.trackStyle,
//   }) : assert(progress >= 0.0 || progress <= 1.0, '');

//   ///
//   final double progress;

//   ///
//   final double? height;

//   ///
//   final double? width;

//   ///
//   final EdgeInsetsGeometry? margin;

//   ///
//   final Color? trackColor;

//   ///
//   final List<Color>? progressColors;

//   ///
//   final Widget? child;

//   ///
//   final PaintingStyle? trackStyle;

//   ///
//   final double? progressRadius;

//   ///
//   final double? trackRadius;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
//       width: width,
//       height: height,
//       child: CustomPaint(
//         painter: _CustomProgressBarPainter(
//           progress: progress,
//           trackColor: trackColor,
//           progressColors: progressColors,
//           trackRadius: trackRadius,
//           progressRadius: progressRadius,
//           trackStyle: trackStyle,
//         ),
//         child: child,
//       ),
//     );
//   }
// }

// class _CustomProgressBarPainter extends CustomPainter {
//   _CustomProgressBarPainter({
//     this.progress,
//     this.progressColors,
//     this.trackColor,
//     this.trackRadius,
//     this.progressRadius,
//     this.trackStyle,
//   });

//   final double? progress;
//   final Color? trackColor;
//   final List<Color>? progressColors;
//   final PaintingStyle? trackStyle;
//   final double? progressRadius;
//   final double? trackRadius;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final trackPaint = Paint()
//       ..color = trackColor ?? Colors.grey.shade200
//       ..style = trackStyle ?? PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 2.0;

//     final progressPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = size.height;

//     if (progressColors?.isNotEmpty ?? false) {
//       if (progressColors!.length == 1) {
//         progressPaint.color = progressColors!.first;
//       } else {
//         final gradient = LinearGradient(
//           colors: progressColors!,
//           tileMode: TileMode.repeated,
//         );
//         final rect = Rect.fromCenter(
//           center: Offset(size.width * 0.5, size.height * 0.5),
//           width: size.width,
//           height: size.height,
//         );
//         progressPaint.shader = gradient.createShader(rect);
//       }
//     } else {
//       progressPaint.color = Colors.blue;
//     }

//     // final p1 = Offset(0.0, size.height);
//     // final p2 = Offset(size.width, size.height);
//     // final progressPoint = Offset(size.width * (progress ?? 0.0),
//     // size.height);

//     // canvas
//     //   ..drawLine(p1, p2, trackPaint)
//     //   ..drawLine(p1, progressPoint, progressPaint);

//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = Radius.circular(trackRadius ?? 8.0);

//     final trackRect =
//         Rect.fromCenter(center: center, width: size.width, height: size.height);
//     final trackRRect = RRect.fromRectAndRadius(trackRect, radius);

//     final progressRect =
//         Rect.fromLTWH(0.0, 0.0, size.width * progress!, size.height);

//     if (trackStyle == PaintingStyle.fill) {
//       canvas
//         ..clipRRect(trackRRect)
//         ..drawRRect(trackRRect, trackPaint)
//         ..drawRect(progressRect, progressPaint);
//     } else {
//       canvas
//         ..clipRRect(trackRRect)
//         ..drawRect(progressRect, progressPaint)
//         ..drawRRect(trackRRect, trackPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter widget) => true;
// }
