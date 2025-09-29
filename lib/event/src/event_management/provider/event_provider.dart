import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../event.dart';
import '../event_repository.dart';

/// A provider class that manages the state and business logic for events in the application.
/// 
/// This class handles loading, filtering, and managing events, and notifies listeners
/// when the state changes. It works with an [EventRepository] to persist and retrieve event data.
///
/// Example usage:
/// ```dart
/// final eventProvider = EventProvider(
///   eventRepository: eventRepository,
/// );
/// ```
class EventProvider with ChangeNotifier {
  /// The repository used to fetch and persist event data.
  final EventRepository _eventRepository;

  /// Creates a new [EventProvider] with the given [eventRepository].
  ///
  /// The [eventRepository] parameter must not be null.
  EventProvider({required EventRepository eventRepository})
      : _eventRepository = eventRepository;

  // State variables
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  String? _errorMessage;
  EventCategory? _selectedCategory;
  String _searchQuery = '';
  DateTime? _filterStart;
  DateTime? _filterEnd;

  // Getters
  
  /// The complete list of all events.
  List<Event> get events => _events;
  
  /// The list of events after applying any active filters or search queries.
  List<Event> get filteredEvents => _filteredEvents;
  
  /// The currently selected event, if any.
  Event? get selectedEvent => _selectedEvent;
  
  /// Whether the provider is currently loading data.
  bool get isLoading => _isLoading;
  
  /// The current error message, if any error occurred during the last operation.
  String? get errorMessage => _errorMessage;
  
  /// The currently selected event category filter, if any.
  EventCategory? get selectedCategory => _selectedCategory;
  
  /// The current search query string.
  String get searchQuery => _searchQuery;
  DateTime? get filterStart => _filterStart;
  DateTime? get filterEnd => _filterEnd;

  // Load all events
  Future<void> loadAllEvents() async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getAllEvents();
    result.fold(
      (error) => _setError(error),
      (events) {
        _events = events;
        _applyFilters();
      },
    );

