// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';

@immutable
class PageValue {
  const PageValue({
    this.page = 0.0,
    this.offset = 0.0,
    this.position,
  });

  final double page;
  final ScrollPosition? position;
  final double offset;

  PageValue copyWith({
    double? page,
    ScrollPosition? position,
    double? offset,
  }) {
    return PageValue(
      page: page ?? this.page,
      position: position ?? this.position,
      offset: offset ?? this.offset,
    );
  }

  @override
  String toString() =>
      'PageValue(page: $page, position: $position, offset: $offset)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PageValue &&
        other.page == page &&
        other.position == position &&
        other.offset == offset;
  }

  @override
  int get hashCode => page.hashCode ^ position.hashCode ^ offset.hashCode;
}

extension PageValueX on PageValue {
  /// Actual index of the page
  int get index => page.truncate();

  /// Max scroll extent
  double get maxExtent => position?.maxScrollExtent ?? 0.0;

  /// Min scroll extent
  double get minExtent => position?.minScrollExtent ?? 0.0;

  /// Right over scroll pixel
  double get rightOverScrollPX => offset - maxExtent;

  /// Left over scroll pixel
  double get leftOverScrollPX => offset.isNegative ? offset.abs() : 0.0;

  /// Over scroll pixel
  double get overScrollPX =>
      isLeftOverScroll ? leftOverScrollPX : rightOverScrollPX;

  /// true, if over scroll from left side
  bool get isLeftOverScroll => leftOverScrollPX > 0.0;

  /// true, if over scroll from right side
  bool get isRightOverScroll => rightOverScrollPX > 0.0;

  /// true, if scroll is over scroll
  bool get isOverScroll => isLeftOverScroll || isRightOverScroll;

  /// Over scroll percent based on provided [pixel]
  double overScrollPercent(double pixel) =>
      (overScrollPX / pixel).clamp(0.0, 1.0);
}
