library bwu_datagrid.plugins.row_move_manager;

import 'dart:html' as dom;
import 'dart:async' as async;
import 'dart:math' as math;

import 'package:bwu_datagrid/plugins/plugin.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_utils/bwu_utils_browser.dart' as utils;

class RowMoveManager extends Plugin {
  static const String dragDropId = 'text/bwu-datagrid-row-move';

  bool cancelEditOnDrag = false;

  core.EventBus<core.EventData> get eventBus => _eventBus;
  core.EventBus<core.EventData> _eventBus = new core.EventBus<core.EventData>();

  dom.Element _canvas;
  int _canvasTop;
  bool _dragging = false;
  final List<async.StreamSubscription<core.EventData>> _subscriptions =
      <async.StreamSubscription<core.EventData>>[];

  dom.Element _selectionProxy;
  dom.Element _dummyProxy;
  dom.Element _guide;
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
    _subscriptions
        .forEach((async.StreamSubscription<core.EventData> e) => e.cancel());
  }

  void _handleDragStart(core.DragStart e) {
    Cell cell = grid.getCellFromTarget(e.causedBy.target);

    if (cancelEditOnDrag && grid.getEditorLock.isActive) {
      grid.getEditorLock.cancelCurrentEdit();
    }

    if (cell == null ||
        grid.getColumns[cell.cell] == null ||
        grid.getColumns[cell.cell].behavior == null ||
        grid.getEditorLock.isActive ||
        !(grid.getColumns[cell.cell].behavior.contains('move'))) {
      e.retVal = false;
      return;
    }

    _dragging = true;
    e.causedBy.dataTransfer
      ..effectAllowed = 'move'
      ..dropEffect = 'move'
      ..setData(dragDropId, "move");

    List<int> selectedRows = grid.getSelectedRows();

    if (selectedRows.length == 0 || !selectedRows.contains(cell.row)) {
      selectedRows = [cell.row];
      grid.setSelectedRows(selectedRows);
    }

    final int rowHeight = grid.getGridOptions.rowHeight;
    _canvasTop = _canvas.getBoundingClientRect().top.round();

    _selectedRows = selectedRows;
    e.causedBy.dataTransfer.setDragImage(_dummyProxy, 0, 0);
    _insertBefore = -1;

    // run DOM modification async because modifying the DOM in DragStart
    // causes the browser to fire DragEnd immediately
    new async.Future<Null>.delayed(new Duration(milliseconds: 10), () {
      _selectionProxy = new dom.DivElement()
        ..classes.add('bwu-datagrid-reorder-proxy')
        ..style.position = "absolute"
        ..style.zIndex = "99999"
        ..style.width = '${utils.innerWidth(_canvas)}px'
        ..style.height = '${rowHeight * selectedRows.length}px';
      _canvas.append(_selectionProxy);

      _guide = new dom.DivElement()
        ..classes.add('bwu-datagrid-reorder-guide')
        ..style.position = "absolute"
        ..style.zIndex = "99998"
        ..style.width = '${utils.innerWidth(_canvas)}px'
        ..style.top = '-1000px';
      _canvas.append(_guide);
      print('DragStart done');
    });
  }

  void _handleDrag(core.Drag e) {
    if (!_dragging) {
      return;
    }

    e.preventDefault();

    final int top = e.causedBy.client.y - _canvasTop;

    _selectionProxy.style.top = '${top - 5}px';

    final int insertBefore = math.max(
        0,
        math.min/*<int>*/(
            (top / grid.getGridOptions.rowHeight).round(), grid.getDataLength));
    if (insertBefore != _insertBefore) {
      if (eventBus
              .fire(
                  core.Events.beforeMoveRows,
                  new core.BeforeMoveRows(this,
                      rows: _selectedRows, insertBefore: insertBefore))
              .retVal ==
          false) {
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
      eventBus.fire(
          core.Events.moveRows,
          new core.MoveRows(this,
              rows: _selectedRows, insertBefore: _insertBefore));
    }
  }

  void _handleDragOver(core.DragOver e) {
    if (!_dragging || !e.causedBy.dataTransfer.types.contains(dragDropId)) {
      return;
    }
    e.preventDefault();
  }

  void _handleDrop(core.Drop e) {
    if (!_dragging || !e.causedBy.dataTransfer.types.contains(dragDropId)) {
      return;
    }
    e.preventDefault();
  }

  async.Stream<core.BeforeMoveRows> get onBwuBeforeMoveRows =>
      _eventBus.onEvent(core.Events.beforeMoveRows)
      as async.Stream<core.BeforeMoveRows>;

  async.Stream<core.MoveRows> get onBwuMoveRows =>
      _eventBus.onEvent(core.Events.moveRows) as async.Stream<core.MoveRows>;
}
