import 'package:flutter/material.dart';
import 'package:simple_utils/simple_utils.dart';

///
typedef PlayerEvent<T> = PlayerEventResult Function(ActionIntent intent);

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
class Story<T> {
  Story({
    required this.id,
    required this.clips,
    this.author,
    this.extra = const <String, dynamic>{},
    this.initialIndex = 0,
    this.completed = false,
    this.curve,
    this.duration,
  });

  /// String id to represent story collection
  final String id;

  ///
  final String? author;

  /// Clips inside the story
  final List<StoryClip<T>> clips;

  ///
  final Duration? duration;

  ///
  final Curve? curve;

  ///
  final Map<String, dynamic> extra;

  /// Initial index of the stories from where player will start playing
  int initialIndex;

  /// true, if user has  played all story
  bool completed;

  /// Copy object
  Story<T> copyWith({
    String? id,
    List<StoryClip<T>>? stories,
    Map<String, dynamic>? extra,
    int? initialIndex,
    bool? completed,
    Duration? duration,
    Curve? curve,
  }) {
    return Story<T>(
      id: id ?? this.id,
      clips: stories ?? this.clips,
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
class StoryClip<T> extends Equatable {
  ///
  const StoryClip({
    required this.id,
    this.detail,
    this.duration,
    this.state = StoryState.none,
    this.extra = const <String, dynamic>{},
  });

  /// Story id
  final String id;

  /// Generic object that can be used with [StoryClip]
  final T? detail;

  /// Specifies how long the story should be displayed. It should be a
  /// reasonable amount of time greater than 1 seconds. default to 5 second
  final Duration? duration;

  /// State of the story
  final StoryState state;

  /// Extra information
  final Map<String, dynamic> extra;

  ///
  StoryClip<T> copyWith({
    String? id,
    T? detail,
    Duration? duration,
    StoryState? state,
    Map<String, dynamic>? extra,
  }) {
    return StoryClip<T>(
      id: id ?? this.id,
      detail: detail ?? this.detail,
      duration: duration ?? this.duration,
      state: state ?? this.state,
      extra: extra ?? this.extra,
    );
  }

  @override
  List<Object?> get props => [
        id,
        detail,
        duration,
        state,
        extra,
      ];
}
