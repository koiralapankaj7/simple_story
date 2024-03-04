import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_utils/simple_utils.dart';

import 'entities/entities.dart';
import 'widgets/widgets.dart';

///
typedef StoryBuilder = StoryDetails Function(Story story);

double _degToRad(num deg) => deg * (math.pi / 180.0);

///
class StoryDetails {
  const StoryDetails({
    required this.clipBuilder,
    this.transitionBuilder,
    this.progressBar,
    this.player,
    this.onComplete,
    this.storyLoader,
    DraggableStoryGesture? gesture,
  }) : gesture = gesture ?? DraggableStoryGesture.none;

  /// Story clip/item builder
  final StoryClipBuilder clipBuilder;

  ///
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;

  ///
  final StoryProgressBar? progressBar;

  ///
  final StoryPlayer? player;

  ///
  final DraggableStoryGesture gesture;

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
}

/// ==================== StoryViewGesture ====================

///
class SimpleStory extends StatefulWidget {
  const SimpleStory({
    required this.stories,
    required this.builder,
    this.transitionBuilder,
    // this.gesture,
    this.controller,
    this.initialIndex = 0,
    this.autoPlay,
    this.animation,
    super.key,
  });

  final List<Story> stories;
  // final StoryClipBuilder clipBuilder;
  final SimpleStoryController? controller;
  final int initialIndex;
  final bool? autoPlay;
  final Animation<double>? animation;
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;
  // final ConfigGetter? gesture;
  final StoryBuilder builder;

  /// Open [SimpleStory]
  static Future<void> open(
    BuildContext context, {
    required List<Story> stories,
    required StoryBuilder builder,
    SimpleStoryController? controller,
    int initialIndex = 0,
    bool? autoPlay,
    Key? key,
  }) {
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      opaque: false,
      settings: const RouteSettings(name: 'storyGallery'),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return MatrixTransition(
          animation: animation,
          onTransform: (value) {
            return Matrix4.identity()..translate(0.0, 200 * (1 - value));
          },
          child: child,
        );
      },
      pageBuilder: (_, animation, secondaryAnimation) {
        return SimpleStory(
          key: key,
          stories: stories,
          builder: builder,
          initialIndex: initialIndex,
          controller: controller,
          animation: animation,
          autoPlay: autoPlay,
        );
      },
    );
    return Navigator.of(context).push(route);
  }

  @override
  State<SimpleStory> createState() => _SimpleStoryState();
}

