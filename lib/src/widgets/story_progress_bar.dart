import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:simple_utils/simple_utils.dart';
import 'widgets.dart';

enum HorizontalDirection {
  left,
  right,
}

abstract class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar._({
    this.player,
    this.padding,
    this.space,
    required this.alignment,
    super.key,
  });

  ///
  const factory StoryProgressBar({
    StoryPlayer? player,
    EdgeInsetsGeometry? padding,
    double? space,
    double height,
    double? width,
    HorizontalDirection progressDirection,
    Alignment? alignment,
    Key? key,
  }) = HStoryProgressBar;

  ///
  const factory StoryProgressBar.vertical({
    StoryPlayer? player,
    EdgeInsetsGeometry? padding,
    double? space,
    double width,
    double? height,
    VerticalDirection progressDirection,
    Alignment? alignment,
    Key? key,
  }) = VStoryProgressBar;

  ///
  final StoryPlayer? player;

  ///
  final EdgeInsetsGeometry? padding;

  ///
  final double? space;

  ///
  final Alignment alignment;

  ///
  Widget buildBar(
    BuildContext context,
    BoxConstraints constraints,
    StoryPlayer player,
  );

  ///
  double gap(StoryPlayer player) =>
      space ??
      ((player.length > 15) ? 1.0 : ((player.length > 10) ? 2.0 : 4.0));

  ///
  double barExtent(double maxExtent, double? extent, StoryPlayer player) {
    final me =
        (maxExtent - ((player.length - 1) * gap(player))) / player.length;
    return (extent ?? 0) > 0 ? math.min(extent!, me) : me;
  }

  ///
  Widget buildItem(int index, double height, StoryPlayer player) {
    final progress = index == player.currentIndex
        ? player.animation.value
        : index < player.currentIndex
            ? 1.0
            : 0.0;
    return LinearProgressIndicator(
      value: progress,
      minHeight: height,
      backgroundColor: Colors.white.withOpacity(0.4),
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(height / 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPlayer = player ?? DefaultStoryPlayer.maybeOf(context);
    assert(defaultPlayer != null);
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: RepaintBoundary(
          child: LayoutBuilder(builder: (context, constraints) {
            return AnimatedBuilder(
              animation: defaultPlayer!.animation,
              builder: (context, child) =>
                  buildBar(context, constraints, defaultPlayer),
            );
          }),
        ),
      ),
    );
  }
}

///
class HStoryProgressBar extends StoryProgressBar {
  const HStoryProgressBar({
    super.player,
    super.padding,
    super.space,
    this.height = 3.0,
    this.width,
    this.progressDirection = HorizontalDirection.right,
    Alignment? alignment,
    super.key,
  }) : super._(alignment: alignment ?? Alignment.topCenter);

  final double height;
  final double? width;
  final HorizontalDirection progressDirection;

  @override
  Widget buildBar(context, constraints, player) {
    final right = progressDirection == HorizontalDirection.right;
    final children = List.generate(
      player.length,
      (index) {
        return SizedBox(
          width: barExtent(constraints.maxWidth, width, player),
          child: RotatedBox(
            quarterTurns: right ? 0 : 2,
            child: buildItem(index, height, player),
          ),
        );
      },
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          (right ? children : children.reversed).paddedX(space: gap(player)),
    );
  }
}

///
class VStoryProgressBar extends StoryProgressBar {
  const VStoryProgressBar({
    super.player,
    super.padding,
    super.space,
    this.width = 3.0,
    this.height,
    this.progressDirection = VerticalDirection.down,
    Alignment? alignment,
    super.key,
  }) : super._(alignment: alignment ?? Alignment.centerRight);

  final double width;
  final double? height;
  final VerticalDirection progressDirection;

  @override
  Widget buildBar(context, constraints, player) {
    final down = progressDirection == VerticalDirection.down;
    final children = List.generate(
      player.length,
      (index) {
        return SizedBox(
          height: barExtent(constraints.maxHeight, height, player),
          width: width,
          child: RotatedBox(
            quarterTurns: down ? 1 : -1,
            child: buildItem(index, width, player),
          ),
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          (down ? children : children.reversed).paddedY(space: gap(player)),
    );
  }
}
