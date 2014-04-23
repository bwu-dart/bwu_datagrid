part of bwu_dart.bwu_datagrid.core.range;


/**
 * [EventBus] is a central event hub.
 */
class EventBus extends Object with polymer.Observable {
  final _logger = new logging.Logger("EventBusModel");

  /**
   * A [StreamController] is maintained for each event type.
   */
  Map<EventType, async.StreamController> streamControllers = new Map<EventType, async.StreamController>();

  //StreamController _historyStreamController = new StreamController();

  @polymer.observable bool isSync = true; // TODO when bug is fixed (literal values for attributes)

  /**
   * Constructs an [EventBus] and allows to specify if the events should be
   * send synchroniously or asynchroniously by setting [isSync].
   */
  EventBus({this.isSync : false});

  /**
   * [onEvent] allows to access an stream for the specified [eventType].
   */
  async.Stream/*<T>*/ onEvent(EventType/*<T>*/ eventType) {
    _logger.finest('onEvent');

    if(!streamControllers.containsKey(eventType)) {
      _logger.finest('onEvent: new EventType: ${eventType.name}');
    }

    return streamControllers.putIfAbsent(eventType, () {
      return new async.StreamController.broadcast(sync: isSync);
      }
    ).stream;
  }

  /**
   * [fire] broadcasts an event of a type [eventType] to all subscribers.
   */
  void fire(EventType/*<T>*/ eventType, /*<T>*/ data) {
    _logger.finest('event fired: ${eventType.name}');

    if (data != null && !eventType.isTypeT(data)) {
      throw new ArgumentError('Provided data is not of same type as T of EventType.');
    }

    if(!streamControllers.containsKey(eventType)) {
      _logger.finest('fire: new EventType: ${eventType.name}');
    }

      var controller = streamControllers.putIfAbsent(eventType, () {
        return new async.StreamController.broadcast(sync: isSync);
      });
      controller.add(data);
  }
}

/**
 * Type class used to publish events with an [EventBus].
 * [T] is the type of data that is provided when an event is fired.
 */
class EventType<T> {

  String name;
  bool isHistoryUpdate;

  /**
   * [hash] is the URI part after the # which is associated with this event.
   */
  String hash;

  /**
   * Constructor with an optional [name] for logging purposes.
   */
  EventType(this.name, {this.isHistoryUpdate : false, this.hash : ""});

  /**
   * Returns true if the provided data is of type [T].
   *
   * This method is needed to provide type safety to the [EventBus] as long as
   * Dart does not support generic types for methods.
   */
  bool isTypeT(data) => data is T;
}

