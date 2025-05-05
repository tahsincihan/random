import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a set of event IDs for which the user has already
/// accepted admitting early/late.
class EventCautionNotifier extends StateNotifier<Set<int>> {
  EventCautionNotifier() : super(<int>{});

  /// Call this when the user presses “Yes” on the early/late warning.
  void markCautioned(int eventId) {
    state = {...state, eventId};
  }

  /// Call this when the scannable window for an event has expired
  /// and you want to clear its “already cautioned” flag.
  void clearCautioned(int eventId) {
    state = {...state}..remove(eventId);
  }
}

final eventCautionProvider =
    StateNotifierProvider<EventCautionNotifier, Set<int>>((ref) {
  return EventCautionNotifier();
});
