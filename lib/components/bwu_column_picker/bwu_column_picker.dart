library bwu_datagrid.compponents.bwu_column_picker;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart';

class CbData {
  String id;
  bool checked;
  String text;
  CbData(this.id);
}

class ColumnPickerOptions {
  int fadeSpeed;

  ColumnPickerOptions({this.fadeSpeed : 250});
}

@CustomTag('bwu-column-picker')
class BwuColumnPicker extends PolymerElement {
  BwuColumnPicker.created() : super.created();

  ColumnPickerOptions _options = new ColumnPickerOptions();
  BwuDatagrid _grid;
  List<Column> _columns;

  @observable List<CbData> columnCheckboxes = toObservable(<CbData>[]);
  @observable bool isSyncResize = false;
  @observable bool isAutoResize = false;

  bool _isInitialized = false;

  List<async.StreamSubscription> _subscriptions;

  void set options(ColumnPickerOptions options) {
    if(_isInitialized) {
      throw '"options" must not be updated after the control was added to the DOM.';
    }
    _options = options;
  }

  void set grid(BwuDatagrid grid) {
    if(_isInitialized) {
      throw '"grid" must not be updated after the control was added to the DOM.';
    }
    _grid = grid;
    isSyncResize = _grid.getGridOptions.syncColumnCellResize;
    isAutoResize = _grid.getGridOptions.forceFitColumns;
  }

// TODO binding to 'checked' of the checkboxes didn't work
//  void isSyncResizeChanged(old) {
//    _grid.setGridOptions = new GridOptions(syncColumnCellResize: isSyncResize);
//  }
//
//  void isautoResizeChanged(old) {
//    _grid.setGridOptions = new GridOptions(forceFitColumns: isAutoResize);
//  }

  void syncResizeChangedHandler(dom.Event e, detail, dom.HtmlElement target) {
    _grid.setGridOptions = new GridOptions.unitialized()..syncColumnCellResize = (target as dom.CheckboxInputElement).checked;
  }

  void autoResizeChangedHandler(dom.Event e, detail, dom.HtmlElement target) {
    var checked = (target as dom.CheckboxInputElement).checked;
    _grid.setGridOptions = new GridOptions.unitialized()..forceFitColumns = checked;
    if(checked) {
      _grid.autosizeColumns();
    }
  }

  void set columns(List<Column> columns) {
    if(_isInitialized) {
      throw '"columns" must not be updated after the control was added to the DOM.';
    }
    _columns = toObservable(columns);
  }

  void attached() {
    super.attached();

    _subscriptions.add(_grid.onBwuHeaderContextMenu.listen(_handleHeaderContextMenu));
    _subscriptions.add(_grid.onBwuColumnsReordered.listen(_updateColumnOrder));
    _subscriptions.add(onClick.listen(_updateColumn));

    _isInitialized = true;
  }

  void detached() {
    super.detached();

    _subscriptions.forEach((e) => e.cancel());
    remove();
  }

  void _handleHeaderContextMenu(HeaderContextMenu e) {
    e.preventDefault();
    columnCheckboxes.clear();
    _updateColumnOrder();


    var $li, $input;
    for (var i = 0; i < _columns.length; i++) {
      CbData cb = new CbData(_columns[i].id);

      cb.checked = _grid.getColumnIndex(_columns[i].id) != null;
      cb.text = _columns[i].name;
      columnCheckboxes.add(cb);
    }

    style
        ..top = '${e.causedBy.page.y - 10}px'
        ..left = '${e.causedBy.page.x - 10}px';

    fadeIn(_options.fadeSpeed);
  }

  void _updateColumnOrder([ColumnsReordered e]) {
    // Because columns can be reordered, we have to update the `columns`
    // to reflect the new order, however we can't just take `grid.getColumns()`,
    // as it does not include columns currently hidden by the picker.
    // We create a new `columns` structure by leaving currently-hidden
    // columns in their original ordinal position and interleaving the results
    // of the current column sort.
    var current = new List<Column>.from(_grid.getColumns); //.slice(0);
    var ordered = new List<Column>(_columns.length);
    for (var i = 0; i < ordered.length; i++) {
      if ( _grid.getColumnIndex(_columns[i].id) == null ) {
        // If the column doesn't return a value from getColumnIndex,
        // it is hidden. Leave it in this position.
        ordered[i] = _columns[i];
      } else {
        // Otherwise, grab the next visible column.
        ordered[i] = current.removeAt(0);
      }
    }
    _columns = ordered;
  }

  void _updateColumn(dom.Event e) {
    var cb = e.target as dom.CheckboxInputElement;
    CbData curCbData;

    var visibleColumns = [];
    for(int i = 0; i < columnCheckboxes.length; i++) {
      var cbData = columnCheckboxes[i];
      if(cbData.id == cb.dataset['column-id']) {
        cbData.checked = cb.checked;
        curCbData = cbData;
      }
      if (cbData.checked) {
        visibleColumns.add(_columns[i]);
      }
    }

    if (visibleColumns.length == 0) {
      curCbData.checked = true;
      cb.checked = true;
      return;
    }

    _grid.setColumns = visibleColumns;
  }

  List<Column> getAllColumns() {
    return _columns;
  }

  void fadeIn(int milliseconds) {
    style.display = 'block';
    style.transition = 'opacity ${milliseconds}ms ease-in';
    new async.Future(() => style.opacity = '1');
    onMouseLeave.first.then((e) => fadeOut(_options.fadeSpeed));
  }

  void fadeOut(int milliseconds) {
    style.transition = 'opacity ${milliseconds}ms ease-out';
    new async.Future(() => style.opacity = '0');
    this.onTransitionEnd.first.then((e) => style.display = 'none');
  }

      //init();

//      return {
//        "getAllColumns": getAllColumns,
//        "destroy": destroy
//      };
}