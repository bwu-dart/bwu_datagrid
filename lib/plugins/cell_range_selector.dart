library bwu_datagrid.plugins.cell_range_selector;

import 'dart:html' as dom;
import 'dart:async' as async;
import 'dart:math' as math;

import 'package:bwu_datagrid/plugins/cell_range_decorator.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

class CellRangeSelector extends Plugin {
  BwuDatagrid _grid;
  dom.Element _canvas;
  bool _dragging = false;
  Decorator _decorator;
  //var _handler = new Slick.EventHandler();
  math.Point<int> _canvasOrigin;
  core.Range _range;
  dom.Element _dummyProxy;

  core.EventBus<core.EventData> get eventBus => _eventBus;
  core.EventBus<core.EventData> _eventBus = new core.EventBus<core.EventData>();

  CellRangeDecoratorOptions _options;

  CellRangeSelector([CellRangeDecoratorOptions options]) {
    if (options != null) {
      _options = options;
    } else {
      _options = new CellRangeDecoratorOptions(selectionCss: <String, String>{
        'border': '2px dashed blue',
        'z-index': '9999'
      });
    }
  }

  final List<async.StreamSubscription<core.EventData>> _subscriptions =
      <async.StreamSubscription<core.EventData>>[];

  @override
  void init(BwuDatagrid grid) {
    // TODO options = $.extend(true, {}, _defaults, options);
    _decorator = new CellRangeDecorator(grid, options: _options);
    _grid = grid;
    _canvas = _grid.getCanvasNode;
    _canvas.attributes['draggable'] = 'true';

    _subscriptions.add(_grid.onBwuDragStart.listen(_handleDragStart));
    _subscriptions.add(_grid.onBwuDrag.listen(_handleDrag));
    _subscriptions.add(_grid.onBwuDragEnd.listen(_handleDragEnd));

    _dummyProxy = new dom.DivElement()
      ..style.width = '0'
      ..style.height = '0';
    _canvas.append(_dummyProxy);
  }

  @override
  void destroy() {
    _subscriptions
        .forEach((async.StreamSubscription<core.EventData> e) => e.cancel());
  }

//  void handleDragInit(DragInit e) {
//    // prevent the grid from cancelling drag'n'drop by default
//    e.stopImmediatePropagation();
//  }

  dom.Element _handleDragStart(core.DragStart e) {
    if (e.isImmediatePropagationStopped || isSuspended) return null;

    Cell cell = _grid.getCellFromEvent(e.causedBy);
    if (eventBus
        .fire(core.Events.beforeCellRangeSelected,
            new core.BeforeCellRangeSelected(this, cell))
        .retVal) {
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

    dom.Rectangle<num> canvasBounds = _canvas.getBoundingClientRect();
    _canvasOrigin = new math.Point<int>(
        canvasBounds.left.round(), canvasBounds.top.round());
    e.causedBy.dataTransfer.setDragImage(_dummyProxy, 0, 0);

    Cell start = _grid.getCellFromPoint(e.causedBy.client.x - _canvasOrigin.x,
        e.causedBy.client.y - _canvasOrigin.y);

    _range = new core.Range(start.row, start.cell);

    return _decorator.show(_range);
  }

  void _handleDrag(core.Drag e) {
    if (!_dragging) {
      return;
    }
    e.preventDefault();

    final Cell end = _grid.getCellFromPoint(e.causedBy.page.x - _canvasOrigin.x,
        e.causedBy.page.y - _canvasOrigin.y);

    if (!_grid.canCellBeSelected(end.row, end.cell)) {
      return;
    }

    _range
      ..toCell = end.cell
      ..toRow = end.row;

    _decorator.show(_range);
  }

  void _handleDragEnd(core.DragEnd e) {
    if (_dragging == null || !_dragging) {
      return;
    }

    _dragging = false;
    e.preventDefault();

    _decorator.hide();
    eventBus.fire(core.Events.cellRangeSelected,
        new core.CellRangeSelected(this, _range));
  }

  async.Stream<core.BeforeCellRangeSelected> get onBwuBeforeCellRangeSelected =>
      _eventBus.onEvent(core.Events.beforeCellRangeSelected);

  async.Stream<core.CellRangeSelected> get onBwuCellRangeSelected =>
      _eventBus.onEvent(core.Events.cellRangeSelected);
}

//    $.extend(this, {
//      "init": init,
//      "destroy": destroy,
//
//      "onBeforeCellRangeSelected": new Slick.Event(),
//      "onCellRangeSelected": new Slick.Event()
//    });
