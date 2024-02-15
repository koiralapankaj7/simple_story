// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../entities/story.dart';
import 'story_player_gesture.dart';
import 'story_view_header.dart';

/// Story builder
typedef StoryBuilder<T> = Widget Function(
  Story<T> story,
  StoryList<T> storyList,
  StoryPlayerController<T> controller,
);

/// Story gesture callback
typedef StoryGestureCallback<T> = void Function(
  Story<T> story,
  SwipeDirection direction,
);

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous/next page.
class StoryPlayer<T extends Object?> extends StatefulWidget {
  const StoryPlayer({
    required this.storyList,
    required this.storyBuilder,
    super.key,
    this.storyFooterBuilder,
    this.onInit,
    // this.onSwipe,
    this.onComplete,
    this.onDisposed,
    this.progressBarAlignment = Alignment.topCenter,
    this.autoPlay = true,
  });

  /// Stories
  final StoryList<T> storyList;

  /// Story item builder
  final StoryBuilder<T> storyBuilder;

  /// Story footer builder
  final StoryBuilder<T>? storyFooterBuilder;

  ///
  final ValueSetter<StoryPlayerController<T>>? onInit;

  // /// Callback for when a vertical swipe gesture is detected.
  // final StoryGestureCallback<T>? onSwipe;

  /// Callback for when a all stories is played or when going previous item
  /// from first index. Only [AxisDirection.left] and [AxisDirection.right] will
  /// be used.
  ///
  /// [ActionIntent.previous] means user is trying to browse previous item
  /// from first story.
  ///
  /// [ActionIntent.next] means user has played all stories ang trying to
  /// browse next story
  final ValueSetter<ActionIntent>? onComplete;

  /// Callback which will be triggered on [StoryPlayer] disposed
  final VoidCallback? onDisposed;

  /// Where the progress indicator should be placed.
  final AlignmentGeometry progressBarAlignment;

  /// AutoPlay stories, default value is true
  final bool autoPlay;

  @override
  State<StoryPlayer<T>> createState() => _StoryPlayerState<T>();
}

class _StoryPlayerState<T> extends State<StoryPlayer<T>>
    with TickerProviderStateMixin {
  late StoryPlayerController<T> _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // @override
  // void didUpdateWidget(covariant StoryPlayer<T> oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.storyList != widget.storyList ||
  //       oldWidget.storyFooterBuilder != widget.storyFooterBuilder ||
  //       oldWidget.storyBuilder != widget.storyBuilder) {
  //     _controller.dispose();
  //     _init();
  //   }
  // }

  void _init() {
    _controller = StoryPlayerController<T>();
    _controller._init(
      vsync: this,
      storyList: widget.storyList,
      onComplete: widget.onComplete,
      autoPlay: widget.autoPlay,
    );
    widget.onInit?.call(_controller);
  }

  @override
  void dispose() {
    widget.storyList
      ..completed = _controller.isCompleted
      ..initialIndex = _controller.isCompleted ? 0 : _controller.currentIndex;
    widget.onDisposed?.call();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return StoryPlayerControllerProvider<T>(
      controller: _controller,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black26,
            body: Column(
              children: [
                // Top padding space
                SizedBox(height: padding.top),

                // Content body
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: Stack(
                      children: <Widget>[
                        // Story items
                        // Positioned.fill(
                        //   child: PageTransitionSwitcher(
                        //     transitionBuilder: (
                        //       Widget child,
                        //       Animation<double> animation,
                        //       Animation<double> secondaryAnimation,
                        //     ) {
                        //       return FadeThroughTransition(
                        //         animation: animation,
                        //         secondaryAnimation: secondaryAnimation,
                        //         child: child,
                        //       );
                        //     },
                        //     child: ValueListenableBuilder<int>(
                        //       valueListenable: _controller.indexNotifier,
                        //       builder: (context, index, child) {
                        //         return widget.storyBuilder(
                        //           _controller.currentItem,
                        //           widget.storyList,
                        //           _controller,
                        //         );
                        //       },
                        //     ),
                        //   ),
                        // ),
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: kThemeChangeDuration,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _controller.indexNotifier,
                              builder: (context, index, child) {
                                return widget.storyBuilder(
                                  _controller.currentItem,
                                  widget.storyList,
                                  _controller,
                                );
                              },
                            ),
                          ),
                        ),

                        // Indicator
                        StoryViewHeader(
                          controller: _controller,
                          alignment: widget.progressBarAlignment,
                        ),

                        // Gesture controls
                        Positioned.fill(
                          child: StoryPlayerGesture(
                            onPause: _controller.pause,
                            onPlay: _controller.play,
                            onNext: _controller.next,
                            onPrevious: _controller.previous,
                            onSwipeUp: () {
                              // widget.onSwipe?.call(
                              //   _controller.currentItem,
                              //   direction,
                              // );
                            },
                          ),
                        ),

                        //
                      ],
                    ),
                  ),
                ),

                // Footer controls
                Align(
                  alignment: Alignment.bottomCenter,
                  child: StoryViewControls(
                    controller: _controller,
                    onPause: _controller.pause,
                    onPlay: _controller.play,
                    onNext: _controller.next,
                    onPrevious: _controller.previous,
                  ),
                ),

                // Bottom padding space
                SizedBox(height: padding.bottom),
                //
              ],
            ),
          );
        },
      ),
    );
  }
}

