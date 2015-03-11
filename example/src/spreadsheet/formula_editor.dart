library bwu_datagrid.example.spreadsheet.formula_editor;

import 'dart:async' as async;

import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/plugins/cell_range_selector.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

class FormulaEditor extends Editor {
  EditorArgs args;
  CellRangeSelector _selector;
  TextEditor _editor; // = new TextEditor();
  async.StreamSubscription _cellRangeSelectedSubscr;

  FormulaEditor newInstance(EditorArgs args) {
    return new FormulaEditor._(args);
  }

  FormulaEditor() : super();

  FormulaEditor._(this.args) {
    grid = args.grid;

    _editor = new TextEditor().newInstance(args);

    // register a plugin to select a range and append it to the textbox
    // since events are fired in reverse order (most recently added are executed first),
    // this will override other plugins like moverows or selection model and will
    // not require the grid to not be in the edit mode
    _selector = new CellRangeSelector();
    _cellRangeSelectedSubscr =
        _selector.onBwuCellRangeSelected.listen(_handleCellRangeSelected);
    grid.registerPlugin(_selector, suspendOthers: true);
  }

  void _handleCellRangeSelected(core.CellRangeSelected e) {
    _editor.value =
        '${_editor.value}${grid.getColumns[e.range.fromCell].name}${e.range.fromRow}:${grid.getColumns[e.range.toCell].name}${e.range.toRow}';
  }

  @override
  void applyValue(DataItem item, value) {
    return _editor.applyValue(item, value);
  }

  @override
  void destroy() {
    if (_cellRangeSelectedSubscr != null) {
      _cellRangeSelectedSubscr.cancel();
      _cellRangeSelectedSubscr = null;
    }
    grid.unregisterPlugin(_selector);
    _editor.destroy();
  }

  @override
  void focus() {
    _editor.focus();
  }

  @override
  bool get isValueChanged => _editor.isValueChanged;

  @override
  void loadValue(DataItem item) {
    return _editor.loadValue(item);
  }

  @override
  serializeValue() {
    return _editor.serializeValue();
  }

  @override
  ValidationResult validate() {
    return _editor.validate();
  }
}
