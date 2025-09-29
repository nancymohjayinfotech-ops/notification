import 'package:dartz/dartz.dart';
import 'event.dart';

abstract class EventRepository {
  Future<Either<String, List<Event>>> getAllEvents();
  Future<Either<String, Event>> getEventById(String id);
  Future<Either<String, Event>> getEventBySlug(String slug);
  Future<Either<String, List<Event>>> getEventsByCategory(EventCategory category);
  Future<Either<String, List<Event>>> searchEvents(String query);
  Future<Either<String, Event>> createEvent(Event event);
  Future<Either<String, Event>> updateEvent(Event event);
  Future<Either<String, bool>> deleteEvent(String id);
  Future<Either<String, List<Event>>> getUpcomingEvents();
  Future<Either<String, List<Event>>> getEventsByDateRange(DateTime start, DateTime end);
  Future<Either<String, String>> uploadEventResource(String eventId, String filePath);
  Future<Either<String, bool>> removeEventResource(String eventId, String resourceUrl);
}