class _SimpleStoryState extends State<SimpleStory>
    with SingleTickerProviderStateMixin {
  late final SimpleStoryController _controller;
  final _dragDetails = Value(DragDetails.zero);
  // late final _animationController = AnimationController(
  //   vsync: this,
  //   duration: kThemeAnimationDuration,
  // );

  // late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // _animation = widget.animation ??
    //     CurvedAnimation(
    //       parent: _animationController,
    //       curve: Curves.easeOut,
    //     );
    _controller = widget.controller ??
        SimpleStoryController(initialIndex: widget.initialIndex);
    _controller._init(items: widget.stories, context: context);
  }

  @override
  void dispose() {
    _dragDetails.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    // _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoryGalleryControllerProvider(
      controller: _controller,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: widget.animation != null
              ? Listenable.merge([_dragDetails, widget.animation])
              : _dragDetails,
          builder: (context, child) {
            final value = 1 - _dragDetails.value.progress;
            final margin = (80 * (1 - value)).clamp(0.0, 24.0);
            return ColoredBox(
              color: Colors.black.withOpacity(value),
              child: Transform.translate(
                offset: Offset(0.0, _dragDetails.value.extent),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(margin),
                    child: child,
                  ),
                ),
              ),
            );
            // final animValue = widget.animation?.value ?? 0.0;
            // final value =
            //     (animValue - _dragDetails.value.progress).clamp(0.0, 1.0);
            // return ColoredBox(
            //   color: Colors.black.withOpacity(value),
            //   child: Transform.translate(
            //     offset: Offset(0.0, _dragDetails.value.extent),
            //     // transform: Matrix4.identity()
            //     //   ..scale(
            //     //     widget.animation?.value,
            //     //     widget.animation?.value,
            //     //   ),
            //     // ..translate(0.0, _dragDetails.value.extent * animValue),
            //     child: Padding(
            //       padding: EdgeInsets.symmetric(horizontal: margin),
            //       child: ClipRRect(
            //         borderRadius: BorderRadius.circular(margin),
            //         child: child,
            //       ),
            //     ),
            //   ),
            // );
          },
          child: PageView.builder(
            controller: _controller.pageController,
            itemCount: widget.stories.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              final detail = widget.builder(story);

              return StoryPlayerTransform(
                index: index,
                controller: _controller,
                child: StoryView.draggable(
                  onPlayerInit: _controller._onPlayerInit,
                  onDisposed: _controller._onStoryDisposed,
                  story: story,
                  player: detail.player,
                  clipBuilder: detail.clipBuilder,
                  transitionBuilder: detail.transitionBuilder,
                  autoPlay: widget.autoPlay,
                  gesture: detail.gesture.copyWith(
                    onDragUpdate: (record) {
                      detail.gesture.onDragUpdate?.call(record);
                      _dragDetails.update(record.$2);
                    },
                    onDragDown: (clip) {
                      detail.gesture.onDragDown?.call(clip);
                      Navigator.of(context).pop();
                    },
                  ),
                  onComplete: (intent) {
                    final res = detail.onComplete?.call(intent);
                    if (res == PlayerEventResult.handled) return res!;
                    return _controller._handelIntent(intent);
                  },
                  storyLoader: (player) => true,
                  progressBar: null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ==================== StoryViewGesture ====================

///
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
  final SimpleStoryController controller;

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

/// ==================== StoryViewGesture ====================

///
/// [SimpleStory] controller
class SimpleStoryController extends ChangeNotifier {
  SimpleStoryController({int initialIndex = 0}) {
    pageController = PageController(initialPage: initialIndex)
      ..addListener(_pageListener);
    pageValueNotifier = ValueNotifier(
      PageValue(page: initialIndex.toDouble()),
    );
  }

  /// If pageView will be overScrolled by this pixel, [SimpleStory]
  /// will be closed.
  final _overScrollPX = 100.0;

  /// Check if controller has been initialized from [SimpleStory] or not
  bool _initialized = false;

  /// Gallery pageView controller
  late final PageController pageController;

  /// Page value notifier
  late final ValueNotifier<PageValue> pageValueNotifier;

  /// PageView default animation duration
  final _duration = const Duration(milliseconds: 500);

  /// PageView default curve
  final _curve = Curves.ease;

  /// [Story] collection
  List<Story> _items = [];

  ///
  StoryPlayer? _player;

  ///
  BuildContext? _context;

  void _init({
    required List<Story> items,
    required BuildContext context,
  }) {
    _items = items;
    _context = context;
    _initialized = true;
  }

  void _onPlayerInit(StoryPlayer player) {
    _player = player;
  }

  void _onStoryDisposed() {
    _player = null;
  }

  void _pageListener() {
    pageValueNotifier.value = pageValueNotifier.value.copyWith(
      page: pageController.page ?? 0.0,
      position: pageController.position,
      offset: pageController.offset,
    );

    final value = pageValueNotifier.value;

    if (value.page == value.index && !value.isOverScroll) {
      _player?.play();
    }

    if (value.isOverScroll && value.overScrollPercent(_overScrollPX) == 1.0) {
      _pop();
    }
  }

  PlayerEventResult _handelIntent(ActionIntent intent) {
    switch (intent) {
      case ActionIntent.next:
        nextItem();
      case ActionIntent.previous:
        previousItem();
      case ActionIntent.none:
    }
    return PlayerEventResult.handled;
  }

  bool _popped = false;

  ///
  void _pop() {
    if (_context != null && !_popped) {
      _popped = true;
      // pageController.position.hold(() {});
      Navigator.of(_context!).pop();
    }
  }

  ///
  void _changePage(int index) {
    pageController.animateToPage(index, duration: _duration, curve: _curve);
  }

  /// Move to next gallery item
  void nextItem() {
    if (!_initialized) return;
    if (isLastItem) {
      _pop();
      return;
    }
    _changePage(currentIndex + 1);
  }

  /// Move to previous gallery item
  void previousItem() {
    if (!_initialized) return;
    if (isFirstItem) {
      _pop();
      return;
    }
    _changePage(currentIndex - 1);
  }

  /// Current index of the gallery
  int get currentIndex => pageValueNotifier.value.page.truncate();

  /// true, if last item of the gallery
  bool get isLastItem => currentIndex == _items.length - 1;

  /// true, if first item of the gallery
  bool get isFirstItem => currentIndex == 0;

  ///
  StoryPlayer get currentPlayer {
    assert(_player != null, '');
    return _player!;
  }

  /// [Story] for current gallery item
  Story get currentStory => _items[currentIndex];

  ///
  StoryClip get currentClip {
    assert(_player != null, '');
    return _player!.currentClip;
  }

  @override
  void dispose() {
    pageController
      ..removeListener(_pageListener)
      ..dispose();
    super.dispose();
  }
}

/// [SimpleStoryController] provider
class StoryGalleryControllerProvider extends InheritedWidget {
  /// Creates a widget that associates a [StoryGalleryControllerProvider]
  /// with a subtree.
  const StoryGalleryControllerProvider({
    required SimpleStoryController this.controller,
    required super.child,
    super.key,
  });

  /// Creates a subtree without an associated [SimpleStoryController].
  const StoryGalleryControllerProvider.none({
    required super.child,
    super.key,
  }) : controller = null;

  /// The [StoryGalleryControllerProvider] associated with the subtree.
  ///
  final SimpleStoryController? controller;

  /// Returns the [StoryGalleryControllerProvider] most closely
  /// associated with the given context.
  ///
  /// Returns null if there is no [StoryGalleryControllerProvider]
  /// associated with the given context.
  static SimpleStoryController? of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<StoryGalleryControllerProvider>();
    return result?.controller;
  }

  @override
  bool updateShouldNotify(
    covariant StoryGalleryControllerProvider oldWidget,
  ) =>
      controller != oldWidget.controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<SimpleStoryController>(
        'controller',
        controller,
        ifNull: 'no controller',
        showName: false,
      ),
    );
  }
}

/// [StoryGalleryControllerProviderContextX] Extension
extension StoryGalleryControllerProviderContextX on BuildContext {
  /// [StoryGalleryControllerProvider] instance
  SimpleStoryController? get storyGalleryController =>
      StoryGalleryControllerProvider.of(this);
}

// onInit: (playerController) {
                    //   if (index == widget.initialIndex) {
                    //     Future<void>.delayed(
                    //       const Duration(milliseconds: 300),
                    //       () {
                    //         if (!mounted) return;
                    //         playerController.play();
                    //       },
                    //     );
                    //   }
                    //   _controller
                    //     .._context = context
                    //     .._playerController = playerController;
                    // },