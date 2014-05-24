library bwu_datagrid.plugins.cell_rang_selector;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/plugins/cell_range_decorator.dart';
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

class CellRangeSelector extends Plugin {


  BwuDatagrid _grid;
  dom.HtmlElement _canvas;
  bool _dragging;
  Decorator _decorator;
  //var _handler = new Slick.EventHandler();
  Map _defaults = {
    'selectionCss': {
      "border": "2px dashed blue"
    }
  };
  CellRangeDecoratorOptions _options;

  CellRangeSelector(this._options);

  var _subscriptions = <async.StreamSubscription>[];

  void init(BwuDatagrid grid) {
    // TODO options = $.extend(true, {}, _defaults, options);
    _decorator = new CellRangeDecorator(grid, _options);
    _grid = grid;
    _canvas = _grid.getCanvasNode;
    _subscriptions.add(_grid.onBwuDragInit.listen(handleDragInit));
    _subscriptions.add(_grid.onBwuDragStart.listen(handleDragStart));
    _subscriptions.add(_grid.onBwuDrag.listen(handleDrag));
    _subscriptions.add(_grid.onBwuDragEnd.listen(handleDragEnd));
  }

  void destroy() {
    _subscriptions.forEach((e) => e.cancel());
  }

  void handleDragInit(DragInit e) {
    // prevent the grid from cancelling drag'n'drop by default
    e.stopImmediatePropagation();
  }

  dom.HtmlElement handleDragStart(DragStart e) {
    var cell = _grid.getCellFromEvent(e.causedBy);
    if (_grid.eventBus.fire(core.Events.BEFORE_CELL_RANGE_SELECTED, new core.BeforeCellRangeSelected(this, cell)) != false) {
      if (_grid.canCellBeSelected(cell.row, cell.cell)) {
        _dragging = true;
        e.stopImmediatePropagation();
      }
    }
    if (!_dragging) {
      return null;
    }

    _grid.focus();

    var start = _grid.getCellFromPoint(
        e.dd['startX'] - _canvas.offset.left,
        e.dd['startY'] - _canvas.offset.top);

    e.dd['range'] = {'start': start, 'end': {}};

    return _decorator.show(new Range(start.row, start.cell));
  }

  void handleDrag(Drag e) {
    if (!_dragging) {
      return;
    }
    e.stopImmediatePropagation();

    var end = _grid.getCellFromPoint(
        e.causedBy.page.x - _canvas.offset.left,
        e.causedBy.page.y - _canvas.offset.top);

    if (!_grid.canCellBeSelected(end.row, end.cell)) {
      return;
    }

    e.dd['range'].end = end;
    _decorator.show(new Range(e.dd['range'].start.row, e.dd['range'].start.cell, toRow: end.row, toCell: end.cell));
  }

  void handleDragEnd(DragEnd e) {
    if (_dragging == null || !_dragging) {
      return;
    }

    _dragging = false;
    e.stopImmediatePropagation();

    _decorator.hide();
    _grid.eventBus.fire(core.Events.CELL_RANGE_SELECTED, new core.CellRangeSelected(this,
      new Range(
          e.dd['range'].start.row,
          e.dd['range'].start.cell,
          toRow: e.dd['range'].end.row,
          toCell: e.dd['range'].end.cell
      )
    ));
  }
}
//    $.extend(this, {
//      "init": init,
//      "destroy": destroy,
//
//      "onBeforeCellRangeSelected": new Slick.Event(),
//      "onCellRangeSelected": new Slick.Event()
//    });
