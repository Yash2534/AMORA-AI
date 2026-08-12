import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/domain/my_event_category.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:flutter/foundation.dart';

class EventParticipationController extends ChangeNotifier {
  EventParticipationController({this.repository});

  static final EventParticipationController instance =
      EventParticipationController();

  final Map<String, UserEventRegistration> _registrations =
      <String, UserEventRegistration>{};
  final EventRepository? repository;
  EventRepository get _remote => repository ?? EventRepository.instance;
  bool _isLoading = false;
  bool _hasLoadError = false;

  List<UserEventRegistration> get registrations =>
      List<UserEventRegistration>.unmodifiable(_registrations.values);

  Map<String, TicketStatus> get statuses =>
      Map<String, TicketStatus>.unmodifiable(
        _registrations.map(
          (id, registration) => MapEntry(id, registration.status),
        ),
      );

  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  TicketStatus? statusFor(String eventId) => _registrations[eventId]?.status;

  List<UserEventRegistration> registrationsFor(
    MyEventCategory category, {
    DateTime? now,
  }) => sortMyEvents(_registrations.values, category, now: now);

  int countFor(MyEventCategory category, {DateTime? now}) =>
      registrationsFor(category, now: now).length;

  void registerEvent(EventModel event, {DateTime? registeredAt}) {
    _setRegistration(
      UserEventRegistration(
        event: event,
        status: TicketStatus.upcoming,
        registeredAt: registeredAt ?? DateTime.now(),
      ),
    );
  }

  void cancelEvent(EventModel event, {DateTime? cancelledAt}) {
    final existing = _registrations[event.id];
    if (existing == null || existing.status == TicketStatus.cancelled) return;
    _setRegistration(
      UserEventRegistration(
        event: event,
        status: TicketStatus.cancelled,
        registeredAt: existing.registeredAt,
        cancelledAt: cancelledAt ?? DateTime.now(),
      ),
    );
  }

  void startLoading() {
    if (_isLoading && !_hasLoadError) return;
    _isLoading = true;
    _hasLoadError = false;
    notifyListeners();
  }

  void completeLoading() {
    if (!_isLoading && !_hasLoadError) return;
    _isLoading = false;
    _hasLoadError = false;
    notifyListeners();
  }

  void reportLoadFailure() {
    _isLoading = false;
    _hasLoadError = true;
    notifyListeners();
  }

  void retry() => completeLoading();

  void syncCatalog(Iterable<EventModel> events) {
    var changed = false;
    for (final event in events) {
      final status = event.participationStatus;
      if (status == null) continue;
      _registrations[event.id] = UserEventRegistration(
        event: event,
        status: status,
        registeredAt: DateTime.now(),
        cancelledAt: status == TicketStatus.cancelled ? DateTime.now() : null,
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> loadMyEvents() async {
    startLoading();
    try {
      final page = await _remote.myEvents('all');
      _registrations.clear();
      for (final event in page.events) {
        final status = event.participationStatus;
        if (status == null) continue;
        _registrations[event.id] = UserEventRegistration(
          event: event,
          status: status,
          registeredAt: DateTime.now(),
          cancelledAt: status == TicketStatus.cancelled ? DateTime.now() : null,
        );
      }
      completeLoading();
    } catch (_) {
      reportLoadFailure();
    }
  }

  Future<void> registerRemote(EventModel event) async {
    final status = await _remote.register(event.id);
    _applyRemoteStatus(event, status);
  }

  Future<void> cancelRemote(EventModel event) async {
    final status = await _remote.cancelRegistration(event.id);
    _applyRemoteStatus(event, status);
  }

  void _applyRemoteStatus(EventModel event, TicketStatus? status) {
    if (status == null) {
      _registrations.remove(event.id);
    } else {
      _registrations[event.id] = UserEventRegistration(
        event: event,
        status: status,
        registeredAt: _registrations[event.id]?.registeredAt ?? DateTime.now(),
        cancelledAt: status == TicketStatus.cancelled ? DateTime.now() : null,
      );
    }
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    final changed = _registrations.isNotEmpty || _isLoading || _hasLoadError;
    _registrations.clear();
    _isLoading = false;
    _hasLoadError = false;
    if (changed) notifyListeners();
  }

  void _setRegistration(UserEventRegistration registration) {
    final existing = _registrations[registration.event.id];
    if (existing?.status == registration.status &&
        identical(existing?.event, registration.event)) {
      return;
    }
    _registrations[registration.event.id] = registration;
    notifyListeners();
  }
}
