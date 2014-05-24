library app_element;

import 'dart:math' as math;
import 'dart:html' as dom;
import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;

class Formatter extends fm.Formatter {
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    target.appendHtml(value);
  }
}

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
      new Column(id: "title", name: "Title", field: "title", width: 120, cssClass: "cell-title", formatter: new Formatter()),
      new Column(id: "duration", name: "Duration", field: "duration"),
      new Column(id: "%", name: "% Complete", field: "percentComplete", width: 80, resizable: false, formatter: new fm.PercentCompleteBarFormatter()),
      new Column(id: "start", name: "Start", field: "start", minWidth: 60),
      new Column(id: "finish", name: "Finish", field: "finish", minWidth: 60),
      new Column(id: "effort-driven", name: "Effort Driven", sortable: false, width: 80, minWidth: 20, maxWidth: 80, cssClass: "cell-effort-driven", field: "effortDriven", formatter: new fm.CheckmarkFormatter())
  ];

  var gridOptions = new GridOptions(
    editable: false,
    enableAddRow: false,
    enableCellNavigation: true
  );

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];
      var data = new MapDataItemProvider();
      for (var i = 0; i < 5; i++) {
        data.items.add(new MapDataItem({
          'title': "<a href='#' tabindex='0'>Task</a> ${i}",
          'duration': "5 days",
          'percentComplete': math.min(100, (new math.Random().nextDouble() * 110).round()),
          'start': "01/01/2009",
          'finish': "01/05/2009",
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