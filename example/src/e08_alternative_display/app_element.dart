library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;

import 'row_item.dart';

class CellFormatter extends fm.Formatter {
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    target.children.clear();

    target.append((new dom.Element.tag('row-item') as RowItem)..data = dataContext);
  }
}

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  List<Column> columns = [
    new Column(id: "contact-card", name: "Contacts", formatter: new CellFormatter(), width: 500, cssClass: "contact-card-cell")
  ];

  var gridOptions = new GridOptions(
      rowHeight: 140,
      editable: false,
      enableAddRow: false,
      enableCellNavigation: false,
      enableColumnReorder: false
  );

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
      for (int i = 0; i < 100; i++) {
        data.items.add(new MapDataItem({
          'name': 'User ${i}',
          'email': 'test.user@nospam.org',
          'title': 'Regional sales manager',
          'phone': '206-000-0000'
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
