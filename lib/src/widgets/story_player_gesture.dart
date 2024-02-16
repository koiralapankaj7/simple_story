import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class DragDetails {
  const DragDetails({
    required this.extent,
    required this.progress,
    this.snapBack,
  });
  final double extent;
  final double progress;
  final VoidCallback? snapBack;

  static const DragDetails zero = DragDetails(extent: 0, progress: 0);
}

class StoryPlayerGesture extends StatefulWidget {
  const StoryPlayerGesture({
    super.key,
    this.onPause,
    this.onPlay,
    this.onNext,
    this.onPrevious,
    this.onSwipeUp,
    this.onDragDown,
    this.top,
    this.bottom,
    this.pauseDuration,
    this.snapDuration,
    this.behavior,
  });

  final VoidCallback? onPause;
  final VoidCallback? onPlay;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSwipeUp;
  final ValueChanged<DragDetails>? onDragDown;
  final HitTestBehavior? behavior;

  /// Amount of pixels that user need to drag from the top to
  /// trigger
  final double? top;

  /// Amount of pixels that user need to swipe/drag from the bottom to
  /// trigger [StoryPlayerGesture.onSwipeUp] callback.
  ///
  /// Default value is 60px
  final double? bottom;

  /// Duration used to calculate pause event. User need to hold the pointer for more
  /// than [pauseDuration] to pause the player. Default to 150 milliseconds
  final Duration? pauseDuration;

  ///
  final Duration? snapDuration;

  @override
  State<StoryPlayerGesture> createState() => _StoryPlayerGestureState();
}

class _StoryPlayerGestureState extends State<StoryPlayerGesture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: 1.0,
      duration: widget.snapDuration ?? const Duration(milliseconds: 350),
    )..addListener(_dragUpdate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late BoxConstraints _constraints;
  late final _widthThird = _constraints.maxWidth / 3;

  //  ====================== POINTER ======================

  var _downInitialDX = 0.0;
  var _downDuration = Duration.zero;
  var _isPaused = false;

  bool get _isLeft => _downInitialDX < _widthThird;
  bool get _isRight => _downInitialDX > _widthThird * 2;
  bool get _isCenter => !_isLeft && !_isRight;

  void _pause() {
    if (_isPaused) return;
    widget.onPause?.call();
    _isPaused = true;
  }

  void _togglePause() {
    _isPaused ? widget.onPlay?.call() : widget.onPause?.call();
    _isPaused = !_isPaused;
  }

  void _handleTap() {
    if (_isLeft) {
      widget.onPrevious?.call();
      return;
    }
    if (_isRight) {
      widget.onNext?.call();
      return;
    }

    _togglePause();
  }

  void _onPointerDown(PointerDownEvent event) {
    _downInitialDX = event.position.dx;
    _downDuration = event.timeStamp;
    widget.onPause?.call();
  }

  void _onPointerUp(PointerUpEvent event) {
    // Handle pause
    if ((event.timeStamp.inMilliseconds - _downDuration.inMilliseconds) >
        (widget.pauseDuration?.inMilliseconds ?? 150)) {
      _isCenter ? _pause() : widget.onPlay?.call();
      return;
    }
    // Handle tap
    _handleTap();
  }

  // ====================== DRAG ======================

  var _dragExtent = 0.0;

  void _dragUpdate() {
    final extent =
        (_dragExtent * _controller.value).clamp(0.0, _dragExtent.abs());
    final progress = (extent / (_constraints.maxHeight * 0.5)).clamp(0.0, 1.0);
    widget.onDragDown?.call(DragDetails(
      extent: extent,
      progress: progress,
      snapBack: _snapBack,
    ));
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragExtent = 0.0;
    _controller.value = 1.0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.primaryDelta!;
    if (_dragExtent > 0) _dragUpdate();
  }

  void _snapBack() {
    final Simulation simulation = SpringSimulation(
      SpringDescription.withDampingRatio(mass: 1, stiffness: 600, ratio: 1.1),
      1.0,
      0.0,
      0,
    );

    _controller.animateWith(simulation).then((_) {
      _dragExtent = 0.0;
      _controller.value = 1.0;
    });
    // // Animate back to the original position
    // _controller.animateBack(0.0, curve: Curves.bounceOut).then((_) {
    //   // Reset _dragExtent once the animation is complete
    //   setState(() {
    //     _dragExtent = 0.0;
    //     _controller.value = 1.0;
    //   });
    // });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragExtent > 0) {
      if (_dragExtent < (widget.top ?? 200)) {
        _snapBack();
        widget.onPlay?.call();
      }
    } else if (_dragExtent < -(widget.bottom ?? 60)) {
      widget.onSwipeUp?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (
      BuildContext context,
      BoxConstraints constraints,
    ) {
      _constraints = constraints;
      return Listener(
        behavior: widget.behavior ?? HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        child: widget.onSwipeUp == null && widget.onDragDown == null
            ? null
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
              ),
      );
    });
  }
}
