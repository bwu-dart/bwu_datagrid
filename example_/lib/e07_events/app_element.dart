@HtmlImport('app_element.html')
library app_element;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/editors/editors.dart';

// ignore: unused_import
import 'package:bwu_datagrid_examples/asset/example_style.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

import 'context_menu.dart';

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  final List<Column> columns = <Column>[
    new Column(
        id: "title",
        name: "Title",
        field: "title",
        width: 200,
        cssClass: "cell-title",
        editor: new TextEditor()),
    new Column(
        id: "priority",
        name: "Priority",
        field: "priority",
        width: 80,
        selectable: false,
        resizable: false)
  ];

  final GridOptions gridOptions = new GridOptions(
      editable: true,
      enableAddRow: false,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      rowHeight: 30);

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'] as BwuDatagrid;
      final MapDataItemProvider<core.ItemBase> data =
          new MapDataItemProvider<core.ItemBase>();
      for (int i = 0; i < 500; i++) {
        data.items.add(new MapDataItem(
            <String, String>{'title': 'Task ${i}', 'priority': 'Medium'}));
      }

      grid
          .setup(dataProvider: data, columns: columns, gridOptions: gridOptions)
          .then/*<dynamic>*/((_) {
        // setup context menu handler
        grid.onBwuContextMenu.listen((core.ContextMenu e) {
          e.stopImmediatePropagation();
          e.preventDefault();
          ($['contextMenu'] as ContextMenu)
            ..cell = e.cell
            ..setPosition(e.causedBy.page.x.toInt(), e.causedBy.page.y.toInt())
            ..show();
        });

        // setup context menu select handler
        ($['contextMenu'] as ContextMenu)
            .onContextMenuSelect
            .listen((dom.CustomEvent e) {
          if (!grid.getEditorLock.commitCurrentEdit()) {
            return;
          }
          final Cell cell = ($['contextMenu'] as ContextMenu).cell;
          data.items[cell.row]['priority'] = e.detail;
          grid.updateRow(cell.row);
          ($['contextMenu'] as ContextMenu).hide();
        });

        // setup next value on cell click
        grid.onBwuClick.listen((core.Click e) {
          if (grid.getColumns[e.cell.cell].id == 'priority') {
            if (!grid.getEditorLock.commitCurrentEdit()) {
              return;
            }

            final Map<String, String> states = <String, String>{
              'Low': 'Medium',
              'Medium': 'High',
              'High': 'Low'
            };
            data.items[e.cell.row]['priority'] =
                states[data.items[e.cell.row]['priority']];
            grid.updateRow(e.cell.row);
            e.stopPropagation();
          }
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
