library bwu_dart.bwu_datagrid.plugin.row_move_manager;

import 'dart:html' as dom;
import 'dart:async' as async;
import 'dart:math' as math;

import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_utils_browser/html/html.dart' as tools;
import 'package:bwu_datagrid/effects/sortable.dart' as sort;

class RowMoveManager extends Plugin {
  static const DRAG_DROP_ID = 'text/bwu-datagrid-row-move';

  bool cancelEditOnDrag = false;

  core.EventBus get eventBus => _eventBus;
  core.EventBus _eventBus = new core.EventBus();

  dom.HtmlElement _canvas;
  int _canvasTop;
  bool _dragging = false;
  List<async.StreamSubscription> _subscriptions = [];

  sort.Sortable _sortable;

  dom.HtmlElement _selectionProxy;
  dom.HtmlElement _dummyProxy;
  dom.HtmlElement _guide;
  bool _canMove = false;
  int _insertBefore;
  List<int> _selectedRows;

  RowMoveManager(BwuDatagrid grid, {this.cancelEditOnDrag}) {
    init(grid);
    _canvas = grid.getCanvasNode;
    _subscriptions.add(grid.onBwuDragStart.listen(_handleDragStart));
    _subscriptions.add(grid.onBwuDrag.listen(_handleDrag));
    _subscriptions.add(grid.onBwuDragEnd.listen(_handleDragEnd));
    _subscriptions.add(grid.onBwuDragOver.listen(_handleDragOver));
    _subscriptions.add(grid.onBwuDrop.listen(_handleDrop));

    _dummyProxy = new dom.DivElement()
      ..style.width = '0'
      ..style.height = '0';
    _canvas.append(_dummyProxy);
  }

  void destroy() {
    _subscriptions.forEach((e) => e.cancel());
  }

  void _handleDragStart(core.DragStart e) {
    var cell = grid.getCellFromTarget(e.causedBy.target);

    if (cancelEditOnDrag && grid.getEditorLock.isActive) {
      grid.getEditorLock.cancelCurrentEdit();
    }

    if(cell == null || grid.getColumns[cell.cell] == null || grid.getColumns[cell.cell].behavior == null ||
        grid.getEditorLock.isActive || !(grid.getColumns[cell.cell].behavior.contains('move'))) {
      e.retVal = false;
      return;
    }

    _dragging = true;
    e.causedBy.dataTransfer
      ..effectAllowed = 'move'
      ..dropEffect = 'move'
      ..setData(DRAG_DROP_ID, "move");

    var selectedRows = grid.getSelectedRows();

    if (selectedRows.length == 0 || !selectedRows.contains(cell.row)) {
      selectedRows = [cell.row];
      grid.setSelectedRows(selectedRows);
    }

    var rowHeight = grid.getGridOptions.rowHeight;
    _canvasTop = _canvas.getBoundingClientRect().top.round();

    _selectedRows = selectedRows;
    e.causedBy.dataTransfer.setDragImage(_dummyProxy, 0, 0);
    _insertBefore = -1;

    // run DOM modification async because modifying the DOM in DragStart
    // causes the browser to fire DragEnd immediately
    new async.Future.delayed(new Duration(milliseconds: 10), () {
      _selectionProxy = new dom.DivElement()
        ..classes.add('bwu-datagrid-reorder-proxy')
        ..style.position = "absolute"
        ..style.zIndex = "99999"
        ..style.width ='${tools.innerWidth(_canvas)}px'
        ..style.height = '${rowHeight * selectedRows.length}px';
      _canvas.append(_selectionProxy);

      _guide = new dom.DivElement()
        ..classes.add('bwu-datagrid-reorder-guide')
        ..style.position = "absolute"
        ..style.zIndex = "99998"
        ..style.width = '${tools.innerWidth(_canvas)}px'
        ..style.top = '-1000px';
      _canvas.append(_guide);
    });
  }

  void _handleDrag(core.Drag e) {
    if (!_dragging) {
      return;
    }

    e.preventDefault();

    var top = e.causedBy.client.y - _canvasTop;

    _selectionProxy.style.top = '${top - 5}px';

    var insertBefore = math.max(0, math.min((top / grid.getGridOptions.rowHeight).round(), grid.getDataLength));
    if (insertBefore != _insertBefore) {
      if (eventBus.fire(core.Events.BEFORE_MOVE_ROWS, new core.BeforeMoveRows(this, rows: _selectedRows, insertBefore: insertBefore)).retVal == false) {
        _guide.style.top = '-1000px';
        _canMove = false;
      } else {
        _guide.style.top = '${insertBefore * grid.getGridOptions.rowHeight}px';
        _canMove = true;
      }
      _insertBefore = insertBefore;
    }
  }

  void _handleDragEnd(core.DragEnd e) {
    if (!_dragging) {
      return;
    }
    _dragging = false;

    _guide.remove();
    _selectionProxy.remove();

    if (_canMove) {
      // TODO:  _grid.remapCellCssClasses ?
      eventBus.fire(core.Events.MOVE_ROWS, new core.MoveRows(this, rows: _selectedRows, insertBefore: _insertBefore));
    }
  }

  void _handleDragOver(core.DragOver e) {
    if (!_dragging || !e.causedBy.dataTransfer.types.contains(DRAG_DROP_ID)) {
      return;
    }
    e.preventDefault();
  }

  void _handleDrop(core.Drop e) {
    if (!_dragging || !e.causedBy.dataTransfer.types.contains(DRAG_DROP_ID)) {
      return;
    }
    e.preventDefault();
  }

  async.Stream<core.BeforeMoveRows> get onBwuBeforeMoveRows =>
      _eventBus.onEvent(core.Events.BEFORE_MOVE_ROWS);

  async.Stream<core.MoveRows> get onBwuMoveRows =>
      _eventBus.onEvent(core.Events.MOVE_ROWS);
}