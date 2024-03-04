import 'package:flutter/material.dart';
import 'package:simple_utils/simple_utils.dart';

/// Intent behind user action.
///
/// [previous] => user want to access previous item
///
/// [next] => user want to access next item
enum ActionIntent { previous, next, none }

///
enum PlayerEventResult {
  ///
  handled,

  ///
  ignored,
}

/// Story state
enum StoryState { none, played, skipped }

/// Story player state
enum StoryPlayerState { paused, playing, next, previous, completed, none }

/// Story list
class Story {
  Story({
    required this.id,
    required this.clips,
    this.author,
    this.extra,
    this.initialIndex = 0,
    this.completed = false,
    this.curve,
    this.duration,
  });

  /// String id to represent story
  final String id;

  ///
  final String? author;

  /// Clips inside the story
  final List<StoryClip> clips;

  ///
  final Duration? duration;

  ///
  final Curve? curve;

  ///
  final Object? extra;

  /// Initial index of the stories from where player will start playing
  int initialIndex;

  /// true, if user has  played all story
  bool completed;

  /// Copy object
  Story copyWith({
    String? id,
    List<StoryClip>? clips,
    Object? extra,
    int? initialIndex,
    bool? completed,
    Duration? duration,
    Curve? curve,
  }) {
    return Story(
      id: id ?? this.id,
      clips: clips ?? this.clips,
      extra: extra ?? this.extra,
      initialIndex: initialIndex ?? this.initialIndex,
      completed: completed ?? this.completed,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
    );
  }

  @override
  String toString() =>
      'StoryList(id: $id, stories: $clips), extra: $extra initialIndex: $initialIndex, hasUnplayedStory: $completed';
}

/// Vertical slide direction
enum SwipeDirection { up, down }

/// This is a representation of a story item (or page).
@immutable
class StoryClip extends Equatable {
  ///
  const StoryClip({
    required this.id,
    this.duration,
    this.state = StoryState.none,
    this.extra = const <String, dynamic>{},
  });

  /// Story id
  final String id;

  /// Specifies how long the story should be displayed. It should be a
  /// reasonable amount of time greater than 1 seconds. default to 5 second
  final Duration? duration;

  /// State of the story
  final StoryState state;

  /// Extra information
  final Object extra;

  ///
  StoryClip copyWith({
    String? id,
    Duration? duration,
    StoryState? state,
    Map<String, dynamic>? extra,
  }) {
    return StoryClip(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      state: state ?? this.state,
      extra: extra ?? this.extra,
    );
  }

  @override
  List<Object?> get props => [
        id,
        duration,
        state,
        extra,
      ];
}
