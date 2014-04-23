part of bwu_dart.bwu_datagrid.dataview;

class RowCountChangedEvent extends EventData {}

class RowsChangedEvent extends EventData {}

class PagingInfoChanged extends EventData {}

abstract class Events {
  static final EventType<RowCountChangedEvent> rowCountChanged =
      new EventType<RowCountChangedEvent>("row-count-changed");
  static final EventType<RowsChangedEvent> rowsChanged =
      new EventType<RowsChangedEvent>("rows-changed");
  static final EventType<PagingInfoChanged> pagingInfoChanged =
      new EventType<PagingInfoChanged>("rows-changed");

  static List<EventType> events() => [rowCountChanged, rowsChanged,
      pagingInfoChanged];
}
