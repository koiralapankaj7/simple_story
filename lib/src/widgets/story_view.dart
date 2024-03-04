// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:simple_utils/simple_utils.dart';

import '../entities/story.dart';
import 'story_progress_bar.dart';

/// Story builder
typedef StoryClipBuilder = Widget Function(
  BuildContext context,
  StoryClip clip,
  StoryPlayer player,
);

/// Story gesture callback
typedef StoryGestureCallback = void Function(
  StoryClip story,
  SwipeDirection direction,
);

///
typedef StoryEventResult<T> = (StoryPlayer player, T result);

///
typedef PointerResultSetter = PlayerEventResult Function(
  StoryEventResult<PointerUpResult> result,
);

///
typedef PlayerEvent = PlayerEventResult Function(ActionIntent intent);

///
typedef StoryLoader = FutureOr<void> Function(StoryPlayer player);

class DragDetails {
  const DragDetails({
    required this.extent,
    required this.progress,
    this.dragUpdateDetails,
    this.snapBack,
  });

  final double extent;
  final double progress;
  final DragUpdateDetails? dragUpdateDetails;
  final VoidCallback? snapBack;

  static const DragDetails zero = DragDetails(extent: 0, progress: 0);
}

class PointerUpResult {
  PointerUpResult({required this.event, required this.isLongPressed});
  final PointerUpEvent event;
  final bool isLongPressed;
}

///
class StoryGesture {
  const StoryGesture({
    this.onPointerDown,
    this.onTapLeft,
    this.onTapCenter,
    this.onTapRight,
    this.onPointerCancel,
  });

  ///
  static const StoryGesture none = StoryGesture();

  ///
  final ValueSetter<StoryEventResult<PointerDownEvent>>? onPointerDown;

  ///
  final PointerResultSetter? onTapLeft;

  ///
  final PointerResultSetter? onTapCenter;

  ///
  final PointerResultSetter? onTapRight;

  ///
  final ValueSetter<StoryEventResult<PointerCancelEvent>>? onPointerCancel;

  ///
  StoryGesture copyWith({
    ValueSetter<StoryEventResult<PointerDownEvent>>? onPointerDown,
    PointerResultSetter? onTapLeft,
    PointerResultSetter? onTapCenter,
    PointerResultSetter? onTapRight,
    ValueSetter<StoryEventResult<PointerCancelEvent>>? onPointerCancel,
  }) {
    return StoryGesture(
      onPointerDown: onPointerDown ?? this.onPointerDown,
      onTapLeft: onTapLeft ?? this.onTapLeft,
      onTapCenter: onTapCenter ?? this.onTapCenter,
      onTapRight: onTapRight ?? this.onTapRight,
      onPointerCancel: onPointerCancel ?? this.onPointerCancel,
    );
  }
}

///
class DraggableStoryGesture extends StoryGesture {
  const DraggableStoryGesture({
    super.onPointerDown,
    super.onTapLeft,
    super.onTapCenter,
    super.onTapRight,
    super.onPointerCancel,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.onDragDown,
    this.onSwipeUp,
    this.dragSnapThreshold,
    this.swipeThreshold,
    this.snapDuration,
    this.snapCurve,
  });

  ///
  static const DraggableStoryGesture none = DraggableStoryGesture();

  ///
  final ValueChanged<StoryEventResult<DragStartDetails>>? onDragStart;

  ///
  final ValueChanged<StoryEventResult<DragDetails>>? onDragUpdate;

  ///
  final ValueChanged<StoryEventResult<DragEndDetails>>? onDragEnd;

  ///
  final ValueChanged<StoryPlayer>? onDragCancel;

  ///
  final ValueChanged<StoryPlayer>? onDragDown;

  ///
  final ValueChanged<StoryPlayer>? onSwipeUp;

  /// Amount of pixels that user need to drag from the top to
  /// trigger
  ///
  /// Default value is 200px
  final double? dragSnapThreshold;

  /// Amount of pixels that user need to swipe/drag from the bottom to
  /// trigger [StoryViewGesture.onSwipeUp] callback.
  ///
  /// Default value is 60px
  final double? swipeThreshold;

