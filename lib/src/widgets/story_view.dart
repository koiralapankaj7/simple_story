// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_utils/simple_utils.dart';

import '../entities/story.dart';
import 'story_player_gesture.dart';
import 'story_progress_bar.dart';

/// Story builder
typedef StoryClipBuilder<T> = Widget Function(
  BuildContext context,
  StoryClip<T> clip,
  StoryPlayer<T> player,
);

/// Story gesture callback
typedef StoryGestureCallback<T> = void Function(
  StoryClip<T> story,
  SwipeDirection direction,
);

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous/next page.
class StoryView<T extends Object?> extends StatefulWidget {
  const StoryView({
    required this.story,
    required this.builder,
    this.player,
    this.autoPlay = false,
    this.onComplete,
    this.progressBarAlignment = Alignment.topCenter,
    super.key,
  });

  /// Stories
  final Story<T> story;

  /// Story clip/item builder
  final StoryClipBuilder<T> builder;

  ///
  final StoryPlayer<T>? player;

  /// AutoPlay stories, default value is true
  final bool autoPlay;

  /// Callback for when a all stories is played or when going previous item
  /// from first index. Only [AxisDirection.left] and [AxisDirection.right] will
  /// be used.
  ///
  /// [ActionIntent.previous] means user is trying to browse previous item
  /// from first story.
  ///
  /// [ActionIntent.next] means user has played all stories ang trying to
  /// browse next story
  final PlayerEvent<T>? onComplete;

  /// Where the progress indicator should be placed.
  final Alignment progressBarAlignment;

  @override
  State<StoryView<T>> createState() => _StoryViewState<T>();
}

class _StoryViewState<T> extends State<StoryView<T>>
    with TickerProviderStateMixin {
  late StoryPlayer<T> _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player ?? StoryPlayer<T>();
    _init();
  }

  void _init() {
    _player
      .._init(
        vsync: this,
        story: widget.story,
        autoPlay: widget.autoPlay,
      )
      ..onComplete = widget.onComplete;
  }

  @override
  void didUpdateWidget(covariant StoryView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool needsInit = false;
    if (widget.player != oldWidget.player) {
      if (oldWidget.player == null) {
        _player.dispose();
      }
      _player = widget.player ?? StoryPlayer<T>();
      needsInit = true;
    }
    if (oldWidget.story != widget.story) {
      needsInit = true;
    }

    if (needsInit) {
      _init();
    }
  }

  @override
  void dispose() {
    widget.story
      ..completed = _player.isCompleted
      ..initialIndex = _player.currentIndex;
    if (widget.player == null) {
      _player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultStoryPlayer<T>(
      player: _player,
      child: _CardView(
        player: _player,
        clipBuilder: widget.builder,
        progressBarAlignment: widget.progressBarAlignment,
      ),
    );
  }
}

class _DefaultView<T> extends StatelessWidget {
  const _DefaultView({
    super.key,
    required this.player,
    required this.clipBuilder,
    required this.progressBarAlignment,
  });

  final StoryPlayer<T> player;
  final StoryClipBuilder<T> clipBuilder;
  final Alignment progressBarAlignment;

  @override
  Widget build(BuildContext context) {
    return DefaultStoryPlayer<T>(
      player: player,
      child: Stack(
        children: <Widget>[
          //
          Positioned.fill(
            child: ValueListenableBuilder<int>(
              valueListenable: player.indexNotifier,
              builder: (context, index, child) {
                return AnimatedSwitcher(
                  duration: kThemeChangeDuration,
                  switchInCurve: Curves.ease,
                  child: KeyedSubtree(
                    key: ValueKey(index),
                    child: clipBuilder(
                      context,
                      player.currentClip,
                      player,
                    ),
                  ),
                );
              },
            ),
          ),

          // Indicator
          Align(
            alignment: progressBarAlignment,
            child: StoryProgressBar(player: player),
          ),

          // Gesture controls
          Positioned.fill(
            child: StoryPlayerGesture(
              onPause: player.pause,
              onPlay: player.play,
              onNext: player.next,
              onPrevious: player.previous,
            ),
          ),

          // Footer controls
          Align(
            alignment: Alignment.bottomCenter,
            child: StoryPlayerControl(player: player),
          ),

          //
        ],
      ),
    );
  }
}

