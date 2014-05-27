library bwu_dart.bwu_dataview.events;

import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';

abstract class Events {

  static const PAGING_INFO_CHANGED = const core.EventType<PagingInfoChanged>(
      'paging-info-changed');

  static const ROW_COUNT_CHANGED = const core.EventType<RowCountChanged>(
      'row-count-changed');

  static const ROWS_CHANGED = const core.EventType<RowsChanged>(
      'rows-changed');

  static const SELECTED_ROW_IDS_CHANGED = const core.EventType<SelectedRowIdsChanged>(
      'selected-row-ids-changed');

}

class PagingInfoChanged extends core.EventData {
  PagingInfo pagingInfo;

  PagingInfoChanged(sender, {PagingInfo pagingInfo}) : super(sender: sender, detail: {
        'pagingInfo': pagingInfo
      }) {
    this.pagingInfo = pagingInfo;
  }
}

class RowCountChanged extends core.EventData {
  int oldCount;
  int newCount;
  RowCountChanged(sender, {int oldCount, int newCount}) : super(sender: sender, detail: {
        'oldCount': oldCount,
        'newCount': newCount
      }) {
    this.oldCount = oldCount;
    this.newCount = newCount;
  }
}

class RowsChanged extends core.EventData {
  List<int> changedRows;
  RowsChanged(sender, {List<int> changedRows}) : super(sender: sender, detail: {
        'changedRows': changedRows
      }) {
    this.changedRows = changedRows;
  }
}

class SelectedRowIdsChanged extends core.EventData {
  BwuDatagrid grid;
  List<String> ids;

  SelectedRowIdsChanged(sender, BwuDatagrid grid, List<String> ids) : super(sender: sender, detail: {
        'grid': grid,
        'ids': ids
      }) {
    this.grid = grid;
    this.ids = ids;
  }
}
