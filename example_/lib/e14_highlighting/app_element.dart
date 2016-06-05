@HtmlImport('app_element.html')
library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
// ignore: unused_import
import 'package:bwu_datagrid_examples/asset/example_style.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

class CpuUtilizationFormatter extends fm.CellFormatter {
  @override
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase dataContext) {
    if (value != null && value > 90) {
      target.children.clear();
      target.append(new dom.SpanElement()
        ..classes.add('load-hi')
        ..text = '${value}%');
    } else if (value != null && value > 70) {
      target.children.clear();
      target.append(new dom.SpanElement()
        ..classes.add('load-medium')
        ..text = '${value}%');
    } else {
      target.children.clear();
      target.text = value != null ? '${value}%' : '0%';
    }
  }
}

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  final List<Column> columns = <Column>[
    new Column(id: "server", name: "Server", field: "server", width: 180),
  ];

  final GridOptions gridOptions = new GridOptions(
      editable: false,
      enableAddRow: false,
      enableCellNavigation: true,
      cellHighlightCssClass: 'changed',
      cellFlashingCssClass: 'current-server');

  MapDataItemProvider<core.ItemBase> data;
  math.Random rnd = new math.Random();

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      for (int i = 0; i < 4; i++) {
        columns.add(new Column(
            id: 'cpu${i}',
            name: 'CPU${i}',
            field: 'cpu${i}',
            width: 80,
            formatter: new CpuUtilizationFormatter()));
      }

      data = new MapDataItemProvider<core.ItemBase>();
      for (int i = 0; i < 500; i++) {
        final MapDataItem item =
            new MapDataItem(<String, dynamic>{'server': 'Server ${i}',});
        data.items.add(item);

        for (int j = 0; j < 4; j++) {
          item['cpu${j}'] = rnd.nextInt(100);
        }
      }

      grid.setup(
          dataProvider: data, columns: columns, gridOptions: gridOptions);

      currentServer = (rnd.nextDouble() * (data.length - 1)).round();
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

  int currentServer;

  @reflectable
  void simulateRealTimeUpdates([_, __]) {
    final Map<int, Map<String, String>> changes = <int, Map<String, String>>{};
    int numberOfUpdates = (rnd.nextDouble() * (data.length / 10)).round();

    for (int i = 0; i < numberOfUpdates; i++) {
      final int server = rnd.nextInt(data.length - 1);
      final int cpu = rnd.nextInt(columns.length - 1);
      final int delta = rnd.nextInt(50) - 25;
      //var col = grid.getColumnIndex('cpu${cpu}');
      //print('col: ${col}');
      int val = data.items[server]['cpu${cpu}'] + delta;
      val = math.max/*<int>*/(0, val);
      val = math.min(100, val);

      data.items[server]['cpu${cpu}'] = val;

      if (!changes.containsKey(server)) {
        changes[server] = <String, String>{};
      }

      changes[server]['cpu${cpu}'] = 'changed';

      grid.invalidateRow(server);
    }

    grid.setCellCssStyles('highlight', changes);
    grid.render();

    new async.Future<Null>.delayed(
        new Duration(milliseconds: 500), () => simulateRealTimeUpdates());
  }

  @reflectable
  void findCurrentServer([_, __]) {
    grid.scrollRowIntoView(currentServer);
    grid.flashCell(currentServer, grid.getColumnIndex("server"), 100);
  }
}