  ///
  final Duration? snapDuration;

  ///
  final Curve? snapCurve;

  @override
  DraggableStoryGesture copyWith({
    ValueSetter<StoryEventResult<PointerDownEvent>>? onPointerDown,
    PointerResultSetter? onTapLeft,
    PointerResultSetter? onTapCenter,
    PointerResultSetter? onTapRight,
    ValueSetter<StoryEventResult<PointerCancelEvent>>? onPointerCancel,
    ValueChanged<StoryEventResult<DragStartDetails>>? onDragStart,
    ValueChanged<StoryEventResult<DragDetails>>? onDragUpdate,
    ValueChanged<StoryEventResult<DragEndDetails>>? onDragEnd,
    ValueChanged<StoryPlayer>? onDragCancel,
    ValueChanged<StoryPlayer>? onDragDown,
    ValueChanged<StoryPlayer>? onSwipeUp,
    double? dragSnapThreshold,
    double? swipeThreshold,
    Duration? snapDuration,
    Curve? snapCurve,
  }) {
    return DraggableStoryGesture(
      onPointerDown: onPointerDown ?? super.onPointerDown,
      onTapLeft: onTapLeft ?? super.onTapLeft,
      onTapCenter: onTapCenter ?? super.onTapCenter,
      onTapRight: onTapRight ?? super.onTapRight,
      onPointerCancel: onPointerCancel ?? super.onPointerCancel,
      onDragStart: onDragStart ?? this.onDragStart,
      onDragUpdate: onDragUpdate ?? this.onDragUpdate,
      onDragEnd: onDragEnd ?? this.onDragEnd,
      onDragCancel: onDragCancel ?? this.onDragCancel,
      onDragDown: onDragDown ?? this.onDragDown,
      onSwipeUp: onSwipeUp ?? this.onSwipeUp,
      dragSnapThreshold: dragSnapThreshold ?? this.dragSnapThreshold,
      swipeThreshold: swipeThreshold ?? this.swipeThreshold,
      snapDuration: snapDuration ?? this.snapDuration,
      snapCurve: snapCurve ?? this.snapCurve,
    );
  }
}

/// ==================== StoryView ====================

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous/next page.
class StoryView extends StatefulWidget {
  const StoryView({
    required this.story,
    required this.clipBuilder,
    this.transitionBuilder,
    this.progressBar,
    this.player,
    this.onComplete,
    this.storyLoader,
    this.onPlayerInit,
    this.onDisposed,
    bool? autoPlay,
    StoryGesture? gesture,
    super.key,
  })  : gesture = gesture ?? StoryGesture.none,
        autoPlay = autoPlay ?? true;

  ///
  const StoryView.draggable({
    required this.story,
    required this.clipBuilder,
    this.transitionBuilder,
    this.progressBar,
    this.player,
    this.onComplete,
    this.storyLoader,
    this.onPlayerInit,
    this.onDisposed,
    bool? autoPlay,
    DraggableStoryGesture? gesture,
    super.key,
  })  : gesture = gesture ?? DraggableStoryGesture.none,
        autoPlay = autoPlay ?? true;

  ///
  final Story story;

  /// Story clip/item builder
  final StoryClipBuilder clipBuilder;

  ///
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;

  ///
  final StoryProgressBar? progressBar;

  ///
  final StoryPlayer? player;

  /// AutoPlay stories, default value is true
  final bool autoPlay;

  ///
  final StoryGesture gesture;

  /// Callback for when a all stories is played or when going previous item
  /// from first index. Only [AxisDirection.left] and [AxisDirection.right] will
  /// be used.
  ///
  /// [ActionIntent.previous] means user is trying to browse previous item
  /// from first story.
  ///
  /// [ActionIntent.next] means user has played all stories ang trying to
  /// browse next story
  final PlayerEvent? onComplete;

  ///
  final StoryLoader? storyLoader;

  ///
  final ValueSetter<StoryPlayer>? onPlayerInit;

  ///
  final VoidCallback? onDisposed;

