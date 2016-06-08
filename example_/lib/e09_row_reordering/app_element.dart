@HtmlImport('app_element.html')
library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/plugins/row_selection_model.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/plugins/row_move_manager.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/asset/example_style.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

// ignore: unused_import
import 'drop_zone.dart';
import 'package:bwu_datagrid_examples/shared/required_field_validator.dart';

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  final List<Column> columns = <Column>[
    new Column(
        id: "#",
        name: "",
        width: 40,
        behavior: <String>["select", 'move'], //AndMove",
        selectable: false,
        resizable: false,
        isDraggable: true,
        cssClass: "cell-reorder dnd"),
    new Column(
        id: "name",
        name: "Name",
        field: "name",
        width: 500,
        cssClass: "cell-title",
        editor: new TextEditor(),
        validator: new RequiredFieldValidator(),
        isDraggable: true,
        behavior: <String>['drag']),
    new Column(
        id: "complete",
        name: "Complete",
        width: 60,
        cssClass: "cell-effort-driven",
        field: "complete",
        cannotTriggerInsert: true,
        formatter: new fm.CheckmarkFormatter(),
        editor: new CheckboxEditor(),
        isDraggable: true,
        behavior: <String>['drag'])
  ];

  final GridOptions gridOptions = new GridOptions(
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      forceFitColumns: true,
      autoEdit: false);

  math.Random rnd = new math.Random();

  BwuDatagrid grid;
  MapDataItemProvider<core.ItemBase> data;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      // prepare the data
      data = new MapDataItemProvider<core.ItemBase>();
      data.items.add(new MapDataItem(
          <String, dynamic>{'name': "Make a list", 'complete': true}));
      data.items.add(new MapDataItem(
          <String, dynamic>{'name': "Check it twice", 'complete': false}));
      data.items.add(new MapDataItem(<String, dynamic>{
        'name': "Find out who's naughty",
        'complete': false
      }));
      data.items.add(new MapDataItem(
          <String, dynamic>{'name': "Find out who's nice", 'complete': false}));

      grid
          .setup(dataProvider: data, columns: columns, gridOptions: gridOptions)
          .then((_) {
        grid.setSelectionModel = new RowSelectionModel();

        final RowMoveManager moveRowsPlugin =
            new RowMoveManager(grid, cancelEditOnDrag: true);

        moveRowsPlugin.onBwuBeforeMoveRows.listen((core.BeforeMoveRows e) {
          for (int i = 0; i < e.rows.length; i++) {
            // no point in moving before or after itself
            if (e.rows[i] == e.insertBefore ||
                e.rows[i] == e.insertBefore - 1) {
              e.retVal = false;
            }
          }
          return;
        });

        moveRowsPlugin.onBwuMoveRows.listen(moveRowsHandler);

        grid.registerPlugin(moveRowsPlugin);

        grid.onBwuDragStart.listen(dragStartHandler);
        grid.onBwuDragEnd.listen(dragEndHandler);

        grid.onBwuDrag.listen((core.Drag e) {
//          print('drag');
          dom.DataTransfer dt = e.causedBy.dataTransfer;
          if (dt.getData('text/bwu-datagrid-recycle') != "recycle") {
            return;
          }
          (dt.getData('helper') as dom.Element)
            ..style.top = '${e.causedBy.page.y + 5}px'
            ..style.left = '${e.causedBy.page.x + 5}px';
        });

        grid.onBwuAddNewRow.listen((core.AddNewRow e) {
          MapDataItem item = new MapDataItem(
              <String, dynamic>{'name': "New task", 'complete': false});
          //$.extend(item, args.item);
          data.items.add(item);
          grid.invalidateRows(<int>[data.length - 1]);
          grid.updateRowCount();
          grid.render();
        });
      });
    } on NoSuchMethodError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on RangeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on TypeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } catch (e) {
      print('$e');
    }
  }

  @reflectable
  void zoneDropHandler(CustomEventWrapper e, [_]) {
    if ((e.original as dom.MouseEvent)
            .dataTransfer
            .getData('text/bwu-datagrid-recycle') !=
        "recycle") {
      return;
    }

    final List<int> selectedRows = grid.getSelectedRows();

    List<core.ItemBase> rowsToDelete = <core.ItemBase>[];
    selectedRows.forEach((int r) {
      rowsToDelete.add(data.items[r]);
    });
    rowsToDelete.forEach((core.ItemBase r) => data.items.remove(r));

    grid.invalidate();
    grid.setSelectedRows(<int>[]);
  }

  /// Handle rows reordering
  void moveRowsHandler(core.MoveRows e) {
    final List<core.ItemBase> extractedRows = <core.ItemBase>[];
    List<core.ItemBase> left, right;
    List<int> rows = e.rows;
    final int insertBefore = e.insertBefore;
    if (insertBefore < 0) {
      return;
    }
    left = data.items.getRange(0, insertBefore).toList();
    right = data.items.getRange(insertBefore, data.length).toList();

    rows.sort((int a, int b) => a - b);

    for (int i = 0; i < rows.length; i++) {
      extractedRows.add(data.items[rows[i]]);
    }

    rows = rows.reversed.toList();

    for (int i = 0; i < rows.length; i++) {
      final int row = rows[i];
      if (row < insertBefore) {
        left.removeAt(row);
      } else {
        right.removeAt(row - insertBefore);
      }
    }

    data.items = new List<core.ItemBase>()
      ..addAll(left)
      ..addAll(extractedRows)
      ..addAll(right);

    final List<int> selectedRows = <int>[];
    for (int i = 0; i < rows.length; i++) selectedRows.add(left.length + i);

    grid.resetActiveCell();
    grid.setData(data);
    grid.setSelectedRows(selectedRows);
    grid.render();
  }

  dom.SpanElement _dragProxy;

  @reflectable
  void dragEndHandler(core.DragEnd e, [_]) {
    if (_dragProxy != null) {
      _dragProxy.remove();
    }
  }

  /// drag row content (instead of by the handle)
  void dragStartHandler(core.DragStart e) {
    Cell cell = grid.getCellFromEvent(e.causedBy);

    if (cell == null ||
        columns[cell.cell].behavior == null ||
        !columns[cell.cell].behavior.contains('drag')) {
      return;
    }

    Map<dynamic, dynamic> dragData = new Map<dynamic, dynamic>();
    dragData['row'] = cell.row;

    if (cell.row >= data.items.length) {
      return;
    }

    if (core.globalEditorLock.isActive) {
      return;
    }

    e.causedBy.dataTransfer
      ..effectAllowed = 'move'
      ..dropEffect = 'move'
      ..setData('text/bwu-datagrid-recycle', "recycle");

    List<int> selectedRows = grid.getSelectedRows();

    if (selectedRows.length == 0 || !selectedRows.contains(cell.row)) {
      selectedRows = <int>[cell.row];
      grid.setSelectedRows(selectedRows);
    }

    final dom.Rectangle<num> r = grid.getCanvasNode.getBoundingClientRect();

    _dragProxy = new dom.SpanElement()
      ..style.position = "absolute"
      ..style.left = '${r.left}px'
      ..style.top = '${r.top}px'
      ..style.display = "inline-block"
      ..style.padding = "4px 10px"
      ..style.background = "#e0e0e0"
      ..style.border = "1px solid gray"
      ..style.zIndex = '-99999'
      ..style.borderRadius = "8px"
      ..style.boxShadow = "2px 2px 6px silver"
      ..text =
          "Drag to Recycle Bin to delete ${selectedRows.length} selected row(s)";
    dom.document.body.append(_dragProxy);

    e.causedBy.dataTransfer.setDragImage(_dragProxy, 0, 0);
  }
}