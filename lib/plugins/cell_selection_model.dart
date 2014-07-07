library bwu_datagrid.plugins.cell_selection_model;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/plugins/cell_range_selector.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/plugins/cell_range_decorator.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';

class CellSelectionModelOptions {
  bool selectActiveCell;

  CellSelectionModelOptions({this.selectActiveCell : true});
}

class CellSelectionModel extends SelectionModel {
  BwuDatagrid _grid;
  dom.HtmlElement _canvas;
  List<core.Range> _ranges = <core.Range>[];
  var _selector = new CellRangeSelector(new CellRangeDecoratorOptions(
    selectionCss: {'border': '2px solid black', 'z-index': '9999'}
  ));
  CellSelectionModelOptions _options;
  var _defaults = {
    'selectActiveCell': true
  };

  CellSelectionModel([CellSelectionModelOptions options]) {
    if(_options != null) {
      this._options = options;
    } else {
      this._options = new CellSelectionModelOptions();
    }
  }

  async.StreamSubscription _cellRangeSelectedSubscription;
  async.StreamSubscription _beforeCellRangeSelectedSubscription;

  List<async.StreamSubscription> _subscriptions = <async.StreamSubscription>[];

  void init(BwuDatagrid grid) {
    // TODO _options = $.extend(true, {}, _defaults, options);
    _grid = grid;
    _canvas = _grid.getCanvasNode;
    _subscriptions.add(_grid.onBwuActiveCellChanged.listen(handleActiveCellChange));
    _subscriptions.add(_grid.onBwuKeyDown.listen(handleKeyDown));
    grid.registerPlugin(_selector);
    _subscriptions.add(_selector.onBwuCellRangeSelected.listen(handleCellRangeSelected));
    _subscriptions.add(_selector.onBwuBeforeCellRangeSelected.listen(handleBeforeCellRangeSelected));
  }


  void destroy() {
    _subscriptions.forEach((e) => e.cancel());
    _grid.unregisterPlugin(_selector);
  }

  List<core.Range> removeInvalidRanges(ranges) {
    var result = [];

    for (var i = 0; i < ranges.length; i++) {
      var r = ranges[i];
      if (_grid.canCellBeSelected(r.fromRow, r.fromCell) && _grid.canCellBeSelected(r.toRow, r.toCell)) {
        result.add(r);
      }
    }

    return result;
  }

  void setSelectedRanges(ranges) {
    _ranges = removeInvalidRanges(ranges);
    _grid.eventBus.fire(core.Events.SELECTED_RANGES_CHANGED, new core.SelectedRangesChanged(this, _ranges));
//    _self.onSelectedRangesChanged.notify(_ranges);
  }

  List<core.Range> getSelectedRanges() {
    return _ranges;
  }

  void handleBeforeCellRangeSelected(BeforeCellRangeSelected e) {
    if (_grid.getEditorLock.isActive) {
      e.stopPropagation();
      e.retVal = false;
    }
  }

  void handleCellRangeSelected(CellRangeSelected e) {
    setSelectedRanges([e.range]);
  }

  void handleActiveCellChange(ActiveCellChanged e) {
    if (_options.selectActiveCell != null && e.cell.row != null && e.cell != null) {
      setSelectedRanges([new core.Range(e.cell.row, e.cell.cell)]);
    }
  }

  void handleKeyDown(KeyDown e) {
    List<core.Range> ranges;
    core.Range last;
    Cell active = _grid.getActiveCell();

    if ( active != null && e.causedBy.shiftKey && !e.causedBy.ctrlKey && !e.causedBy.altKey &&
        (e.causedBy.which == dom.KeyCode.LEFT || e.causedBy.which == dom.KeyCode.RIGHT || e.causedBy.which == dom.KeyCode.UP || e.causedBy.which == dom.KeyCode.DOWN) ) {

      ranges = getSelectedRanges();
      if (ranges.length == 0)
       ranges.add(new core.Range(active.row, active.cell));

      // keyboard can work with last range only
      last = ranges.removeLast();

      // can't handle selection out of active cell
      if (!last.contains(active.row, active.cell))
        last = new core.Range(active.row, active.cell);

      var dRow = last.toRow - last.fromRow,
          dCell = last.toCell - last.fromCell,
          // walking direction
          dirRow = active.row == last.fromRow ? 1 : -1,
          dirCell = active.cell == last.fromCell ? 1 : -1;

      if (e.causedBy.which == dom.KeyCode.LEFT) {
        dCell -= dirCell;
      } else if (e.causedBy.which == dom.KeyCode.RIGHT) {
        dCell += dirCell ;
      } else if (e.causedBy.which == dom.KeyCode.UP) {
        dRow -= dirRow;
      } else if (e.causedBy.which == dom.KeyCode.DOWN) {
        dRow += dirRow;
      }

      // define new selection range
      var new_last = new core.Range(active.row, active.cell, toRow: active.row + dirRow * dRow, toCell: active.cell + dirCell * dCell);
      if (removeInvalidRanges([new_last]).length != 0) {
        ranges.add(new_last);
        var viewRow = dirRow > 0 ? new_last.toRow : new_last.fromRow;
        var viewCell = dirCell > 0 ? new_last.toCell : new_last.fromCell;
       _grid.scrollRowIntoView(viewRow);
       _grid.scrollCellIntoView(viewRow, viewCell);
      }
      else {
        ranges.add(last);
      }

      setSelectedRanges(ranges);

      e.preventDefault();
      e.stopPropagation();
    }
  }
}

//    $.extend(this, {
//      "getSelectedRanges": getSelectedRanges,
//      "setSelectedRanges": setSelectedRanges,
//
//      "init": init,
//      "destroy": destroy,
//
//      "onSelectedRangesChanged": new Slick.Event()
//    });
