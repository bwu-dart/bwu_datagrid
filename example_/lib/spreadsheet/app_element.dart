@HtmlImport('app_element.html')
library app_element;

import 'dart:math' as math;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/components/bwu_column_picker/bwu_column_picker.dart';
import 'package:bwu_datagrid/plugins/cell_selection_model.dart';
import 'package:bwu_datagrid/plugins/bwu_auto_tooltips.dart';
import 'package:bwu_datagrid/plugins/cell_copymanager.dart';

import 'package:bwu_datagrid_examples/asset/example_style.dart';
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

import 'formula_editor.dart';

/// Silence analyzer [exampleStyleSilence], [OptionsPanel]
/// Silence analyzer [BwuColumnPicker]
@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  final List<Column> columns = <Column>[
    new Column(id: "selector", name: "", field: "num", width: 30)
  ];

  final GridOptions gridOptions = new GridOptions(
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      autoEdit: false);

  math.Random rnd = new math.Random();

  BwuDatagrid grid;
  MapDataItemProvider data;

  String numToChars(int i) {
    String result = '';
    if (i >= 26) {
      result = '${numToChars(i ~/ 26 - 1)}${numToChars(i % 26)}';
    } else {
      result = '${new String.fromCharCode('A'.codeUnits[0] + i)}';
    }
    return result;
  }

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      FormulaEditor formulaEditor = new FormulaEditor();

      for (int i = 0; i < 100; i++) {
        columns.add(new Column(
            id: i.toString(),
            name: numToChars(i),
            field: i.toString(),
            width: 60,
            editor: formulaEditor));
      }

      // prepare the data
      data = new MapDataItemProvider();
      for (int i = 0; i < 100; i++) {
        data.items.add(new MapDataItem({'num': i,}));
      }

      grid
          .setup(dataProvider: data, columns: columns, gridOptions: gridOptions)
          .then((_) {
        grid.setSelectionModel = (new CellSelectionModel());
        grid.registerPlugin(new AutoTooltips());

        // set keyboard focus on the grid
        grid.getCanvasNode.focus();

        CellCopyManager copyManager = new CellCopyManager();
        grid.registerPlugin(copyManager);

        copyManager.onBwuPasteCells.listen((core.PasteCells e) {
          if (e.from.length != 1 || e.to.length != 1) {
            throw "This implementation only supports single range copy and paste operations";
          }

          final Range from = e.from[0];
          final Range to = e.to[0];
          Object val;
          for (int i = 0; i <= from.toRow - from.fromRow; i++) {
            for (int j = 0; j <= from.toCell - from.fromCell; j++) {
              if (i <= to.toRow - to.fromRow && j <= to.toCell - to.fromCell) {
                val = data.items[from.fromRow + i]
                    [columns[from.fromCell + j].field];
                data.items[to.fromRow + i]
                    [columns[to.fromCell + j].field] = val;
                grid.invalidateRow(to.fromRow + i);
              }
            }
          }
          grid.render();
        });

        grid.onBwuAddNewRow.listen((core.AddNewRow e) {
          final DataItem item = e.item;
          grid.invalidateRow(data.length);
          data.items.add(item);
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
}