  @override
  State<StoryView> createState() => StoryViewState<StoryView>();
}

///
class StoryViewState<T extends StoryView> extends State<T>
    with SingleTickerProviderStateMixin {
  late StoryPlayer _player;

  ///
  StoryPlayer get player => _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player ?? StoryPlayer();
    _init();
    widget.onPlayerInit?.call(_player);
  }

  void _init() {
    _player
      .._init(
        vsync: this,
        story: widget.story,
        autoPlay: widget.autoPlay,
        storyLoader: widget.storyLoader,
      )
      .._onComplete = widget.onComplete;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsInit = false;
    if (widget.player != oldWidget.player) {
      if (oldWidget.player == null) {
        _player.dispose();
      }
      _player = widget.player ?? StoryPlayer();
      widget.onPlayerInit?.call(_player);
      needsInit = true;
    }
    if (needsInit ||
        widget.story != oldWidget.story ||
        widget.autoPlay != oldWidget.autoPlay) {
      _init();
    }
  }

  ///
  void onPointerDown(PointerDownEvent event) {
    _player._animationController.stop();
    widget.gesture.onPointerDown?.call((_player, event));
  }

  ///
  void onLeft(PointerUpResult result) {
    final res = widget.gesture.onTapLeft?.call((_player, result));
    if (res == PlayerEventResult.handled) return;
    result.isLongPressed ? _player.play() : _player.previous();
  }

  ///
  void onCenter(PointerUpResult result) {
    final res = widget.gesture.onTapCenter?.call((_player, result));
    if (res == PlayerEventResult.handled) return;
    result.isLongPressed ? _player.pause() : _player.toggle();
  }

  ///
  void onRight(PointerUpResult result) {
    final res = widget.gesture.onTapRight?.call((_player, result));
    if (res == PlayerEventResult.handled) return;
    result.isLongPressed ? _player.play() : _player.next();
  }

  ///
  void onPointerCancel(PointerCancelEvent event) {
    widget.gesture.onPointerCancel?.call((_player, event));
  }

  ///
  Widget buildProgressBar(BuildContext context) {
    return widget.progressBar ?? StoryProgressBar(player: _player);
  }

  ///
  Widget buildGesture(BuildContext context) {
    if (widget.gesture is DraggableStoryGesture) {
      final gesture = widget.gesture as DraggableStoryGesture;
      return StoryViewGesture.draggable(
        onPointerDown: onPointerDown,
        onTapLeft: onLeft,
        onTapCenter: onCenter,
        onTapRight: onRight,
        onPointerCancel: onPointerCancel,
        onVerticalDragStart: gesture.onDragStart == null
            ? null
            : (details) => gesture.onDragStart!((_player, details)),
        onDragUpdate: gesture.onDragUpdate == null
            ? null
            : (details) => gesture.onDragUpdate!((_player, details)),
        onVerticalDragEnd: gesture.onDragEnd == null
            ? null
            : (details) => gesture.onDragEnd!((_player, details)),
        onVerticalDragCancel: gesture.onDragCancel == null
            ? null
            : () => gesture.onDragCancel!(_player),
        onDragDown: gesture.onDragDown == null
            ? null
            : () => gesture.onDragDown!(_player),
        onSwipeUp: gesture.onSwipeUp == null
            ? null
            : () => gesture.onSwipeUp!(_player),
      );
    }

    return StoryViewGesture(
      onPointerDown: onPointerDown,
      onTapLeft: onLeft,
      onTapCenter: onCenter,
      onTapRight: onRight,
      onPointerCancel: onPointerCancel,
    );
  }

  ///
  Widget buildStory(BuildContext context) {
    return ListenableBuilder(
      listenable: _player.index,
      builder: (context, child) => buildClip(context, _player.currentClip),
    );
  }

  ///
  Widget buildClip(BuildContext context, StoryClip clip) {
    return AnimatedSwitcher(
      duration: kThemeChangeDuration,
      switchInCurve: Curves.ease,
      transitionBuilder:
          widget.transitionBuilder ?? AnimatedSwitcher.defaultTransitionBuilder,
      child: KeyedSubtree(
        key: ValueKey(_player.index),
        child: widget.clipBuilder(context, clip, _player),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.player == null) _player.dispose();
    widget.onDisposed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultStoryPlayer(
      player: _player,
      child: Stack(
        children: <Widget>[
          // Main Content
          Positioned.fill(child: buildStory(context)),

          // Indicator
          buildProgressBar(context),

          // Gesture controls
          Positioned.fill(child: buildGesture(context)),
        ],
      ),
    );
  }
}

