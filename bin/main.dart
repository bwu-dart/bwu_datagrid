import 'dart:async' show Stream, StreamController;

class Events {
  static const EventType<ContextMenu> contextMenu =
      const EventType<ContextMenu>('bwu-context-menu');
}

class EventData {}

class EventType<T extends EventData> {
  final String name;
  const EventType(this.name);
}

class ContextMenu extends EventData {}

class EventBus<T extends EventData> {
  final Map<EventType<T>, StreamController<T>> streamControllers =
      <EventType<T>, StreamController<T>>{};

  Stream<U> onEvent/*<U extends T>*/(EventType<T> eventType) {
    return streamControllers.putIfAbsent(eventType, () {
      return new StreamController<U>.broadcast(sync: true);
    }).stream;
  }

  T fire(EventType<T> eventType, T data) {
    final StreamController<T> controller =
        streamControllers.putIfAbsent(eventType, () {
      return new StreamController<T>.broadcast(sync: true);
    });

    controller.add(data);
    return data;
  }
}

class Grid {
  EventBus<EventData> _eventBus = new EventBus<EventData>();

  Stream<ContextMenu> get onBwuContextMenu =>
      _eventBus.onEvent(Events.contextMenu);

  void someMethod() {
    onBwuContextMenu.listen((ContextMenu e) {
      print(e);
    });
  }
}

void main() {
  final Grid g = new Grid();
  g.someMethod();
}
