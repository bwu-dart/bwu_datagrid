@HtmlImport('app_element.html')
library app_element;

import 'dart:math' as math;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  List<Column> columns = [
    new Column(id: "title", name: "Title", field: "title"),
    new Column(id: "duration", name: "Duration", field: "duration"),
    new Column(id: "%", name: "% Complete", field: "percentComplete"),
    new Column(id: "start", name: "Start", field: "start"),
    new Column(id: "finish", name: "Finish", field: "finish"),
    new Column(
        id: "effort-driven", name: "Effort Driven", field: "effortDriven")
  ];

  final GridOptions gridOptions = new GridOptions(
      editable: false,
      enableAddRow: false,
      enableCellNavigation: false,
      autoHeight: true);

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

      for (int i = 1; i <= 100; i++) {
        data.items.add(new MapDataItem({
          'title': 'Task ${i}',
          'duration': '5 days',
          'percentComplete': rnd.nextInt(100),
          'start': '01/01/2009',
          'finish': '01/05/2009',
          'effortDriven': (i % 5 == 0)
        }));
      }

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
