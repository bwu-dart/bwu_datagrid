library bwu_datagrid.plugins.cell_range_selector;

import 'dart:html' as dom;
import 'dart:async' as async;
import 'dart:math' as math;

import 'package:bwu_datagrid/plugins/cell_range_decorator.dart';
import 'package:bwu_datagrid/core/core.dart';
import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

class CellRangeSelector extends Plugin {

  BwuDatagrid _grid;
  dom.HtmlElement _canvas;
  bool _dragging = false;
  Decorator _decorator;
  //var _handler = new Slick.EventHandler();
  math.Point<int> _canvasOrigin;
  Range _range;
  dom.HtmlElement _dummyProxy;

  core.EventBus get eventBus => _eventBus;
  core.EventBus _eventBus = new core.EventBus();

  CellRangeDecoratorOptions _options;

  CellRangeSelector([CellRangeDecoratorOptions options]) {
    if(options != null) {
      _options = options;
    } else {
      _options = new CellRangeDecoratorOptions(selectionCss: {
        'border': '2px dashed blue', 'z-index': '9999'
      });
    }
  }

  var _subscriptions = <async.StreamSubscription>[];

  void init(BwuDatagrid grid) {
    // TODO options = $.extend(true, {}, _defaults, options);
    _decorator = new CellRangeDecorator(grid, options: _options);
    _grid = grid;
    _canvas = _grid.getCanvasNode;
    _canvas.attributes['draggable']='true';

    _subscriptions.add(_grid.onBwuDragStart.listen(_handleDragStart));
    _subscriptions.add(_grid.onBwuDrag.listen(_handleDrag));
    _subscriptions.add(_grid.onBwuDragEnd.listen(_handleDragEnd));

    _dummyProxy = new dom.DivElement()
      ..style.width = '0'
      ..style.height = '0';
    _canvas.append(_dummyProxy);

  }

  void destroy() {

    _subscriptions.forEach((e) => e.cancel());
  }

//  void handleDragInit(DragInit e) {
//    // prevent the grid from cancelling drag'n'drop by default
//    e.stopImmediatePropagation();
//  }

  dom.HtmlElement _handleDragStart(DragStart e) {
    if(e.isImmediatePropagationStopped || isSuspended) return null;

    var cell = _grid.getCellFromEvent(e.causedBy);
    if (eventBus.fire(core.Events.BEFORE_CELL_RANGE_SELECTED, new core.BeforeCellRangeSelected(this, cell)).retVal) {
      if (_grid.canCellBeSelected(cell.row, cell.cell)) {
        _dragging = true;
        e.stopImmediatePropagation();
      }
    }
    if (!_dragging) {
      e.preventDefault();
      return null;
    }

    _grid.setFocus();

    var canvasBounds = _canvas.getBoundingClientRect();
    _canvasOrigin = new math.Point(canvasBounds.left.round(), canvasBounds.top.round());
    e.causedBy.dataTransfer.setDragImage(_dummyProxy, 0, 0);


    var start = _grid.getCellFromPoint(
        e.causedBy.client.x - _canvasOrigin.x,
        e.causedBy.client.y - _canvasOrigin.y);

    _range = new Range(start.row, start.cell);

    return _decorator.show(_range);
  }

  void _handleDrag(Drag e) {
    if (!_dragging) {
      return;
    }
    e.preventDefault();

    var end = _grid.getCellFromPoint(
        e.causedBy.page.x - _canvasOrigin.x,
        e.causedBy.page.y - _canvasOrigin.y);

    if (!_grid.canCellBeSelected(end.row, end.cell)) {
      return;
    }

    _range
      ..toCell = end.cell
      ..toRow = end.row;

    _decorator.show(_range);
  }

  void _handleDragEnd(DragEnd e) {
    if (_dragging == null || !_dragging) {
      return;
    }

    _dragging = false;
    e.preventDefault();

    _decorator.hide();
    eventBus.fire(core.Events.CELL_RANGE_SELECTED, new core.CellRangeSelected(this, _range));
  }

  async.Stream<core.BeforeCellRangeSelected> get onBwuBeforeCellRangeSelected =>
      _eventBus.onEvent(core.Events.BEFORE_CELL_RANGE_SELECTED);

  async.Stream<core.CellRangeSelected> get onBwuCellRangeSelected =>
      _eventBus.onEvent(core.Events.CELL_RANGE_SELECTED);
}

//    $.extend(this, {
//      "init": init,
//      "destroy": destroy,
//
//      "onBeforeCellRangeSelected": new Slick.Event(),
//      "onCellRangeSelected": new Slick.Event()
//    });
