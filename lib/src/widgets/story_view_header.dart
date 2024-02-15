import 'package:flutter/material.dart';

import 'widgets.dart';

///
class StoryViewHeader extends StatefulWidget {
  const StoryViewHeader({
    required this.controller,
    this.alignment = Alignment.topCenter,
    this.height,
    super.key,
  });

  final double? height;
  final StoryPlayerController controller;
  final AlignmentGeometry alignment;

  @override
  State<StatefulWidget> createState() => _StoryViewHeaderState();
}

class _StoryViewHeaderState extends State<StoryViewHeader> {
  @override
  Widget build(BuildContext context) {
    final count = widget.controller.totalCount;
    final spacing = (count > 15) ? 1.0 : ((count > 10) ? 2.0 : 4.0);
    final height = widget.height?.abs() ?? 3.0;
    final controller = widget.controller;

    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: widget.alignment,
      child: Row(
        children: List.generate(
          count,
          (index) {
            return Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  right: index == count - 1 ? 0.0 : spacing,
                ),
                child: AnimatedBuilder(
                  animation: controller.animation,
                  builder: (context, child) {
                    // return const SizedBox();
                    if (index == controller.currentIndex) {
                      return CustomProgressbar(
                        height: height,
                        margin: EdgeInsets.zero,
                        trackStyle: PaintingStyle.fill,
                        progress: controller.animation.value,
                        trackRadius: height / 2,
                        progressRadius: height / 2,
                        progressColors: [Colors.white.withOpacity(0.8)],
                        trackColor: Colors.white.withOpacity(0.4),
                        // size: Size.fromHeight(height),
                        // foregroundPainter: _ProgressPainter(
                        //   color: Colors.white.withOpacity(0.8),
                        //   progress: index < value.itemIndex ? 1.0 : 0.0,
                        // ),
                        // painter: _ProgressPainter(
                        //   color: Colors.white.withOpacity(0.4),
                        // ),
                      );
                    }

                    return CustomProgressbar(
                      height: height,
                      margin: EdgeInsets.zero,
                      trackStyle: PaintingStyle.fill,
                      progress: index < controller.currentIndex ? 1.0 : 0.0,
                      trackRadius: height / 2,
                      progressRadius: height / 2,
                      progressColors: [Colors.white.withOpacity(0.8)],
                      trackColor: Colors.white.withOpacity(0.4),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

///
class CustomProgressbar extends StatelessWidget {
  ///
  const CustomProgressbar({
    required this.progress,
    super.key,
    this.height,
    this.width,
    this.margin,
    this.trackColor,
    this.progressColors,
    this.child,
    this.progressRadius,
    this.trackRadius,
    this.trackStyle,
  }) : assert(progress >= 0.0 || progress <= 1.0, '');

  ///
  final double progress;

  ///
  final double? height;

  ///
  final double? width;

  ///
  final EdgeInsetsGeometry? margin;

  ///
  final Color? trackColor;

  ///
  final List<Color>? progressColors;

  ///
  final Widget? child;

  ///
  final PaintingStyle? trackStyle;

  ///
  final double? progressRadius;

  ///
  final double? trackRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0),
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CustomProgressBarPainter(
          progress: progress,
          trackColor: trackColor,
          progressColors: progressColors,
          trackRadius: trackRadius,
          progressRadius: progressRadius,
          trackStyle: trackStyle,
        ),
        child: child,
      ),
    );
  }
}

class _CustomProgressBarPainter extends CustomPainter {
  _CustomProgressBarPainter({
    this.progress,
    this.progressColors,
    this.trackColor,
    this.trackRadius,
    this.progressRadius,
    this.trackStyle,
  });

  final double? progress;
  final Color? trackColor;
  final List<Color>? progressColors;
  final PaintingStyle? trackStyle;
  final double? progressRadius;
  final double? trackRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor ?? Colors.grey.shade200
      ..style = trackStyle ?? PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final progressPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.height;

    if (progressColors?.isNotEmpty ?? false) {
      if (progressColors!.length == 1) {
        progressPaint.color = progressColors!.first;
      } else {
        final gradient = LinearGradient(
          colors: progressColors!,
          tileMode: TileMode.repeated,
        );
        final rect = Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.5),
          width: size.width,
          height: size.height,
        );
        progressPaint.shader = gradient.createShader(rect);
      }
    } else {
      progressPaint.color = Colors.blue;
    }

    // final p1 = Offset(0.0, size.height);
    // final p2 = Offset(size.width, size.height);
    // final progressPoint = Offset(size.width * (progress ?? 0.0),
    // size.height);

    // canvas
    //   ..drawLine(p1, p2, trackPaint)
    //   ..drawLine(p1, progressPoint, progressPaint);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = Radius.circular(trackRadius ?? 8.0);

    final trackRect =
        Rect.fromCenter(center: center, width: size.width, height: size.height);
    final trackRRect = RRect.fromRectAndRadius(trackRect, radius);

    final progressRect =
        Rect.fromLTWH(0.0, 0.0, size.width * progress!, size.height);

    if (trackStyle == PaintingStyle.fill) {
      canvas
        ..clipRRect(trackRRect)
        ..drawRRect(trackRRect, trackPaint)
        ..drawRect(progressRect, progressPaint);
    } else {
      canvas
        ..clipRRect(trackRRect)
        ..drawRect(progressRect, progressPaint)
        ..drawRRect(trackRRect, trackPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter widget) => true;
}
