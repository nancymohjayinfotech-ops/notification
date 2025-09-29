import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'event.dart';

/// A contract for local data sources that handle event data persistence.
///
/// This abstract class defines the interface for storing and retrieving
/// event data from local storage, typically using SharedPreferences.
abstract class EventLocalDataSource {

  /// Retrieves all events from the local cache.
  ///
  /// Returns a [Future] that completes with a list of [Event] objects.
  /// If no events are cached, returns an empty list.
  ///
  /// Throws an [Exception] if the operation fails.
  Future<List<Event>> getAllEvents();

  /// Retrieves a specific event by its ID.
  ///
  /// [id] The unique identifier of the event to retrieve.
  /// Returns a [Future] that completes with the [Event] if found, or `null` if not found.
  Future<Event?> getEventById(String id);

  /// Caches a list of events to local storage.
  ///
  /// [events] The list of events to cache.
  /// Throws an [Exception] if the operation fails.
  Future<void> cacheEvents(List<Event> events);

  /// Caches a single event to local storage.
  ///
  /// If an event with the same ID already exists, it will be updated.
  /// Otherwise, the event will be added to the cache.
  ///
  /// [event] The event to cache.
  /// Throws an [Exception] if the operation fails.
  Future<void> cacheEvent(Event event);

  /// Deletes an event from the local cache.
  ///
  /// [id] The ID of the event to delete.
  /// Throws an [Exception] if the operation fails.
  Future<void> deleteEvent(String id);

  /// Clears all cached event data.
  ///
  /// Throws an [Exception] if the operation fails.
  Future<void> clearCache();
}

/// A concrete implementation of [EventLocalDataSource] that uses SharedPreferences
/// for local data persistence.
///
/// This class handles the serialization and deserialization of events to/from JSON
/// and manages the SharedPreferences instance for storage.
class EventLocalDataSourceImpl implements EventLocalDataSource {
  /// The key used to store events in SharedPreferences.
  static const String _eventsKey = 'cached_events';
  
  /// The SharedPreferences instance used for data persistence.
  final SharedPreferences sharedPreferences;

  /// Creates a new [EventLocalDataSourceImpl] instance.
  ///
  /// [sharedPreferences] The SharedPreferences instance to use for storage.
  /// Must not be null.
  EventLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<Event>> getAllEvents() async {
    try {
      final jsonString = sharedPreferences.getString(_eventsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => Event.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get cached events: $e');
    }
  }

  @override
  Future<Event?> getEventById(String id) async {
    try {
      final events = await getAllEvents();
      return events.firstWhere(
        (event) => event.id == id,
        orElse: () => throw Exception('Event not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheEvents(List<Event> events) async {
    try {
      final jsonList = events.map((event) => event.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await sharedPreferences.setString(_eventsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache events: $e');
    }
  }

  @override
  Future<void> cacheEvent(Event event) async {
    try {
      final events = await getAllEvents();
      final existingIndex = events.indexWhere((e) => e.id == event.id);
      
      if (existingIndex != -1) {
        events[existingIndex] = event;
      } else {
        events.add(event);
      }
      
      await cacheEvents(events);
    } catch (e) {
      throw Exception('Failed to cache event: $e');
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      final events = await getAllEvents();
      events.removeWhere((event) => event.id == id);
      await cacheEvents(events);
    } catch (e) {
      throw Exception('Failed to delete cached event: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(_eventsKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }
}
