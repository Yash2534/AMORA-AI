import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';

class FixtureEventRepository extends EventRepository {
  FixtureEventRepository(this.fixtures) : super(remote: _UnusedRemote());
  final List<EventModel> fixtures;

  @override
  Future<EventPage> browse({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? city,
    DateTime? dateFrom,
    DateTime? dateTo,
    String timing = 'upcoming',
    bool? available,
  }) async {
    final normalized = search?.trim().toLowerCase();
    final values = fixtures
        .where((event) {
          if (normalized?.isNotEmpty == true &&
              !'${event.title} ${event.category} ${event.city}'
                  .toLowerCase()
                  .contains(normalized!)) {
            return false;
          }
          if (category != null &&
              event.category.toLowerCase() != category.toLowerCase() &&
              !event.category.toLowerCase().contains(category.toLowerCase())) {
            return false;
          }
          if (city != null && event.city != city) return false;
          return true;
        })
        .toList(growable: false);
    final offset = (page - 1) * limit;
    final pageValues = offset >= values.length
        ? const <EventModel>[]
        : values.skip(offset).take(limit).toList(growable: false);
    return EventPage(
      events: pageValues,
      hasMore: offset + pageValues.length < values.length,
      nextPage: offset + pageValues.length < values.length ? page + 1 : null,
    );
  }

  @override
  Future<EventModel> detail(String eventId) async =>
      fixtures.firstWhere((event) => event.id == eventId);

  @override
  Future<EventPage> myEvents(
    String category, {
    int page = 1,
    int limit = 50,
  }) async => EventPage(events: fixtures, hasMore: false);

  @override
  Future<TicketStatus?> register(String eventId) async => TicketStatus.upcoming;
  @override
  Future<TicketStatus?> cancelRegistration(String eventId) async =>
      TicketStatus.cancelled;
}

class _UnusedRemote implements EventRemoteDataSource {
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => throw UnimplementedError();
}
