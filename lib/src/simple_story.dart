import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'entities/entities.dart';
import 'widgets/widgets.dart';

///
class SimpleStory<T extends Object?> extends StatefulWidget {
  const SimpleStory({
    required this.items,
    required this.storyBuilder,
    super.key,
    this.storyFooterBuilder,
    this.controller,
    this.initialIndex = 0,
  });

  final List<StoryList<T>> items;
  final StoryBuilder<T> storyBuilder;
  final StoryBuilder<T>? storyFooterBuilder;
  final SSController<T>? controller;
  final int initialIndex;

  /// Open [SimpleStory]
  static Future<T?> open<T>(
    BuildContext context, {
    required List<StoryList<T>> items,
    required StoryBuilder<T> storyBuilder,
    Key? key,
    SSController<T>? controller,
    int initialIndex = 0,
  }) {
    final route = PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 600),
      opaque: false,
      settings: const RouteSettings(name: 'storyGallery'),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SimpleStory(
          key: key,
          items: items,
          storyBuilder: storyBuilder,
          initialIndex: initialIndex,
          controller: controller,
        );
      },
    );
    return Navigator.of(context).push(route);
  }

  @override
  State<SimpleStory<T>> createState() => _SimpleStoryState<T>();
}

class _SimpleStoryState<T> extends State<SimpleStory<T>> {
  late final SSController<T> _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? SSController<T>(initialIndex: widget.initialIndex);
    _controller._init(items: widget.items);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoryGalleryControllerProvider<T>(
      controller: _controller,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Builder(
          builder: (context) {
            return PageView.builder(
              controller: _controller.pageController,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final storyList = widget.items[index];
                return StoryPlayerTransform(
                  index: index,
                  controller: _controller,
                  child: StoryPlayer<T>(
                    storyList: storyList,
                    storyBuilder: widget.storyBuilder,
                    storyFooterBuilder: widget.storyFooterBuilder,
                    autoPlay: false,
                    onInit: (playerController) {
                      if (index == widget.initialIndex) {
                        Future<void>.delayed(
                          const Duration(milliseconds: 300),
                          () {
                            if (!mounted) return;
                            playerController.play();
                          },
                        );
                      }
                      _controller
                        .._context = context
                        .._playerController = playerController;
                    },
                    onComplete: (intent) {
                      switch (intent) {
                        case ActionIntent.next:
                          _controller.nextItem();
                        case ActionIntent.previous:
                          _controller.previousItem();
                        case ActionIntent.none:
                          return;
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

///
/// [SimpleStory] controller
class SSController<T> extends ChangeNotifier {
  SSController({int initialIndex = 0}) {
    pageController = PageController(initialPage: initialIndex)
      ..addListener(_pageListener);
    pageValueNotifier = ValueNotifier(
      PageValue(page: initialIndex.toDouble()),
    );
  }

  /// If pageview will be overscrolled by this pixel, [SimpleStory]
  /// will be closed.
  final _overScrollPX = 100.0;

  /// Check if controller has been initialized from [SimpleStory] or not
  bool _initialized = false;

  /// Gallery pageview controller
  late final PageController pageController;

  /// Page value notifier
  late final ValueNotifier<PageValue> pageValueNotifier;

  /// PageView default animation duration
  final _duration = const Duration(milliseconds: 500);

  /// PageView default curve
  final _curve = Curves.ease;

  /// [StoryList] collection
  List<StoryList<T>> _items = [];

  ///
  StoryPlayerController<T>? _playerController;

  ///
  late BuildContext? _context;

  void _init({required List<StoryList<T>> items}) {
    _items = items;

    _initialized = true;
  }

  void _pageListener() {
    pageValueNotifier.value = pageValueNotifier.value.copyWith(
      page: pageController.page ?? 0.0,
      position: pageController.position,
      offset: pageController.offset,
    );

    final value = pageValueNotifier.value;

    if (value.page == value.index && !value.isOverScroll) {
      _playerController?.play();
    }

    if (value.isOverScroll && value.overScrollPercent(_overScrollPX) == 1.0) {
      _pop();
    }
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

  @override
  void dispose() {
    pageController
      ..removeListener(_pageListener)
      ..dispose();
    super.dispose();
  }
}

/// [SSController] Extension
extension StoryGalleryControllerX<T> on SSController<T> {
  /// Current index of the gallery
  int get currentIndex => pageValueNotifier.value.page.truncate();

  /// true, if last item of the gallery
  bool get isLastItem => currentIndex == _items.length - 1;

  /// true, if first item of the gallery
  bool get isFirstItem => currentIndex == 0;

  /// [StoryList] for current gallery item
  StoryList<T> get currentStoryList => _items[currentIndex];
}

/// [SSController] provider
class StoryGalleryControllerProvider<T> extends InheritedWidget {
  /// Creates a widget that associates a [StoryGalleryControllerProvider<T>]
  /// with a subtree.
  const StoryGalleryControllerProvider({
    required SSController<T> this.controller,
    required super.child,
    super.key,
  });

  /// Creates a subtree without an associated [SSController].
  const StoryGalleryControllerProvider.none({
    required super.child,
    super.key,
  }) : controller = null;

  /// The [StoryGalleryControllerProvider] associated with the subtree.
  ///
  final SSController<T>? controller;

  /// Returns the [StoryGalleryControllerProvider<T>] most closely
  /// associated with the given context.
  ///
  /// Returns null if there is no [StoryGalleryControllerProvider<T>]
  /// associated with the given context.
  static SSController<T>? of<T>(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<
        StoryGalleryControllerProvider<T>>();
    return result?.controller;
  }

  @override
  bool updateShouldNotify(
    covariant StoryGalleryControllerProvider<T> oldWidget,
  ) =>
      controller != oldWidget.controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<SSController<T>>(
        'controller',
        controller,
        ifNull: 'no controller',
        showName: false,
      ),
    );
  }
}

/// [StoryGalleryControllerProviderContextX] Extension
extension StoryGalleryControllerProviderContextX<T> on BuildContext {
  /// [StoryGalleryControllerProvider<T>] instance
  SSController<T>? get storyGalleryController =>
      StoryGalleryControllerProvider.of<T>(this);
}
