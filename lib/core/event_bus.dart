part of bwu_datagrid.core;

/// [EventBus] is a central event hub.
class EventBus<T extends EventData> {
  final logging.Logger _logger = new logging.Logger("EventBusModel");

  /// A [StreamController] is maintained for each event type.
  final Map<EventType<T>, async.StreamController<T>> streamControllers =
      <EventType<T>, async.StreamController<T>>{};

  final bool isSync;

  /// Constructs an [EventBus] and allows to specify if the events should be
  /// send synchronously or asynchronously by setting [isSync].
  EventBus({this.isSync: true});

  ///  [onEvent] allows to access an stream for the specified [eventType].
  async.Stream<T /*=U*/> onEvent/*<U extends T>*/(EventType<T> eventType) {
    _logger.finest('onEvent');

    if (!streamControllers.containsKey(eventType)) {
      _logger.finest('onEvent: new EventType: ${eventType.name}');
    }

    return streamControllers.putIfAbsent(eventType, () {
      return new async.StreamController<T /*=U*/>.broadcast(sync: isSync);
    }).stream as async.Stream<T /*=U*/>;
  }

  /// [fire] broadcasts an event of a type [eventType] to all subscribers.
  T /*=U*/ fire/*<U extends T>*/(EventType<T> eventType, T/*=U*/ data) {
    _logger.finest('event fired: ${eventType.name}');

    if (data != null && !eventType.isTypeT(data)) {
      throw new ArgumentError(
          'Provided data is not of same type as T of EventType.');
    }

    if (!streamControllers.containsKey(eventType)) {
      _logger.finest('fire: new EventType: ${eventType.name}');
    }

    final async.StreamController<T> controller =
        streamControllers.putIfAbsent(eventType, () {
      return new async.StreamController<T /*=U*/>.broadcast(sync: isSync);
    });

    controller.add(data);
    return data;
  }
}

///  Type class used to publish events with an [EventBus].
///  [T] is the type of data that is provided when an event is fired.
class EventType<T extends EventData> {
  final String name;

  /// Constructor with an optional [name] for logging purposes.
  const EventType(this.name);

  /// Returns true if the provided data is of type [T].
  ///
  /// This method is needed to provide type safety to the [EventBus] as long as
  /// Dart does not support generic types for methods.
  bool isTypeT(dynamic data) => data is T;
}
