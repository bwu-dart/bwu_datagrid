library bwu_datagrid.plugins.row_selection_model;

import 'dart:html' as dom;
import 'dart:async' as async;
import 'dart:math' as math;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';

class RowSelectionModelOptions {
  bool selectActiveRow;

  RowSelectionModelOptions({this.selectActiveRow: true});
}

class RowSelectionModel extends SelectionModel {
  BwuDatagrid _grid;
  List<core.Range> _ranges = [];
  //var _handler = new Slick.EventHandler();
  //int _inHandler;
  RowSelectionModelOptions _options;

  RowSelectionModel([RowSelectionModelOptions options]) {
    if(options != null) {
      _options = options;
    } else {
      _options = new RowSelectionModelOptions();
    }
  }

  List<async.StreamSubscription> _subscriptions = [];

  void init(BwuDatagrid grid) {
    //_options = $.extend(true, {}, _defaults, options);
    _grid = grid;
    _subscriptions.add(_grid.onBwuActiveCellChanged.listen(_handleActiveCellChange));
    _subscriptions.add(_grid.onBwuKeyDown.listen(_handleKeyDown));
    _subscriptions.add(_grid.onBwuClick.listen(_handleClick));
  }

  void destroy() {
    _subscriptions.forEach((e) => e.cancel());
  }

//  void wrapHandler(handler) {
//    return function () {
//      if (!_inHandler) {
//        _inHandler = true;
//        handler.apply(this, arguments);
//        _inHandler = false;
//      }
//    };
//  }

  List<int> _rangesToRows(List<core.Range> ranges) {
    List<int> rows = [];
    for (var i = 0; i < ranges.length; i++) {
      for (var j = ranges[i].fromRow; j <= ranges[i].toRow; j++) {
        rows.add(j);
      }
    }
    return rows;
  }

  List<core.Range> _rowsToRanges(List<int> rows) {
    List<core.Range> ranges = [];
    var lastCell = _grid.getColumns.length - 1;
    for (var i = 0; i < rows.length; i++) {
      ranges.add(new core.Range(rows[i], 0, toRow: rows[i], toCell: lastCell));
    }
    return ranges;
  }

  List<int> _getRowsRange(int from, int to) {
    var i, rows = [];
    for (i = from; i <= to; i++) {
      rows.add(i);
    }
    for (i = to; i < from; i++) {
      rows.add(i);
    }
    return rows;
  }

  List<int> getSelectedRows() {
    return _rangesToRows(_ranges);
  }

  void setSelectedRows(List<int> rows) {
    setSelectedRanges(_rowsToRanges(rows));
  }

  void setSelectedRanges(List<core.Range> ranges) {
    _ranges = ranges;
    _grid.eventBus.fire(core.Events.SELECTED_RANGES_CHANGED, new SelectedRangesChanged(this, _ranges));
    //_self.onSelectedRangesChanged.notify(_ranges);
  }

  List<core.Range> getSelectedRanges() {
    return _ranges;
  }

  void _handleActiveCellChange(ActiveCellChanged e) {
    if (_options.selectActiveRow && e.cell != null && e.cell.row != null) {
      setSelectedRanges([new core.Range(e.cell.row, 0, toRow: e.cell.row, toCell: _grid.getColumns.length - 1)]);
    }
  }

  void _handleKeyDown(core.KeyDown e) {
    Cell activeRow = _grid.getActiveCell();
    if (activeRow != null && e.causedBy.shiftKey && !e.causedBy.ctrlKey && !e.causedBy.altKey && !e.causedBy.metaKey && (e.causedBy.which == dom.KeyCode.UP || e.causedBy.which == dom.KeyCode.DOWN)) {
      List<int> selectedRows = getSelectedRows();
      selectedRows.sort((x, y) {
        return x - y;
      });

      if (selectedRows.length == 0) {
        selectedRows = [activeRow.row];
      }

      int top = selectedRows[0];
      int bottom = selectedRows[selectedRows.length - 1];
      int active;

      if (e.causedBy.which == dom.KeyCode.DOWN) {
        active = activeRow.row < bottom || top == bottom ? ++bottom : ++top;
      } else {
        active = activeRow.row < bottom ? --bottom : --top;
      }

      if (active >= 0 && active < _grid.getDataLength) {
        _grid.scrollRowIntoView(active);
        _ranges = _rowsToRanges(_getRowsRange(top, bottom));
        setSelectedRanges(_ranges);
      }

      e.preventDefault();
      e.stopPropagation();
    }
  }

  void _handleClick(Click e) {
    Cell cell = _grid.getCellFromEvent(e.causedBy);
    if (cell == null || !_grid.canCellBeActive(cell.row, cell.cell)) {
      return; // TODO is this needed? false;
    }

    if (!_grid.getGridOptions.multiSelect || (
        !e.causedBy.ctrlKey && !e.causedBy.shiftKey && !e.causedBy.metaKey)) {
      return; // TODO is this needed? false;
    }

    List<int> selection = _rangesToRows(_ranges);
    var idx = selection.indexOf(cell.row); //$.inArray(cell.row, selection);

    if (idx == -1 && (e.causedBy.ctrlKey || e.causedBy.metaKey)) {
      selection.add(cell.row);
      _grid.setActiveCell(cell.row, cell.cell);
    } else if (idx != -1 && (e.causedBy.ctrlKey || e.causedBy.metaKey)) {
      selection = selection.where((o) => o != cell.row);
      _grid.setActiveCell(cell.row, cell.cell);
    } else if (selection.length > 0 && e.causedBy.shiftKey) {
      var last = selection.removeLast();
      var from = math.min(cell.row, last);
      var to = math.max(cell.row, last);
      selection = [];
      for (var i = from; i <= to; i++) {
        if (i != last) {
          selection.add(i);
        }
      }
      selection.add(last);
      _grid.setActiveCell(cell.row, cell.cell);
    }

    _ranges = _rowsToRanges(selection);
    setSelectedRanges(_ranges);
    e.stopImmediatePropagation();

    return; // TODO is this needed? true;
  }
}