// import 'dart:math';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:simple_story/simple_story.dart';

// class StoryView extends StatefulWidget {
//   const StoryView({
//     required this.story,
//     required this.creator,
//     required this.controller,
//     super.key,
//   });

//   ///
//   final Story<String> story;

//   ///
//   final String creator;

//   ///
//   final StoryPlayerController<String> controller;

//   @override
//   State<StoryView> createState() => _StoryViewItemState();
// }

// class _StoryViewItemState extends State<StoryView> {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       fit: StackFit.expand,
//       alignment: Alignment.center,
//       children: [
//         // // Background
//         // Positioned.fill(
//         //   child: DecoratedBox(
//         //     decoration: BoxDecoration(
//         //       gradient: LinearGradient(
//         //         begin: Alignment.topLeft,
//         //         end: Alignment.bottomRight,
//         //         colors: _background.colors!,
//         //       ),
//         //     ),
//         //     child: const ColoredBox(color: Colors.black26),
//         //   ),
//         // ),

//         // Content
//         Positioned.fill(
//           child: CachedNetworkImage(imageUrl: widget.story.detail as String),
//         ),

//         // // Creator details
//         // Positioned(
//         //   top: 12,
//         //   left: 0.0,
//         //   right: 0.0,
//         //   child: UserTile(
//         //     user: widget.creator,
//         //     style: UserTileStyle(
//         //       imageSize: 38,
//         //       nameColor: Colors.white,
//         //       userNameColor: Colors.white54,
//         //       userImageHero: widget.creator.id,
//         //     ),
//         //     onPressed: widget.controller.pause,
//         //     onPop: widget.controller.play,
//         //   ),
//         // ),

//         //
//       ],
//     );
//   }
// }
