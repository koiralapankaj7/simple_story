// ignore_for_file: strict_raw_type

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../entities/entities.dart';
import '../simple_story.dart';

double _degToRad(num deg) => deg * (pi / 180.0);

class StoryPlayerTransform extends StatelessWidget {
  const StoryPlayerTransform({
    required this.index, // required this.pageValue,
    required this.child,
    required this.controller,
    super.key,
  });

  ///
  final int index;

  /// final double pageValue;
  final Widget child;

  ///
  final SSController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PageValue>(
      valueListenable: controller.pageValueNotifier,
      builder: (context, pageValue, ch) {
        final overscrollPercent =
            pageValue.overScrollPercent(MediaQuery.of(context).size.width);
        final pagePercent = index - pageValue.page;

        final isLeaving = pagePercent.isNegative || pageValue.isRightOverScroll;
        final t = pageValue.isOverScroll
            ? overscrollPercent * (pageValue.isRightOverScroll ? -1 : 1)
            : pagePercent;
        final rotationY = lerpDouble(0, 90, t)!;
        final opacity = lerpDouble(0, 1, t.abs())!.clamp(0.0, 1.0);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(-_degToRad(rotationY));

        return Transform(
          alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
          // transform: isLeaving ? Matrix4.identity() : transform,
          transform: transform,
          child: Stack(
            children: [
              ch!,
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}
