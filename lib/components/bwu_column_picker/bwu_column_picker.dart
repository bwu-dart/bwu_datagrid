@HtmlImport('bwu_column_picker.html')
library bwu_datagrid.components.bwu_column_picker;

import 'dart:html' as dom;
import 'dart:async' show Completer, Future, StreamSubscription;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart';

class CbData extends JsProxy {
  @reflectable String id;
  @reflectable bool checked;
  @reflectable String text;
  CbData(this.id);
}

class ColumnPickerOptions {
  int fadeSpeed;

  ColumnPickerOptions({this.fadeSpeed: 250});
}

@PolymerRegister('bwu-column-picker')
class BwuColumnPicker extends PolymerElement {
  factory BwuColumnPicker() =>
      new dom.Element.tag('bwu-column-picker') as BwuColumnPicker;

  BwuColumnPicker.created() : super.created();

  ColumnPickerOptions _options = new ColumnPickerOptions();
  BwuDatagrid _grid;
  List<Column> _columns;

  @property List columnCheckboxes = [];
  @Property(observer: 'syncResizeChangedHandler') bool isSyncResize = false;
  @Property(observer: 'autoResizeChangedHandler') bool isAutoResize = false;

  bool _isInitialized = false;

  List<StreamSubscription> _subscriptions = [];

  void set columns(List<Column> columns) {
    if (_isInitialized) {
      throw '"columns" must not be updated after the control was added to the DOM.';
    }
    _columns = columns;
  }

  void set options(ColumnPickerOptions options) {
    if (_isInitialized) {
      throw '"options" must not be updated after the control was added to the DOM.';
    }
    _options = options;
  }

  void set grid(BwuDatagrid grid) {
    if (_isInitialized) {
      throw '"grid" must not be updated after the control was added to the DOM.';
    }
    _grid = grid;
    // breaks in Firefox when called synchronuously after
    // `new BwuColumnPicker()`
    async(() {
      set('isSyncResize', _grid.getGridOptions.syncColumnCellResize);
      set('isAutoResize', _grid.getGridOptions.forceFitColumns);
    });
  }

  @reflectable
  void syncResizeChangedHandler(bool checked, [_]) {
    if (_grid == null) {
      return;
    }
    _grid.setGridOptions = new GridOptions.unitialized()
      ..syncColumnCellResize = checked;
  }

  @reflectable
  void autoResizeChangedHandler(bool checked, [_]) {
    if (_grid == null) {
      return;
    }
    _grid.setGridOptions = new GridOptions.unitialized()
      ..forceFitColumns = checked;
    if (checked) {
      _grid.autosizeColumns();
    }
  }

  @override
  void attached() {
    super.attached();
    _subscriptions
        .add(_grid.onBwuHeaderContextMenu.listen(_handleHeaderContextMenu));
    _subscriptions.add(_grid.onBwuColumnsReordered.listen(_updateColumnOrder));

    _isInitialized = true;
  }

  void detached() {
    super.detached();

    _subscriptions.forEach((StreamSubscription e) => e.cancel());
    remove();
  }

  void _handleHeaderContextMenu(HeaderContextMenu e) {
    clear('columnCheckboxes');
    _updateColumnOrder();

    for (int i = 0; i < _columns.length; i++) {
      CbData cb = new CbData(_columns[i].id);

      cb.checked = _grid.getColumnIndex(_columns[i].id) != null;
      cb.text = _columns[i].name;
      add('columnCheckboxes', cb);
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
    final List<Column> current =
        new List<Column>.from(_grid.getColumns); //.slice(0);
    final List<Column> ordered = new List<Column>(_columns.length);
    for (int i = 0; i < ordered.length; i++) {
      if (_grid.getColumnIndex(_columns[i].id) == null) {
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

  @Observe('columnCheckboxes.*')
  void updateColumn(Map e) {
    if (!(e['path'] as String).endsWith('.checked')) {
      return;
    }
    if (_grid == null ||
        e['path'] == 'columnCheckboxes.splices' ||
        e['path'] == 'columnCheckboxes.length') {
      return;
    }

    final List<Column> visibleColumns = <Column>[];
    for (final CbData cbData in columnCheckboxes) {
      if (cbData.checked) {
        visibleColumns
            .add(_columns.firstWhere((Column c) => c.id == cbData.id));
      }
    }

    if (visibleColumns.length == 0) {
      set(e['path'], true);
      return;
    }

    _grid.setColumns = visibleColumns;
    _grid.setSelectedRows(_grid.getSelectedRows());
  }

  List<Column> getAllColumns() {
    return _columns;
  }

  void fadeIn(int milliseconds) {
    style.display = 'block';
    style.transition = 'opacity ${milliseconds}ms ease-in';
    new Future(() => style.opacity = '1');
    onMouseLeave.first.then((dom.MouseEvent e) => fadeOut(_options.fadeSpeed));
  }

  void fadeOut(int milliseconds) {
    style.transition = 'opacity ${milliseconds}ms ease-out';
    new Future(() => style.opacity = '0');
    this
        .onTransitionEnd
        .first
        .then((dom.TransitionEvent e) => style.display = 'none');
  }
}
