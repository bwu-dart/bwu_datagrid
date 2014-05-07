library app_element;

import 'dart:math' as math;
import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/plugins/bwu_auto_tooltips.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
    new Column(id: "title", name: "Title", field: "title"),
    new Column(id: "duration", name: "Duration", field: "duration"),
    new Column(id: "%", name: "% Complete", field: "percentComplete"),
    new Column(id: "start", name: "Start", field: "start"),
    new Column(id: "finish", name: "Finish", field: "finish"),
    new Column(id: "effort-driven", name: "Effort Driven", field: "effortDriven")
  ];

  var options = new GridOptions(
    enableCellNavigation: true,
    enableColumnReorder: false
  );

  @override
  void enteredView() {
    super.enteredView();
    grid = $['myGrid'];

    var data = [];
    for (var i = 0; i < 500; i++) {
      data[i] = {
        'title': "Task " + i,
        'duration': "5 days",
        'percentComplete': new math.Random().nextInt(100).round(),
        'start': "01/01/2009",
        'finish': "01/05/2009",
        'effortDriven': (i % 5 == 0)
      };
    }

    //grid = new Slick.Grid("#myGrid", data, columns, options);
    grid.data = data;
    grid.columns = columns;
    grid.gridOptions = options;
    grid.registerPlugin(new AutoTooltips(new AutoTooltipsOptions(enableForHeaderCells: true)));
    grid.render();
  }
}