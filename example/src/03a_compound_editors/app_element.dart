library app_element;

import 'dart:math' as math;
import 'dart:html' as dom;
import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart';
import 'numeric_range_editor.dart';


class NumericRangeFormatter extends fm.Formatter {
  @override
  void call(dom.HtmlElement target, int row, int cell, value, Column columnDef, dataContext) {
    target.children.clear();
    target.text = "${dataContext['from']} - ${dataContext['to']}";
  }
}

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
    new Column(id: "title", name: "Title", field: "title", width: 120, cssClass: "cell-title", editor: new TextEditor()),
    new Column(id: "range", name: "Range", width: 120, formatter: new NumericRangeFormatter(), editor: new NumericRangeEditor())
  ];

  var gridOptions = new GridOptions(
      editable: true,
      enableAddRow: false,
      enableCellNavigation: true,
      asyncEditorLoading: false
  );

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];
      var data = new MapDataItemProvider();
      for (var i = 0; i < 500; i++) {
        int from = new math.Random().nextInt(100);
        data.items.add(new MapDataItem({
          'title': 'Task ${i}',
          'from': from,
          'to': from + new math.Random().nextInt(100)
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