/// ==================== StoryViewGesture ====================

///
class StoryViewGesture extends StatefulWidget {
  ///
  const StoryViewGesture({
    super.key,
    this.behavior,
    this.onPointerDown,
    this.onTapLeft,
    this.onTapCenter,
    this.onTapRight,
    this.onPointerCancel,
    this.pauseDuration,
    this.child,
  })  : onVerticalDragStart = null,
        onDragUpdate = null,
        onVerticalDragEnd = null,
        onVerticalDragCancel = null,
        onDragDown = null,
        onSwipeUp = null,
        dragSnapThreshold = null,
        swipeThreshold = null,
        snapDuration = null,
        snapCurve = null,
        _enableDrag = false;

  ///
  const StoryViewGesture.draggable({
    super.key,
    this.behavior,
    this.onPointerDown,
    this.onTapLeft,
    this.onTapCenter,
    this.onTapRight,
    this.onPointerCancel,
    this.onVerticalDragStart,
    this.onDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onDragDown,
    this.onSwipeUp,
    this.dragSnapThreshold,
    this.swipeThreshold,
    this.pauseDuration,
    this.snapDuration,
    this.snapCurve,
    this.child,
  }) : _enableDrag = true;

  ///
  final HitTestBehavior? behavior;

  ///
  final ValueSetter<PointerDownEvent>? onPointerDown;

  ///
  final ValueSetter<PointerUpResult>? onTapLeft;

  ///
  final ValueSetter<PointerUpResult>? onTapCenter;

  ///
  final ValueSetter<PointerUpResult>? onTapRight;

  ///
  final ValueSetter<PointerCancelEvent>? onPointerCancel;

  /// Duration used to calculate pause event. User need to hold the pointer for more
  /// than [pauseDuration] to pause the player. Default to 150 milliseconds
  final Duration? pauseDuration;

  ///
  final GestureDragStartCallback? onVerticalDragStart;

  ///
  final ValueChanged<DragDetails>? onDragUpdate;

  ///
  final GestureDragEndCallback? onVerticalDragEnd;

  ///
  final GestureDragCancelCallback? onVerticalDragCancel;

  ///
  final VoidCallback? onDragDown;

  ///
  final VoidCallback? onSwipeUp;

  /// Amount of pixels that user need to drag from the top to
  /// trigger
  ///
  /// Default value is 200px
  final double? dragSnapThreshold;

  /// Amount of pixels that user need to swipe/drag from the bottom to
  /// trigger [StoryViewGesture.onSwipeUp] callback.
  ///
  /// Default value is 60px
  final double? swipeThreshold;

  ///
  final Duration? snapDuration;

  ///
  final Curve? snapCurve;

  ///
  final Widget? child;

  final bool _enableDrag;

  @override
  State<StoryViewGesture> createState() => _StoryViewGestureState();
}