    _setLoading(false);
  }

  // Load event by ID
  Future<void> loadEventById(String id) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getEventById(id);
    result.fold(
      (error) => _setError(error),
      (event) => _selectedEvent = event,
    );

    _setLoading(false);
  }

  // Get event by ID (returns Either for better error handling)
  Future<Either<String, Event>> getEventById(String id) async {
    return await _eventRepository.getEventById(id);
  }

  // Load event by slug
  Future<Event?> loadEventBySlug(String slug) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getEventBySlug(slug);
    Event? event;
    
    result.fold(
      (error) => _setError(error),
      (loadedEvent) {
        event = loadedEvent;
        _selectedEvent = loadedEvent;
      },
    );

    _setLoading(false);
    return event;
  }

  // Create new event
  Future<bool> createEvent(Event event) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.createEvent(event);
    bool success = false;

    result.fold(
      (error) => _setError(error),
      (newEvent) {
        _events.add(newEvent);
        _applyFilters();
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  // Update existing event
  Future<bool> updateEvent(Event event) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.updateEvent(event);
    bool success = false;

    result.fold(
      (error) => _setError(error),
      (updatedEvent) {
        final index = _events.indexWhere((e) => e.id == updatedEvent.id);
        if (index != -1) {
          _events[index] = updatedEvent;
          _applyFilters();
          success = true;
        }
      },
    );

    _setLoading(false);
    return success;
  }

  // Delete event
  Future<bool> deleteEvent(String id) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.deleteEvent(id);
    bool success = false;

    result.fold(
      (error) => _setError(error),
      (deleted) {
        if (deleted) {
          _events.removeWhere((event) => event.id == id);
          _applyFilters();
          success = true;
        }
      },
    );

    _setLoading(false);
    return success;
  }

  // Search events
  void searchEvents(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by date range
  void setDateRange({DateTime? start, DateTime? end}) {
    _filterStart = start;
    _filterEnd = end;
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(EventCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Get upcoming events
  Future<void> loadUpcomingEvents() async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getUpcomingEvents();
    result.fold(
      (error) => _setError(error),
      (events) {
        _events = events;
        _filteredEvents = events;
      },
    );

    _setLoading(false);
  }

  // Get events by date range
  Future<void> loadEventsByDateRange(DateTime start, DateTime end) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getEventsByDateRange(start, end);
    result.fold(
      (error) => _setError(error),
      (events) {
        _events = events;
        _filteredEvents = events;
      },
    );

    _setLoading(false);
  }

  // Upload event resource
  Future<bool> uploadEventResource(String eventId, String filePath) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.uploadEventResource(eventId, filePath);
    bool success = false;

    result.fold(
      (error) => _setError(error),
      (resourceUrl) {
        // Update the local event with the new resource
        final eventIndex = _events.indexWhere((e) => e.id == eventId);
        if (eventIndex != -1) {
          final updatedEvent = _events[eventIndex].copyWith(
            resources: [..._events[eventIndex].resources, resourceUrl],
          );
          _events[eventIndex] = updatedEvent;
          _applyFilters();
        }
        success = true;
      },
    );

    _setLoading(false);
    return success;
  }

  // Remove event resource
  Future<bool> removeEventResource(String eventId, String resourceUrl) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.removeEventResource(eventId, resourceUrl);
    bool success = false;

    result.fold(
      (error) => _setError(error),
      (removed) {
        if (removed) {
          // Update the local event by removing the resource
          final eventIndex = _events.indexWhere((e) => e.id == eventId);
          if (eventIndex != -1) {
            final updatedResources = _events[eventIndex].resources
                .where((resource) => resource != resourceUrl)
                .toList();
            final updatedEvent = _events[eventIndex].copyWith(
              resources: updatedResources,
            );
            _events[eventIndex] = updatedEvent;
            _applyFilters();
          }
          success = true;
        }
      },
    );

    _setLoading(false);
    return success;
  }

  // Get events by category
  List<Event> getEventsByCategory(EventCategory category) {
    return _events.where((event) => event.category == category).toList();
  }

  // Get event categories with counts
  Map<EventCategory, int> getCategoryCounts() {
    final Map<EventCategory, int> counts = {};
    for (final category in EventCategory.values) {
      counts[category] = _events.where((event) => event.category == category).length;
    }
    return counts;
  }

  // Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _filterStart = null;
    _filterEnd = null;
    _applyFilters();
  }

  // Private helper methods
  void _applyFilters() {
    List<Event> filtered = List.from(_events);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((event) => event.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
               event.description.toLowerCase().contains(query) ||
               (event.venue?.toLowerCase().contains(query) ?? false) ||
               event.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply date/time range filter
    if (_filterStart != null) {
      filtered = filtered.where((event) {
        final dt = event.dateTime;
        if (dt == null) return false;
        return dt.isAfter(_filterStart!) || _isSameDayMinute(dt, _filterStart!);
      }).toList();
    }
    if (_filterEnd != null) {
      filtered = filtered.where((event) {
        final dt = event.dateTime;
        if (dt == null) return false;
        return dt.isBefore(_filterEnd!) || _isSameDayMinute(dt, _filterEnd!);
      }).toList();
    }

    // Sort by date (upcoming first)
    filtered.sort((a, b) {
      final aDate = a.dateTime ?? DateTime.now();
      final bDate = b.dateTime ?? DateTime.now();
      return aDate.compareTo(bDate);
    });

    _filteredEvents = filtered;
    notifyListeners();
  }

  bool _isSameDayMinute(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day && a.hour == b.hour && a.minute == b.minute;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Utility methods for UI
  String getEventModeDisplayName(EventMode mode) {
    switch (mode) {
      case EventMode.online:
        return 'Online';
      case EventMode.offline:
        return 'Offline';
      case EventMode.hybrid:
        return 'Hybrid';
    }
  }

  String getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.technical:
        return 'Technical';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.webinar:
        return 'Webinar';
      case EventCategory.conference:
        return 'Conference';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.social:
        return 'Social';
      case EventCategory.other:
        return 'Other';
    }
  }

  Color getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return Colors.blue;
      case EventCategory.cultural:
        return Colors.purple;
      case EventCategory.technical:
        return Colors.green;
      case EventCategory.workshop:
        return Colors.orange;
      case EventCategory.seminar:
        return Colors.red;
      case EventCategory.webinar:
        return Colors.teal;
      case EventCategory.conference:
        return Colors.indigo;
      case EventCategory.sports:
        return Colors.amber;
      case EventCategory.social:
        return Colors.pink;
      case EventCategory.other:
        return Colors.grey;
    }
  }
}
