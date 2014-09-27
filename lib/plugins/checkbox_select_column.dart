library bwu_dart.bwu_datagrid.checkbox_select_column;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/formatters/formatters.dart';
import 'package:bwu_datagrid/plugins/plugin.dart';


class CheckboxSelectionFormatter extends Formatter {
  final CheckboxSelectColumn selectColumn;
  CheckboxSelectionFormatter(this.selectColumn) {
    assert(selectColumn != null);
  }

  /// The added element (click target) must have the `selectColumn` attribute set
  /// to be recognized by the [CheckboxSelectColumn] click handler.
  @override
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    target.children.clear();

    if (dataContext != null) {
      target.append(new dom.CheckboxInputElement()
        ..checked = selectColumn.isRowSelected(row)
        ..attributes['selectColumn']='true');
    }
  }
}


class CheckboxSelectColumn extends Column implements Plugin {

  bool isSuspended;
  BwuDatagrid _grid;
  BwuDatagrid get grid => _grid;

  //var _handler = new Slick.EventHandler();
  List<async.StreamSubscription> _subscriptions = [];
  Map<int,bool> selectedRowsLookup = {};
  CheckboxSelectColumn({String id: '_checkbox_selector', String cssClass,
                       toolTip: 'Select/Deselect All', int width: 30})
  : super(id: id, cssClass: cssClass, toolTip: toolTip, width: width,
      name: 'Column selector', nameElement: new dom.CheckboxInputElement() , field: 'sel', resizable: false,
      sortable: false) {
    if(formatter != null) {
      this.formatter = formatter;
    } else {
      this.formatter = new CheckboxSelectionFormatter(this);
    }
  }

  void init(BwuDatagrid grid) {
    _grid = grid;

    _subscriptions
      ..add(_grid.onBwuSelectedRowsChanged.listen(handleSelectedRowsChanged))
      ..add(_grid.onBwuClick.listen(handleClick))
      ..add(_grid.onBwuHeaderClick.listen(handleHeaderClick))
      ..add(_grid.onBwuKeyDown.listen(handleKeyDown));
  }

  void destroy() {
    //_handler.unsubscribeAll();
    _subscriptions.forEach((e) => e.cancel());
  }

  void handleSelectedRowsChanged(core.SelectedRowsChanged e) {
    List<int> selectedRows = _grid.getSelectedRows();
    Map lookup = {};
    int row;
    for (int i = 0; i < selectedRows.length; i++) {
      row = selectedRows[i];
      lookup[row] = true;
      if (lookup[row] != selectedRowsLookup[row]) {
        _grid.invalidateRow(row);
        selectedRowsLookup.remove(row);
      }
    }
    for (final i in selectedRowsLookup.keys) {
      _grid.invalidateRow(i);
    }
    selectedRowsLookup = lookup;
    //(formatter as CheckboxSelectionFormatter)._selectedRowsLookup = _selectedRowsLookup;
    _grid.render();

    if (selectedRows.length > 0 && selectedRows.length == _grid.getDataLength) {
      _grid.updateColumnHeader(id, null, toolTip, nameElement: new dom.CheckboxInputElement()..checked = true);
    } else {
      _grid.updateColumnHeader(id, null, toolTip, nameElement: new dom.CheckboxInputElement());
    }
  }

  void handleKeyDown(core.KeyDown e) {
    if (e.causedBy.which == 32) {
      if (_grid.getColumns[e.cell.cell].id == id) {
        // if editing, try to commit
        if (!_grid.getEditorLock.isActive || _grid.getEditorLock.commitCurrentEdit()) {
          toggleRowSelection(e.cell.row);
        }
        e.preventDefault();
        e.stopImmediatePropagation();
      }
    }
  }

  void handleClick(core.Click e) {
    // clicking on a row select checkbox
    if (_grid.getColumns[e.cell.cell].id == id && (e.causedBy.target as dom.Element).attributes.containsKey('selectColumn')) {
      // if editing, try to commit
      if (_grid.getEditorLock.isActive && !_grid.getEditorLock.commitCurrentEdit()) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return;
      }

      toggleRowSelection(e.cell.row);
      e.stopPropagation();
      e.stopImmediatePropagation();
    }
  }

  void toggleRowSelection(int row) {
    if (selectedRowsLookup.containsKey(row)) {
      _grid.setSelectedRows(_grid.getSelectedRows()..remove(row));
    } else {
      _grid.setSelectedRows(_grid.getSelectedRows()..add(row));
    }
  }

  /// Check whether the [row] is currently selected.
  bool isRowSelected(int row) {
    return selectedRowsLookup.containsKey(row);
  }

  void handleHeaderClick(core.HeaderClick e) {
    if (e.column.id == id && e.causedBy.target is dom.CheckboxInputElement) {
      // if editing, try to commit
      if (_grid.getEditorLock.isActive && !_grid.getEditorLock.commitCurrentEdit()) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return;
      }

      if ((e.causedBy.target as dom.CheckboxInputElement).checked) {
        var rows = [];
        for (var i = 0; i < _grid.getDataLength; i++) {
          rows.add(i);
        }
        _grid.setSelectedRows(rows);
      } else {
        _grid.setSelectedRows([]);
      }
      e.stopPropagation();
      e.stopImmediatePropagation();
    }
  }
}
