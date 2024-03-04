import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_story/simple_story.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  var prevCount = 0;
  final random = Random();
  final _widthController = TextEditingController();

  late final stories = List.generate(20, (parentIndex) {
    final parentId = 'Story-$parentIndex';
    final items = List.generate(random.nextInt(10) + 3, (index) {
      final imgId = prevCount + ((parentIndex + 1) * index);
      return StoryClip(
        extra: 'https://picsum.photos/id/$imgId/400/500',
        id: '$parentId-$index',
      );
    });
    prevCount += items.length;
    return Story(
      id: parentId,
      clips: items,
      author: 'https://i.pravatar.cc/150?img=${random.nextInt(50)}',
    );
  });

  late final _story = Story(
    id: 'StandaloneStory',
    clips: List.generate(random.nextInt(10) + 3, (index) {
      return StoryClip(
        extra: 'https://picsum.photos/id/${index + 20}/400/500',
        id: 'StandaloneStory-$index',
      );
    }),
  );

  final _alignments = [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.center,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight,
  ];

  Axis _barDirection = Axis.horizontal;
  HorizontalDirection _hbpDirection = HorizontalDirection.right;
  VerticalDirection _vbpDirection = VerticalDirection.up;
  Alignment _varAlignment = Alignment.topCenter;
  double? _barWidth;
  bool _loading = false;

  Widget _clipBuilder(
    BuildContext context,
    StoryClip clip,
    StoryPlayer player,
  ) {
    if (_loading) {
      return const Center(
        child: RepaintBoundary(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: clip.extra as String,
      fit: BoxFit.cover,
    );
  }

  Future<void> _loadClip(StoryClip clip) async {
    // To avoid setState during build
    await null;
    if (!context.mounted) return;
    setState(() => _loading = true);
    try {
      final imageProvider = CachedNetworkImageProvider(clip.extra as String);
      await precacheImage(imageProvider, context);
    } catch (e) {
      //
    } finally {
      setState(() => _loading = false);
    }
  }

  StoryDetails _storyBuilder(Story story, {StoryPlayer? player}) {
    return StoryDetails(
      player: player,
      clipBuilder: (context, clip, player) {
        return CachedNetworkImage(
          imageUrl: clip.extra as String,
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      scrollBehavior: const ScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
        scrollbars: false,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Simple Story')),
        // body: const _Gesture(),
        body: CustomScrollView(
          slivers: [
            // Stories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                // color: Colors.cyan,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length,
                  padding: const EdgeInsets.all(8),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = stories[index];
                    return AspectRatio(
                      aspectRatio: 1,
                      child: StoryCircle.decorated(
                        onPressed: (context) {
                          SimpleStory.open(
                            context,
                            stories: stories,
                            builder: _storyBuilder,
                          );
                        },
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(item.author!),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            //
            SliverToBoxAdapter(
              child: Container(
                height: 250,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 2,
                      blurRadius: 4,
                    ),
                  ],
                  // color: Theme.of(context).scaffoldBackgroundColor,
                  color: Colors.grey.shade900,
                ),
                clipBehavior: Clip.hardEdge,
                child: Builder(builder: (context) {
                  return StoryView(
                    story: _story,
                    storyLoader: (player) => _loadClip(player.currentClip),
                    gesture: StoryGesture(
                      onTapCenter: (result) {
                        SimpleStory.open(
                          context,
                          stories: [_story],
                          builder: (story) =>
                              _storyBuilder(story, player: result.$1),
                        );
                        return PlayerEventResult.handled;
                      },
                    ),
                    onComplete: (intent) {
                      return intent == ActionIntent.next
                          ? PlayerEventResult.handled
                          : PlayerEventResult.ignored;
                    },
                    progressBar: _barDirection == Axis.horizontal
                        ? StoryProgressBar(
                            alignment: _varAlignment,
                            progressDirection: _hbpDirection,
                            width: _barWidth,
                          )
                        : StoryProgressBar.vertical(
                            alignment: _varAlignment,
                            progressDirection: _vbpDirection,
                            height: _barWidth,
                          ),
                    clipBuilder: _clipBuilder,
                  );
                }),
              ),
            ),

            //
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Axis
                  _DropdownTile(
                    items: Axis.values,
                    initialValue: _barDirection,
                    title: 'Bar Direction',
                    onSelected: (item) {
                      setState(() {
                        _barDirection = item ?? Axis.horizontal;
                        if (_barDirection == Axis.vertical) {
                          _varAlignment = Alignment.centerRight;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  if (_barDirection == Axis.horizontal) ...[
                    _DropdownTile(
                      items: HorizontalDirection.values,
                      initialValue: _hbpDirection,
                      title: 'Progress Direction',
                      onSelected: (item) {
                        setState(() {
                          _hbpDirection = item ?? HorizontalDirection.right;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    _DropdownTile(
                      items: VerticalDirection.values,
                      initialValue: _vbpDirection,
                      title: 'Progress Direction',
                      onSelected: (item) {
                        setState(() {
                          _vbpDirection = item ?? VerticalDirection.down;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Alignment
                  _DropdownTile(
                    items: _alignments,
                    initialValue: _varAlignment,
                    title: 'Alignment',
                    onSelected: (item) {
                      setState(() {
                        _varAlignment = item ?? Alignment.topCenter;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // Bar extent
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _widthController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Bar width',
                              contentPadding: const EdgeInsets.only(left: 16),
                              constraints: BoxConstraints.tight(
                                const Size.fromHeight(40),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _barWidth =
                                  double.tryParse(_widthController.text);
                            });
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  const _DropdownTile({
    super.key,
    this.initialValue,
    required this.items,
    required this.title,
    required this.onSelected,
  });

  final T? initialValue;
  final Iterable<T> items;
  final String title;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          DropdownMenu<T>(
            initialSelection: initialValue,
            selectedTrailingIcon: Transform.translate(
              offset: const Offset(8, -4),
              child: const Icon(Icons.arrow_drop_up),
            ),
            trailingIcon: Transform.translate(
              offset: const Offset(8, -4),
              child: const Icon(Icons.arrow_drop_down),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.only(left: 16),
              constraints: BoxConstraints.tight(
                const Size.fromHeight(40),
              ),
            ),
            onSelected: onSelected,
            dropdownMenuEntries: items.map((e) {
              return DropdownMenuEntry(
                value: e,
                label: '$e',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// class _Gesture extends StatefulWidget {
//   const _Gesture();

//   @override
//   State<_Gesture> createState() => _GestureState();
// }

// class _GestureState extends State<_Gesture> {
//   final _dragDetails = ValueNotifier(DragDetails.zero);
//   String _message = 'Tap, LongPress or Swipe on the screen';

//   void _updateMessage(String message) {
//     // developer.log(message);
//     setState(() {
//       _message = message;
//     });
//   }

//   @override
//   void dispose() {
//     _dragDetails.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Positioned.fill(
//             child: Row(
//           mainAxisSize: MainAxisSize.max,
//           children: List.generate(
//             3,
//             (index) => Expanded(
//               child: SizedBox.expand(
//                 child: ColoredBox(
//                   color: const Color(0xffcccccc).withAlpha(
//                     100 * (index + 1),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         )),

//         //
//         Positioned.fill(
//           child: ValueListenableBuilder<DragDetails>(
//             valueListenable: _dragDetails,
//             builder: (context, details, child) {
//               return Transform.translate(
//                 offset: Offset(0, details.extent),
//                 child: Container(
//                   margin: EdgeInsets.symmetric(
//                     horizontal: 24 * details.progress,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.amber.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(
//                       24 * details.progress,
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       _message,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         fontSize: 24,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),

//         Positioned.fill(
//           // child: GestureDetectorPage(),
//           child: StoryGesture(
//             onPrevious: () {
//               _updateMessage('Previous');
//             },
//             onPause: () {
//               _updateMessage('Pause');
//             },
//             onPlay: () {
//               _updateMessage('Play');
//             },
//             onNext: () {
//               _updateMessage('Next');
//             },
//             onDragDown: (value) {
//               _dragDetails.value = value;
//             },
//             onSwipeUp: () {
//               _updateMessage('Swipe Up');
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class GestureDetectorPage extends StatefulWidget {
//   @override
//   _GestureDetectorPageState createState() => _GestureDetectorPageState();
// }

// class _GestureDetectorPageState extends State<GestureDetectorPage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       value: 1.0,
//       duration: const Duration(milliseconds: 350),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   String _message = 'Tap, LongPress or Swipe on the screen';
//   late BoxConstraints _constraints;

//   // =================
//   var _downInitialDX = 0.0;
//   var _downDuration = Duration.zero;

//   void _onPointerDown(PointerDownEvent event) {
//     _downInitialDX = event.position.dx;
//     _downDuration = event.timeStamp;
//     _updateMessage('Paused');
//   }

//   void _onPointerUp(PointerUpEvent event) {
//     // _updateMessage('Play');

//     final widthThird = _constraints.maxWidth / 3;
//     final holdDuration =
//         event.timeStamp.inMilliseconds - _downDuration.inMilliseconds;

//     if (holdDuration > 150) {
//       _updateMessage('Play');
//     } else {
//       if (_downInitialDX < widthThird) {
//         _updateMessage('Previous');
//       } else if (_downInitialDX > widthThird * 2) {
//         _updateMessage('Next');
//       } else {
//         _updateMessage('Pause');
//       }
//     }
//   }

//   // ======================

//   var _dragExtent = 0.0;

//   void _onVerticalDragStart(DragStartDetails details) {
//     _dragExtent = 0.0;
//     _controller.value = 1.0;
//   }

//   void _onVerticalDragUpdate(DragUpdateDetails details) {
//     _dragExtent += details.primaryDelta!;
//     if (_dragExtent > 0) setState(() {});
//   }

//   void _snapBack() {
//     final Simulation simulation = SpringSimulation(
//       SpringDescription.withDampingRatio(mass: 1, stiffness: 600, ratio: 1.1),
//       1.0,
//       0.0,
//       0,
//     );

//     _controller.animateWith(simulation).then((_) {
//       setState(() {
//         _dragExtent = 0.0;
//         _controller.value = 1.0;
//       });
//     });
//     // // Animate back to the original position
//     // _controller.animateBack(0.0, curve: Curves.bounceOut).then((_) {
//     //   // Reset _dragExtent once the animation is complete
//     //   setState(() {
//     //     _dragExtent = 0.0;
//     //     _controller.value = 1.0;
//     //   });
//     // });
//   }

//   void _onVerticalDragEnd(DragEndDetails details) {
//     if (_dragExtent > 0) {
//       if (_dragExtent < 200) {
//         _updateMessage('Snap Back');
//       } else {
//         _updateMessage('Close page');
//       }
//       _snapBack();
//     } else if (_dragExtent < -60) {
//       _updateMessage('Swipe up');
//     }
//   }

//   void _updateMessage(String message) {
//     developer.log(message);
//     setState(() {
//       _message = message;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (BuildContext context, BoxConstraints constraints) {
//         _constraints = constraints;
//         return Listener(
//           // behavior: HitTestBehavior.translucent,
//           onPointerDown: _onPointerDown,
//           onPointerUp: _onPointerUp,
//           child: GestureDetector(
//             onVerticalDragStart: _onVerticalDragStart,
//             onVerticalDragUpdate: _onVerticalDragUpdate,
//             onVerticalDragEnd: _onVerticalDragEnd,
//             behavior: HitTestBehavior.translucent,
//             child: AnimatedBuilder(
//               animation: _controller,
//               builder: (context, child) {
//                 final extent = (_dragExtent * _controller.value)
//                     .clamp(0.0, _dragExtent.abs());
//                 final progress = (extent / 400).clamp(0.0, 1.0);
//                 return Transform.translate(
//                   offset: Offset(0, extent),
//                   child: Container(
//                     margin: EdgeInsets.symmetric(horizontal: 24 * progress),
//                     decoration: BoxDecoration(
//                       color: Colors.amber.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(24 * progress),
//                     ),
//                     child: Center(
//                       child: Text(
//                         _message,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 24,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//         // return GestureDetector(
//         //   onTapDown: (TapDownDetails details) =>
//         //       _onTapDown(details, constraints),
//         //   // onLongPress: _onLongPress,
//         //   onLongPressStart: _onLongPressStart,
//         //   onLongPressEnd: _onLongPressEnd,
//         //   onVerticalDragUpdate: _onVerticalSwipe,
//         //   behavior: HitTestBehavior.opaque,
//         //   child: Center(
//         //     child: Text(
//         //       _message,
//         //       textAlign: TextAlign.center,
//         //       style: const TextStyle(
//         //         fontSize: 24,
//         //         color: Colors.black,
//         //       ),
//         //     ),
//         //   ),
//         // );
//       },
//     );
//   }
// }
