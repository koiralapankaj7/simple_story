import 'package:flutter/foundation.dart';

/// Intent behind user action.
///
/// [previous] => user want to access previous item
///
/// [next] => user want to access next item
enum ActionIntent { previous, next, none }

/// Story state
enum StoryState { none, played, skipped }

/// Story player state
enum StoryPlayerState { paused, playing, next, previous, completed, none }

/// Story list
class StoryList<T> {
  StoryList({
    required this.id,
    required this.stories,
    this.author,
    this.extra = const <String, dynamic>{},
    this.initialIndex = 0,
    this.completed = false,
  });

  /// String id to represent story collection
  final String id;

  ///
  final String? author;

  /// Collection of stories
  final List<Story<T>> stories;

  ///
  final Map<String, dynamic> extra;

  /// Initial index of the stories from where player will start playing
  int initialIndex;

  /// true, if user has  played all story
  bool completed;

  /// Copy object
  StoryList<T> copyWith({
    String? id,
    List<Story<T>>? stories,
    Map<String, dynamic>? extra,
    int? initialIndex,
    bool? completed,
  }) {
    return StoryList<T>(
      id: id ?? this.id,
      stories: stories ?? this.stories,
      extra: extra ?? this.extra,
      initialIndex: initialIndex ?? this.initialIndex,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() =>
      'StoryList(id: $id, stories: $stories), extra: $extra initialIndex: $initialIndex, hasUnplayedStory: $completed';
}

/// Vertical slide direction
enum SwipeDirection { up, down }

/// This is a representation of a story item (or page).
@immutable
class Story<T> {
  ///
  const Story({
    required this.id,
    this.detail,
    this.duration = const Duration(seconds: 5),
    this.state = StoryState.none,
    this.extra = const <String, dynamic>{},
  });

  /// Story id
  final String id;

  /// Generic object that can be used with [Story]
  final T? detail;

  /// Specifies how long the story should be displayed. It should be a
  /// reasonable amount of time greater than 1 seconds.
  final Duration duration;

  /// State of the story
  final StoryState state;

  /// Extra information
  final Map<String, dynamic> extra;

  Story<T> copyWith({
    String? id,
    T? detail,
    Duration? duration,
    StoryState? state,
    Map<String, dynamic>? extra,
  }) {
    return Story<T>(
      id: id ?? this.id,
      detail: detail ?? this.detail,
      duration: duration ?? this.duration,
      state: state ?? this.state,
      extra: extra ?? this.extra,
    );
  }

  @override
  String toString() {
    return 'Story(id: $id, detail: $detail, duration: $duration, played: $state, extra: $extra)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Story<T> &&
        other.id == id &&
        other.detail == detail &&
        other.duration == duration &&
        other.state == state &&
        mapEquals<String, dynamic>(other.extra, extra);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        detail.hashCode ^
        duration.hashCode ^
        state.hashCode ^
        extra.hashCode;
  }
}
