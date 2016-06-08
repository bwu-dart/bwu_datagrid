@HtmlImport('app_element.html')
library app_element;

import 'dart:math' as math;
import 'dart:html' as dom;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/editors/editors.dart' as editors;
import 'package:bwu_datagrid/plugins/checkbox_select_column.dart';
import 'package:bwu_datagrid/plugins/row_selection_model.dart';
import 'package:bwu_datagrid/components/bwu_column_picker/bwu_column_picker.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/asset/example_style.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/shared/options_panel.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  factory AppElement() => new dom.Element.tag('app-element') as AppElement;

  AppElement.created() : super.created();

  final List<Column> columns = <Column>[];

  final GridOptions gridOptions = new GridOptions(
      editable: true,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      autoEdit: false);

  math.Random rnd = new math.Random();

  BwuDatagrid grid;
  MapDataItemProvider<core.ItemBase> data;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];
      CheckboxSelectColumn checkboxColumn =
          new CheckboxSelectColumn(cssClass: 'bwu-datagrid-cell-checkboxsel');
      columns.add(checkboxColumn);
      for (int i = 0; i < 5; i++) {
        columns.add(new Column(
            id: i.toString(),
            name: new String.fromCharCode('A'.codeUnits[0] + i),
            field: i.toString(),
            width: 100,
            editor: new editors.TextEditor()));
      }

      // prepare the data
      data = new MapDataItemProvider<core.ItemBase>();
      for (int i = 0; i < 100; i++) {
        data.items.add(new MapDataItem<String, dynamic>(
            <String, dynamic>{'id': i, '0': 'Row $i'}));
      }

      grid
          .setup(dataProvider: data, columns: columns, gridOptions: gridOptions)
          .then((_) {
        grid.setSelectionModel = (new RowSelectionModel(
            new RowSelectionModelOptions(selectActiveRow: false)));
        grid.registerPlugin(checkboxColumn);

        final BwuColumnPicker columnPicker = new BwuColumnPicker()
          ..columns = columns
          ..grid = grid;
        dom.document.body.append(columnPicker);
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