class _CardView<T> extends StatelessWidget {
  const _CardView({
    super.key,
    required this.player,
    required this.clipBuilder,
    required this.progressBarAlignment,
  });

  final StoryPlayer<T> player;
  final StoryClipBuilder<T> clipBuilder;
  final Alignment progressBarAlignment;

  @override
  Widget build(BuildContext context) {
    return DefaultStoryPlayer<T>(
      player: player,
      child: Stack(
        children: <Widget>[
          // Main Content
          Positioned.fill(
            child: ValueListenableBuilder<int>(
              valueListenable: player.indexNotifier,
              builder: (context, index, child) {
                return AnimatedSwitcher(
                  duration: kThemeChangeDuration,
                  switchInCurve: Curves.ease,
                  child: KeyedSubtree(
                    key: ValueKey(index),
                    child: clipBuilder(
                      context,
                      player.currentClip,
                      player,
                    ),
                  ),
                );
              },
            ),
          ),

          // Indicator
          Align(
            alignment: progressBarAlignment,
            child: StoryProgressBar(player: player),
          ),

          // Gesture controls
          Positioned.fill(
            child: StoryPlayerGesture(
              onPause: player.pause,
              onPlay: player.play,
              onNext: player.next,
              onPrevious: player.previous,
            ),
          ),

          //
        ],
      ),
    );
  }
}

/// A controller for managing the playback of story clips.
/// It handles story progression, play/pause functionality, and user interactions.
class StoryPlayer<T> extends BaseChangeNotifier {
  ///
  static StoryPlayer<T>? maybeOf<T>(BuildContext context) =>
      DefaultStoryPlayer.maybeOf<T>(context);

  ///
  static StoryPlayer<T> of<T>(BuildContext context) => maybeOf<T>(context)!;

  bool _initialized = false;
  late Story<T> _story;
  late ValueNotifier<int> _indexNotifier;
  late AnimationController _animationController;
  late Animation<double> _animation;

  StoryPlayerState _state = StoryPlayerState.none;

