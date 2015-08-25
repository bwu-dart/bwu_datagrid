library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  List<Column> columns = [
    new Column(id: "title", name: "Title", field: "title", width: 120),
    new Column(id: "duration", name: "Duration", field: "duration", width: 120),
    new Column(
        id: "%", name: "% Complete", field: "percentComplete", width: 120),
    new Column(id: "start", name: "Start", field: "start", width: 120),
    new Column(id: "finish", name: "Finish", field: "finish", width: 120),
    new Column(
        id: "effort-driven",
        name: "Effort Driven",
        field: "effortDriven",
        width: 120),
    new Column(id: "c7", name: "C7", field: "c7", width: 120),
    new Column(id: "c8", name: "C8", field: "c8", width: 120),
    new Column(id: "c9", name: "C9", field: "c9", width: 120),
    new Column(id: "c10", name: "C10", field: "c10", width: 120),
    new Column(id: "c11", name: "C11", field: "c11", width: 120),
    new Column(id: "c12", name: "C12", field: "c12", width: 120),
    new Column(id: "c13", name: "C13", field: "c13", width: 120),
    new Column(id: "c14", name: "C14", field: "c14", width: 120),
    new Column(id: "c15", name: "C15", field: "c15", width: 120),
    new Column(id: "c16", name: "C16", field: "c16", width: 120),
    new Column(id: "c17", name: "C17", field: "c17", width: 120)
  ];

  var gridOptions =
      new GridOptions(enableCellNavigation: false, enableColumnReorder: false);

  math.Random rnd = new math.Random();

  BwuDatagrid grid;
  MapDataItemProvider data;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      // prepare the data
      data = new MapDataItemProvider();

      for (int i = 1; i <= 10000; i++) {
        data.items.add(new MapDataItem({
          'title': 'Task ${i}',
          'duration': '5 days',
          'percentComplete': rnd.nextInt(100),
          'start': '01/01/2009',
          'finish': '01/05/2009',
          'effortDriven': (i % 5 == 0),
          'c7': 'C7-${i}',
          'c8': 'C8-${i}',
          'c9': 'C9-${i}',
          'c10': 'C10-${i}',
          'c11': 'C11-${i}',
          'c12': 'C12-${i}',
          'c13': 'C13-${i}',
          'c14': 'C14-${i}',
          'c15': 'C15-${i}',
          'c16': 'C16-${i}',
          'c17': 'C17-${i}',
        }));
      }

      dom.window.onResize.listen((e) => grid.resizeCanvas(e));

      grid.setup(
          dataProvider: data, columns: columns, gridOptions: gridOptions);
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