class _StoryViewGestureState extends State<StoryViewGesture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: 1.0,
      duration: widget.snapDuration ?? kThemeChangeDuration,
    )..addListener(_dragUpdate);
  }

  late BoxConstraints _constraints;
  late final _widthThird = _constraints.maxWidth / 3;

  //  ====================== POINTER ======================

  var _downInitialDX = 0.0;

  bool get _isLeft => _downInitialDX < _widthThird;
  bool get _isRight => _downInitialDX > _widthThird * 2;

  //
  Timer? _timer;
  var _longPressed = false;

  void _startTimer() {
    _timer = Timer(
      widget.pauseDuration ?? const Duration(milliseconds: 200),
      () => _longPressed = true,
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _downInitialDX = event.position.dx;
    _longPressed = false;
    _startTimer();
    widget.onPointerDown?.call(event);
  }

  void _onPointerUp(PointerUpEvent event) {
    _stopTimer();
    final result = PointerUpResult(event: event, isLongPressed: _longPressed);

    if (_isLeft) {
      widget.onTapLeft?.call(result);
      return;
    }

    if (_isRight) {
      widget.onTapRight?.call(result);
      return;
    }

    widget.onTapCenter?.call(result);
    _longPressed = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    widget.onPointerCancel?.call(event);
    _stopTimer();
  }

  // ====================== DRAG ======================

  var _dragExtent = 0.0;

  void _dragUpdate([DragUpdateDetails? details]) {
    final extent =
        (_dragExtent * _controller.value).clamp(0.0, _dragExtent.abs());
    final progress = (extent / _constraints.maxHeight).clamp(0.0, 1.0);
    widget.onDragUpdate?.call(DragDetails(
      extent: extent,
      progress: progress,
      dragUpdateDetails: details,
      snapBack: _snapBack,
    ));
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragExtent = 0.0;
    _controller.value = 1.0;
    widget.onVerticalDragStart?.call(details);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.primaryDelta!;
    if (_dragExtent > 0) _dragUpdate(details);
  }

  void _snapBack() {
    FutureOr<dynamic> onEnd(_) {
      _dragExtent = 0.0;
      _controller.value = 1.0;
    }

    if (widget.snapCurve == null) {
      final Simulation simulation = SpringSimulation(
        SpringDescription.withDampingRatio(mass: 1, stiffness: 600, ratio: 1.1),
        1.0,
        0.0,
        0,
      );
      _controller.animateWith(simulation).then(onEnd);
    } else {
      _controller
          .animateBack(
            0.0,
            duration: widget.snapDuration,
            curve: widget.snapCurve ?? Curves.easeOut,
          )
          .then(onEnd);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragExtent > 0) {
      if (_dragExtent < (widget.dragSnapThreshold ?? 200)) {
        _snapBack();
      } else {
        widget.onDragDown?.call();
      }
    } else if (_dragExtent < -(widget.swipeThreshold ?? 60)) {
      widget.onSwipeUp?.call();
    }
    widget.onVerticalDragEnd?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    final behavior = widget.behavior ?? HitTestBehavior.translucent;
    return LayoutBuilder(builder: (_, constraints) {
      _constraints = constraints;
      return Listener(
        behavior: behavior,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: widget._enableDrag
            ? GestureDetector(
                behavior: behavior,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                onVerticalDragCancel: widget.onVerticalDragCancel,
                child: widget.child,
              )
            : widget.child,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopTimer();
    super.dispose();
  }
}

/// ==================== StoryPlayer ====================

/// A controller for managing the playback of story clips.
/// It handles story progression, play/pause functionality, and user interactions.
class StoryPlayer extends BaseChangeNotifier {
  ///
  static StoryPlayer? maybeOf(BuildContext context) =>
      DefaultStoryPlayer.maybeOf(context);

  ///
  static StoryPlayer of(BuildContext context) => maybeOf(context)!;

  bool _initialized = false;
  late Story _story;
  late Value<int> _index;
  late AnimationController _animationController;
  late Animation<double> _animation;
  StoryLoader? _storyLoader;

  StoryPlayerState _prevState = StoryPlayerState.none;
  StoryPlayerState _state = StoryPlayerState.none;

  /// Initializes the story controller with the specified story and animation settings.
  /// This method must be called before the controller is used.
  ///
  /// - [story]`: The story data to be played by the controller.
  /// - [vsync]`: The TickerProvider for the AnimationController.
  /// - [autoPlay]`: Determines if playback should start immediately after initialization.
  void _init({
    required Story story,
    required TickerProvider vsync,
    required bool autoPlay,
    required StoryLoader? storyLoader,
  }) {
    _story = story;
    _storyLoader = storyLoader;
    if (!_initialized) {
      _index = Value(story.initialIndex);
      _animationController = AnimationController(
        vsync: vsync,
        duration: _duration(story.initialIndex),
      )..addStatusListener(_animationStatusListener);
      _animation = CurvedAnimation(
        parent: _animationController,
        curve: story.curve ?? Curves.easeIn,
      );
      _initialized = true;
    }
    if (autoPlay) play();
  }

  /// Callback that will be triggered when [story] is completed
  PlayerEvent? _onComplete;

  Duration _duration(int index) =>
      _story.clips[index].duration ??
      _story.duration ??
      const Duration(seconds: 5);

  void _animationStatusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        next();
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        _updateState(StoryPlayerState.playing);
        break;
      case AnimationStatus.dismissed:
        _updateState(StoryPlayerState.paused);
        break;
    }
  }

  /// Updates the story player's state and notifies listeners about the change.
  void _updateState(StoryPlayerState newState) {
    if (_state == newState) return;
    _prevState = _state;
    _state = newState;
    _story.initialIndex = currentIndex;
    notifyListeners();
  }

  /// Ensures the controller is initialized before executing the provided callback.
  /// Throws a StateError if the controller has not been initialized.
  R _guarded<R>(ValueGetter<R> cb) {
    if (!_initialized) {
      throw StateError(
        '$StoryPlayer has not been initialized yet. StoryPlayer should be attached to $StoryView before accessing its property',
      );
    }
    return cb();
  }

  void _complete(ActionIntent intent) {
    final result = _onComplete?.call(intent) ?? PlayerEventResult.ignored;
    if (result == PlayerEventResult.ignored) {
      jumpTo(0);
    } else {
      _animationController.value = 1.0;
      _updateState(StoryPlayerState.completed);
    }
    // widget.story
    //   ..completed = _player.isCompleted
    //   ..initialIndex = _player.currentIndex;
  }

  void _resetFor(int index) {
    _animationController
      ..duration = _duration(index)
      ..stop()
      ..reset();
    _index.value = index;
  }

  /// Toggle play and pause based on current [state]
  void toggle() => _state == StoryPlayerState.playing ? pause() : play();

  /// Pauses the currently playing story clip. No-op if no clip is playing or
  /// if the controller is not initialized.
  void pause() => _guarded(() {
        _animationController.stop();
        _updateState(StoryPlayerState.paused);
      });

  /// Resumes playback of the current story clip or starts from the first clip
  /// if none are playing. Playback respects custom [Curve]s for animation if specified.
  void play() => _guarded(() async {
        if (_storyLoader != null) {
          try {
            await _storyLoader!(this);
          } catch (_) {}
        }
        _animationController.forward();
        _updateState(StoryPlayerState.playing);
      });

  /// Advances to the next story clip in the sequence, automatically wrapping
  /// to the first clip if at the end. Triggers the onComplete callback with [ActionIntent.next]
  /// if there are no further clips to play.
  void next() => _guarded(() {
        if (isLastStory) {
          _complete(ActionIntent.next);
          return;
        }
        _updateState(StoryPlayerState.next);
        // _animationController
        //   ..duration = _duration(_index.value + 1)
        //   ..stop()
        //   ..reset();
        // _index.value++;
        _resetFor(_index.value + 1);
        play();
      });

  /// Moves to the previous story clip, or triggers the onComplete callback with
  /// [ActionIntent.previous] if already at the first clip.
  void previous() => _guarded(() {
        if (isFirstStory) {
          _complete(ActionIntent.previous);
          return;
        }
        _updateState(StoryPlayerState.previous);
        _resetFor(_index.value - 1);
        play();
        // _animationController
        //   ..duration = _duration(_index.value - 1)
        //   ..stop()
        //   ..reset()
        //   ..forward();
        // _index.value--;
      });

  /// Start playing clip for [index]
  void jumpTo(int index) {
    if (index < 0 || index >= length) return;
    // _animationController
    //   ..duration = _duration(index)
    //   ..stop()
    //   ..reset()
    //   ..forward();
    // _index.value = index;
    _resetFor(index);
    play();
  }

  ///
  bool get initialized => _initialized;

  ///
  Story get story => _guarded(() => _story);

  /// Current [StoryClip] index
  int get currentIndex => _guarded(() => _index.value);

  /// true, if currently playing [StoryClip] is last one
  bool get isLastStory =>
      _guarded(() => currentIndex == _story.clips.length - 1);

  /// true, if currently playing [StoryClip] is first one
  bool get isFirstStory => _guarded(() => currentIndex == 0);

  /// true, if [StoryClip] is currently playing
  bool get isPlaying => _state == StoryPlayerState.playing;

  /// true, if current [StoryClip] is paused
  bool get isPaused => _state == StoryPlayerState.paused;

  /// true, if all [StoryClip] has been played
  bool get isCompleted => _state == StoryPlayerState.completed;

  /// [StoryPlayer] current state. => [StoryPlayerState]
  StoryPlayerState get state => _state;

  /// [StoryPlayer] previous state. => [StoryPlayerState]
  StoryPlayerState get prevState => _prevState;

  /// Total length of the stories
  int get length => _guarded(() => _story.clips.length);

  /// Current playing [StoryClip]
  StoryClip get currentClip => _guarded(() => _story.clips[currentIndex]);

  /// Get [StoryClip] for provided index
  StoryClip getClipFor(int index) => _guarded(() => _story.clips[index]);

  /// Current playing [StoryClip] index notifier
  Value<int> get index => _guarded(() => _index);

  /// Animation
  Animation<double> get animation => _guarded(() => _animation);

  @override
  void dispose() {
    _animationController
      ..removeStatusListener(_animationStatusListener)
      ..dispose();
    _index.dispose();
    super.dispose();
  }
}

///
class DefaultStoryPlayer extends InheritedWidget {
  /// Creates a widget that associates a [StoryPlayer] with a subtree.
  const DefaultStoryPlayer({
    required this.player,
    required super.child,
    super.key,
  });

  /// The [StoryPlayer] associated with the subtree.
  ///
  final StoryPlayer player;

  /// Returns the [StoryPlayer] most closely associated with the given
  /// context.
  ///
  /// Returns null if there is no [StoryPlayer] associated with the
  /// given context.
  static StoryPlayer? maybeOf(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<DefaultStoryPlayer>();
    return result?.player;
  }

  /// Returns the [StoryPlayer] most closely associated with the given
  /// context.
  static StoryPlayer? of(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(
    covariant DefaultStoryPlayer oldWidget,
  ) =>
      player != oldWidget.player;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<StoryPlayer>(
        'controller',
        player,
        ifNull: 'no controller',
        showName: false,
      ),
    );
  }
}