  /// Initializes the story controller with the specified story and animation settings.
  /// This method must be called before the controller is used.
  ///
  /// - [story]`: The story data to be played by the controller.
  /// - [vsync]`: The TickerProvider for the AnimationController.
  /// - [autoPlay]`: Determines if playback should start immediately after initialization.
  void _init({
    required Story<T> story,
    required TickerProvider vsync,
    bool autoPlay = true,
  }) {
    _story = story;
    _indexNotifier = ValueNotifier(story.initialIndex);
    _animationController = AnimationController(
      vsync: vsync,
      duration: _duration(story.initialIndex),
    )..addStatusListener(_animationStatusListener);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: story.curve ?? Curves.easeIn,
    );
    _initialized = true;
    if (autoPlay) play();
  }

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
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // void _animationListener() {
  //   if (_animationController.isAnimating && !isPlaying) {
  //     _state = StoryPlayerState.playing;
  //     notifyListeners();
  //     return;
  //   }

  //   if (_animationController.status == AnimationStatus.completed) {
  //     next();
  //     return;
  //   }
  // }

  ///
  // void ignoreGesture({required bool ignore}) {
  //   _ignoreGesture = ignore;
  //   notifyListeners();
  // }
  //

  /// Ensures the controller is initialized before executing the provided callback.
  /// Throws a StateError if the controller has not been initialized.
  R _guarded<R>(ValueGetter<R> cb) {
    if (!_initialized) {
      throw StateError(
        '${StoryPlayer<T>} has not been initialized yet. StoryPlayer should be attached to ${StoryView<T>} before accessing its property',
      );
    }
    return cb();
  }

  void _onComplete(ActionIntent intent) {
    final result = onComplete?.call(intent) ?? PlayerEventResult.ignored;
    if (result == PlayerEventResult.ignored) {
      jumpTo(0);
    } else {
      _updateState(StoryPlayerState.completed);
    }
  }

  /// Pauses the currently playing story clip. No-op if no clip is playing or
  /// if the controller is not initialized.
  void pause() => _guarded(() {
        _animationController.stop();
        _updateState(StoryPlayerState.paused);
      });

  /// Resumes playback of the current story clip or starts from the first clip
  /// if none are playing. Playback respects custom [Curve]s for animation if specified.
  void play() => _guarded(() {
        _animationController.forward();
        _updateState(StoryPlayerState.playing);
      });

  /// Advances to the next story clip in the sequence, automatically wrapping
  /// to the first clip if at the end. Triggers the onComplete callback with [ActionIntent.next]
  /// if there are no further clips to play.
  void next() => _guarded(() {
        if (isLastStory) {
          _onComplete(ActionIntent.next);
          return;
        }
        _updateState(StoryPlayerState.next);
        _animationController
          ..duration = _duration(_indexNotifier.value + 1)
          ..stop()
          ..reset()
          ..forward();
        _indexNotifier.value++;
      });

  /// Moves to the previous story clip, or triggers the onComplete callback with
  /// [ActionIntent.previous] if already at the first clip.
  void previous() => _guarded(() {
        if (isFirstStory) {
          _onComplete(ActionIntent.previous);
          return;
        }
        _updateState(StoryPlayerState.previous);
        _animationController
          ..duration = _duration(_indexNotifier.value - 1)
          ..stop()
          ..reset()
          ..forward();
        _indexNotifier.value--;
      });

  ///
  void jumpTo(int index) {
    if (index < 0 || index >= length) return;
    _animationController
      ..duration = _duration(index)
      ..stop()
      ..reset()
      ..forward();
    _indexNotifier.value = index;
  }

  ///
  PlayerEvent<T>? onComplete;

  ///
  bool get initialized => _initialized;

  ///
  Story<T> get story => _guarded(() => _story);

  /// Current [StoryClip] index
  int get currentIndex => _guarded(() => _indexNotifier.value);

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

  /// Total length of the stories
  int get length => _guarded(() => _story.clips.length);

  /// Current playing [StoryClip]
  StoryClip<T> get currentClip => _guarded(() => _story.clips[currentIndex]);

  /// Get [StoryClip] for provided index
  StoryClip<T> getClipFor(int index) => _guarded(() => _story.clips[index]);

  /// Current playing [StoryClip] index notifier
  ValueNotifier<int> get indexNotifier => _guarded(() => _indexNotifier);

  /// Animation
  Animation<double> get animation => _guarded(() => _animation);

  @override
  void dispose() {
    _animationController
      ..removeStatusListener(_animationStatusListener)
      ..dispose();
    _indexNotifier.dispose();
    super.dispose();
  }
}

///
class DefaultStoryPlayer<T> extends InheritedWidget {
  /// Creates a widget that associates a [StoryPlayer] with a subtree.
  const DefaultStoryPlayer({
    required this.player,
    required super.child,
    super.key,
  });

  /// The [StoryPlayer] associated with the subtree.
  ///
  final StoryPlayer<T> player;

  /// Returns the [StoryPlayer] most closely associated with the given
  /// context.
  ///
  /// Returns null if there is no [StoryPlayer] associated with the
  /// given context.
  static StoryPlayer<T>? maybeOf<T>(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<DefaultStoryPlayer<T>>();
    return result?.player;
  }

  /// Returns the [StoryPlayer] most closely associated with the given
  /// context.
  static StoryPlayer<T>? of<T>(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(
    covariant DefaultStoryPlayer<T> oldWidget,
  ) =>
      player != oldWidget.player;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<StoryPlayer<T>>(
        'controller',
        player,
        ifNull: 'no controller',
        showName: false,
      ),
    );
  }
}

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

///
extension DefaultStoryPlayerContextX<T> on BuildContext {
  /// [StoryPlayer] instance
  StoryPlayer<T>? get storyPlayer => DefaultStoryPlayer.maybeOf<T>(this);
}