//
///
class StoryPlayerController<T> extends ChangeNotifier {
  bool _initialized = false;
  late StoryList<T> _storyList;
  late ValueNotifier<int> _indexNotifier;
  late AnimationController _animationController;
  StoryPlayerState _state = StoryPlayerState.none;
  ValueSetter<ActionIntent>? _onComplete;
  // bool _ignoreGesture = false;

  //
  void _init({
    required StoryList<T> storyList,
    required TickerProvider vsync,
    bool autoPlay = true,
    ValueSetter<ActionIntent>? onComplete,
  }) {
    if (_initialized) return;
    _storyList = storyList;
    _indexNotifier = ValueNotifier(storyList.initialIndex);
    _animationController = AnimationController(vsync: vsync)
      ..duration = storyList.stories[storyList.initialIndex].duration
      ..addListener(_animationListener);
    _onComplete = onComplete;
    _initialized = true;
    // if (autoPlay) {
    //   _animationController.forward();
    // }
  }

  void _animationListener() {
    // if (_animationController.isAnimating && !isPlaying) {
    //   _state = StoryPlayerState.playing;
    //   notifyListeners();
    //   return;
    // }

    // if (_animationController.status == AnimationStatus.completed) {
    //   next();
    //   return;
    // }
  }

  ///
  // void ignoreGesture({required bool ignore}) {
  //   _ignoreGesture = ignore;
  //   notifyListeners();
  // }

  /// Pause
  void pause() {
    if (!_initialized) return;
    _animationController.stop();
    _state = StoryPlayerState.paused;
    notifyListeners();
  }

  /// play
  void play() {
    if (!_initialized) return;
    _animationController.forward();
    _state = StoryPlayerState.playing;
    notifyListeners();
  }

  /// Next
  void next() {
    if (!_initialized) return;

    if (isLastStory) {
      _onComplete?.call(ActionIntent.next);
      _state = StoryPlayerState.completed;
      notifyListeners();
      return;
    }

    _animationController
      ..duration = currentItem.duration
      ..stop()
      ..reset()
      ..forward();
    _state = StoryPlayerState.next;
    _indexNotifier.value++;
    notifyListeners();
  }

  /// Previous
  void previous() {
    if (!_initialized) return;

    if (isFirstStory) {
      _onComplete?.call(ActionIntent.previous);
      notifyListeners();
      return;
    }
    _animationController
      ..duration = currentItem.duration
      ..stop()
      ..reset()
      ..forward();
    _state = StoryPlayerState.previous;
    _indexNotifier.value--;
    notifyListeners();
  }

  @override
  void dispose() {
    _animationController
      ..removeListener(_animationListener)
      ..dispose();
    _indexNotifier.dispose();
    super.dispose();
  }
}

extension StoryPlayerControllerX<T> on StoryPlayerController<T> {
  /// Current [Story] index
  int get currentIndex => _indexNotifier.value;

  /// true, if currently playing [Story] is last one
  bool get isLastStory => currentIndex == _storyList.stories.length - 1;

  /// true, if currently playing [Story] is first one
  bool get isFirstStory => currentIndex == 0;

  /// true, if [Story] is currently playing
  bool get isPlaying => _state == StoryPlayerState.playing;

  /// true, if current [Story] is paused
  bool get isPaused => _state == StoryPlayerState.paused;

  /// true, if all [Story] has been played
  bool get isCompleted => _state == StoryPlayerState.completed;

  /// [StoryPlayerController] current state. => [StoryPlayerState]
  StoryPlayerState get state => _state;

  /// Total length of the stories
  int get totalCount => _storyList.stories.length;

  /// Current playing [Story]
  Story<T> get currentItem => _storyList.stories[currentIndex];

  /// Get [Story] for provided index
  Story<T> getStoryForIndex(int index) => _storyList.stories[index];

  /// Current playing [Story] index notifier
  ValueNotifier<int> get indexNotifier => _indexNotifier;

  /// Animation controller
  AnimationController get animation => _animationController;
}

///
class StoryPlayerControllerProvider<T> extends InheritedWidget {
  /// Creates a widget that associates a [StoryPlayerController] with a subtree.
  const StoryPlayerControllerProvider({
    required StoryPlayerController<T> this.controller,
    required super.child,
    super.key,
  });

  /// Creates a subtree without an associated [StoryPlayerController].
  const StoryPlayerControllerProvider.none({
    required super.child,
    super.key,
  }) : controller = null;

  /// The [StoryPlayerController] associated with the subtree.
  ///
  final StoryPlayerController<T>? controller;

  /// Returns the [StoryPlayerController] most closely associated with the given
  /// context.
  ///
  /// Returns null if there is no [StoryPlayerController] associated with the
  /// given context.
  static StoryPlayerController<T>? of<T>(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<StoryPlayerControllerProvider<T>>();
    return result?.controller;
  }

  @override
  bool updateShouldNotify(
    covariant StoryPlayerControllerProvider<T> oldWidget,
  ) =>
      controller != oldWidget.controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<StoryPlayerController<T>>(
        'controller',
        controller,
        ifNull: 'no controller',
        showName: false,
      ),
    );
  }
}

///
extension StoryPlayerControllerProviderContextX<T> on BuildContext {
  /// [StoryPlayerController] instance
  StoryPlayerController<T>? get storyPlayerController =>
      StoryPlayerControllerProvider.of<T>(this);
}