/// ==================== StoryPlayerControl ====================

///
class StoryPlayerControl extends StatelessWidget {
  const StoryPlayerControl({
    required this.player,
    super.key,
  });

  ///
  final StoryPlayer player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 16.0),
          // Previous
          _Button(
            onPressed: player.previous,
            iconData: Icons.navigate_before,
            color: Colors.white12,
          ),

          const SizedBox(width: 8.0),

          // Next
          _Button(
            onPressed: player.next,
            iconData: Icons.navigate_next,
            color: Colors.white12,
          ),

          const SizedBox(width: 8.0),

          // Play/Pause
          AnimatedBuilder(
            animation: player,
            builder: (context, child) {
              return _Button(
                radius: 24.0,
                onPressed: player.isPlaying ? player.pause : player.play,
                iconData: player.isPlaying ? Icons.pause : Icons.play_arrow,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.onPressed,
    required this.iconData,
    this.radius = 20.0,
    this.color,
  });

  final VoidCallback onPressed;
  final IconData iconData;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(radius),
      child: CircleAvatar(
        backgroundColor: color,
        maxRadius: radius,
        child: Icon(iconData),
      ),
    );
  }
}

/// ==================== EXTENSIONS ====================

///
extension DefaultStoryPlayerContextX on BuildContext {
  /// [StoryPlayer] instance
  StoryPlayer? get storyPlayer => DefaultStoryPlayer.maybeOf(this);
}
