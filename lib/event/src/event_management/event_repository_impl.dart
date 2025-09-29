import 'package:dartz/dartz.dart';
import 'event.dart';
import 'event_repository.dart';
import 'event_local_datasource.dart';
import '../core/services/event_api_service.dart';

class EventRepositoryImpl implements EventRepository {
  final EventLocalDataSource localDataSource;
  final EventApiService? apiService;

  EventRepositoryImpl({
    required this.localDataSource,
    this.apiService,
  });

  @override
  Future<Either<String, List<Event>>> getAllEvents() async {
    try {
      // Try to fetch from API first if available
      if (apiService != null) {
        try {
          final response = await apiService!.getAllEvents();
          final events = response.events;
          
          // Cache events locally for offline access
          for (final event in events) {
            await localDataSource.cacheEvent(event);
          }
          
          return Right(events);
        } catch (apiError) {
          print('🚨 API fetch failed, falling back to local data: $apiError');
          // Fall back to local data if API fails
        }
      }
      
      // Fallback to local data
      final events = await localDataSource.getAllEvents();
      return Right(events);
    } catch (e) {
      return Left('Failed to get events: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Event>> getEventById(String id) async {
    try {
      // Try to fetch from API first if available
      if (apiService != null) {
        try {
          final event = await apiService!.getEventById(id);
          await localDataSource.cacheEvent(event);
          return Right(event);
        } catch (apiError) {
          print('🚨 API fetch failed, falling back to local data: $apiError');
        }
      }
      
      final event = await localDataSource.getEventById(id);
      if (event != null) {
        return Right(event);
      } else {
        return const Left('Event not found');
      }
    } catch (e) {
      return Left('Failed to get event: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Event>> getEventBySlug(String slug) async {
    try {
      // Try to fetch from API first if available
      if (apiService != null) {
        try {
          final event = await apiService!.getEventBySlug(slug);
          await localDataSource.cacheEvent(event);
          return Right(event);
        } catch (apiError) {
          print('🚨 API fetch by slug failed: $apiError');
          return Left('Failed to get event: ${apiError.toString()}');
        }
      }
      
      // Fallback: try to find by slug in local data
      final events = await localDataSource.getAllEvents();
      final event = events.where((e) => e.slug == slug).firstOrNull;
      if (event != null) {
        return Right(event);
      } else {
        return const Left('Event not found');
      }
    } catch (e) {
      return Left('Failed to get event: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<Event>>> getEventsByCategory(EventCategory category) async {
    try {
      final events = await localDataSource.getAllEvents();
      final filteredEvents = events.where((event) => event.category == category).toList();
      return Right(filteredEvents);
    } catch (e) {
      return Left('Failed to get events by category: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<Event>>> searchEvents(String query) async {
    try {
      final events = await localDataSource.getAllEvents();
      final filteredEvents = events.where((event) {
        final searchQuery = query.toLowerCase();
        return event.title.toLowerCase().contains(searchQuery) ||
               event.description.toLowerCase().contains(searchQuery) ||
               (event.venue?.toLowerCase().contains(searchQuery) ?? false) ||
               event.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
      return Right(filteredEvents);
    } catch (e) {
      return Left('Failed to search events: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Event>> createEvent(Event event) async {
    try {
      final now = DateTime.now();
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Set default values for required fields
      final defaultStartDate = event.startDate ?? event.dateTime ?? now.add(const Duration(days: 1));
      final defaultEndDate = event.endDate ?? event.endDateTime ?? defaultStartDate.add(const Duration(hours: 2));
      final defaultRegistrationDeadline = event.registrationDeadline ?? defaultStartDate.subtract(const Duration(hours: 1));
      
      // Validate required fields
      if (event.title.isEmpty || event.description.isEmpty || event.location.isEmpty) {
        return const Left('Title, description, and location are required');
      }
      
      if (event.category == null) {
        return const Left('Category is required');
      }

      // Create a complete event object with all required fields
      final newEvent = Event(
        id: newId,
        title: event.title,
        description: event.description,
        location: event.location,
        images: event.images,
        videos: event.videos,
        createdBy: event.createdBy ?? const CreatedBy(
          id: 'system',
          name: 'System',
          email: 'system@example.com',
        ),
        isActive: true,
        createdAt: now,
        updatedAt: now,
        slug: '${event.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}-$newId',
        startDate: defaultStartDate,
        endDate: defaultEndDate,
        startTime: event.startTime ?? '10:00',
        endTime: event.endTime ?? '12:00',
        dateTime: event.dateTime,
        endDateTime: event.endDateTime,
        venue: event.venue,
        mode: event.mode ?? EventMode.offline,
        category: event.category!,
        resources: event.resources,
        imageUrl: event.imageUrl,
        price: event.price,
        maxAttendees: event.maxAttendees,
        currentAttendees: event.currentAttendees ?? 0,
        organizerId: event.organizerId,
        organizerName: event.organizerName,
        tags: event.tags,
        meetingLink: event.meetingLink,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        registrationDeadline: defaultRegistrationDeadline,
        participantStats: event.participantStats ?? ParticipantStats(
          totalEnrollments: 0,
          approvedParticipants: 0,
          pendingRequests: 0,
          declinedRequests: 0,
          availableSpots: event.maxAttendees ?? 0,
        ),
      );

      // Try to create via API first if available
      if (apiService != null) {
        try {
          final createdEvent = await apiService!.createEvent(
            title: newEvent.title,
            description: newEvent.description,
            location: newEvent.location,
            startDate: newEvent.startDate!,
            endDate: newEvent.endDate!,
            startTime: newEvent.startTime!,
            endTime: newEvent.endTime!,
            mode: newEvent.mode!,
            category: newEvent.category!,
            price: newEvent.price,
            maxParticipants: newEvent.maxAttendees,
            registrationDeadline: newEvent.registrationDeadline!,
            images: newEvent.images,
            videos: newEvent.videos,
            tags: newEvent.tags,
          );
          
          // Cache the newly created event
          await localDataSource.cacheEvent(createdEvent);
          return Right(createdEvent);
        } catch (apiError) {
          print('🚨 API create failed, creating locally: $apiError');
          // Continue with local creation if API fails
        }
      }
      
      // Create locally if API is not available or failed
      await localDataSource.cacheEvent(newEvent);
      return Right(newEvent);
    } catch (e) {
      return Left('Failed to create event: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Event>> updateEvent(Event event) async {
    try {
      // Try to update via API first if available
      if (apiService != null) {
        try {
          final updatedEvent = await apiService!.updateEvent(
            eventId: event.id,
            title: event.title,
            description: event.description,
            location: event.location,
            startDate: event.startDate ?? event.dateTime ?? DateTime.now(),
            endDate: event.endDate ?? event.endDateTime ?? DateTime.now().add(const Duration(hours: 1)),
            startTime: event.startTime ?? '00:00',
            endTime: event.endTime ?? '01:00',
            mode: event.mode ?? EventMode.offline,
            category: event.category ?? EventCategory.other,
            price: event.price,
            maxParticipants: event.maxAttendees,
            registrationDeadline: event.registrationDeadline,
            images: event.images,
            tags: event.tags,
            isActive: event.isActive,
          );
          await localDataSource.cacheEvent(updatedEvent);
          return Right(updatedEvent);
        } catch (apiError) {
          print('🚨 API update failed, updating locally: $apiError');
          // Fall back to local update if API fails
        }
      }
      
      // Fallback to local update
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      await localDataSource.cacheEvent(updatedEvent);
      return Right(updatedEvent);
    } catch (e) {
      return Left('Failed to update event: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, bool>> deleteEvent(String id) async {
    try {
      // Try to delete from API first if available
      if (apiService != null) {
        try {
          await apiService!.deleteEvent(id);
        } catch (apiError) {
          print('🚨 API delete failed, deleting locally: $apiError');
          // Continue with local delete even if API fails
        }
      }
      
      // Always delete from local storage
      await localDataSource.deleteEvent(id);
      return const Right(true);
    } catch (e) {
      return Left('Failed to delete event: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<Event>>> getUpcomingEvents() async {
    try {
      final events = await localDataSource.getAllEvents();
      final now = DateTime.now();
      final upcomingEvents = events
          .where((event) => (event.dateTime?.isAfter(now) ?? false) && event.isActive)
          .toList();
      upcomingEvents.sort((a, b) {
        final aDate = a.dateTime ?? DateTime.now();
        final bDate = b.dateTime ?? DateTime.now();
        return aDate.compareTo(bDate);
      });
      return Right(upcomingEvents);
    } catch (e) {
      return Left('Failed to get upcoming events: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<Event>>> getEventsByDateRange(DateTime start, DateTime end) async {
    try {
      final events = await localDataSource.getAllEvents();
      final filteredEvents = events.where((event) {
        return (event.dateTime?.isAfter(start) ?? false) && (event.dateTime?.isBefore(end) ?? false);
      }).toList();
      return Right(filteredEvents);
    } catch (e) {
      return Left('Failed to get events by date range: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, String>> uploadEventResource(String eventId, String filePath) async {
    try {
      final event = await localDataSource.getEventById(eventId);
      if (event != null) {
        final updatedResources = List<String>.from(event.resources)..add(filePath);
        final updatedEvent = event.copyWith(
          resources: updatedResources,
          updatedAt: DateTime.now(),
        );
        await localDataSource.cacheEvent(updatedEvent);
        return Right(filePath);
      } else {
        return const Left('Event not found');
      }
    } catch (e) {
      return Left('Failed to upload resource: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, bool>> removeEventResource(String eventId, String resourceUrl) async {
    try {
      final event = await localDataSource.getEventById(eventId);
      if (event != null) {
        final updatedResources = List<String>.from(event.resources)..remove(resourceUrl);
        final updatedEvent = event.copyWith(
          resources: updatedResources,
          updatedAt: DateTime.now(),
        );
        await localDataSource.cacheEvent(updatedEvent);
        return const Right(true);
      } else {
        return const Left('Event not found');
      }
    } catch (e) {
      return Left('Failed to remove resource: ${e.toString()}');
    }
  }
}
