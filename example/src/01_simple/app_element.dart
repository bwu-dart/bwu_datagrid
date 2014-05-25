library app_element;

import 'dart:math' as math;
import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
    new Column(id: 'title', name: 'Title', field: 'title'),
    new Column(id: 'duration', name: 'Duration', field: 'duration'),
    new Column(id: '%', name: '% Complete', field: 'percentComplete'),
    new Column(id: 'start', name: 'Start', field: 'start'),
    new Column(id: 'finish', name: 'Finish', field: 'finish'),
    new Column(id: 'effort-driven', name: 'Effort Driven', field: 'effortDriven')
  ];

  var gridOptions = new GridOptions(
    enableCellNavigation: true,
    enableColumnReorder: false
  );

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      var data = new MapDataItemProvider(); //List<Map>(500);
      for (var i = 0; i < 500; i++) {
        data.items.add(new MapDataItem({
          'title': 'Task ${i}',
          'duration': '5 days',
          'percentComplete': new math.Random().nextInt(100).round(),
          'start': '01/01/2009',
          'finish': '01/05/2009',
          'effortDriven': (i % 5 == 0)
        }));
      }

      grid.setup(dataProvider: data, columns: columns, gridOptions: gridOptions);

    } on NoSuchMethodError catch (e) {
      print('$e\n\n${e.stackTrace}');
    }  on RangeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on TypeError catch(e) {
      print('$e\n\n${e.stackTrace}');
    } catch(e) {
      print('$e');
    }
  }
}