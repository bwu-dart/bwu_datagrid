library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:polymer/polymer.dart';
import 'package:bwu_sparkline/bwu_sparkline.dart';
import 'package:bwu_utils/math/parse_num.dart' as tools;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;

import '../required_field_validator.dart';

class WaitingFormatter extends fm.Formatter {
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    target
        ..children.clear()
        ..appendText('wait...');
  }
}

void renderSparkline(dom.HtmlElement target, int row, DataItem dataContext, Column colDef) {
  var vals = [
    tools.parseNum(dataContext["n1"], onErrorDefault: 0),
    tools.parseNum(dataContext["n2"], onErrorDefault: 0),
    tools.parseNum(dataContext["n3"], onErrorDefault: 0),
    tools.parseNum(dataContext["n4"], onErrorDefault: 0),
    tools.parseNum(dataContext["n5"], onErrorDefault: 0)
  ];

  target
    ..children.clear()
    ..append((new dom.Element.tag('bwu-sparkline') as BwuSparkline)
        ..values = vals
        ..options = (new LineOptions()..width = '100%'));
}

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  List<Column> columns = [
    new Column(id: "title", name: "Title", field: "title", sortable: false, width: 120, cssClass: "cell-title"),
    new Column(id: "n1", name: "1", field: "n1", sortable: false, editor: new IntegerEditor(), width: 40, validator: new RequiredFieldValidator()),
    new Column(id: "n2", name: "2", field: "n2", sortable: false, editor: new IntegerEditor(), width: 40, validator: new RequiredFieldValidator()),
    new Column(id: "n3", name: "3", field: "n3", sortable: false, editor: new IntegerEditor(), width: 40, validator: new RequiredFieldValidator()),
    new Column(id: "n4", name: "4", field: "n4", sortable: false, editor: new IntegerEditor(), width: 40, validator: new RequiredFieldValidator()),
    new Column(id: "n5", name: "5", field: "n5", sortable: false, editor: new IntegerEditor(), width: 40, validator: new RequiredFieldValidator()),
    new Column(id: "chart", name: "Chart", sortable: false, width: 60, formatter: new WaitingFormatter(), rerenderOnResize: true, asyncPostRender: renderSparkline)
    ];

  var gridOptions = new GridOptions(
    editable: true,
    enableAddRow: false,
    enableCellNavigation: true,
    asyncEditorLoading: false,
    enableAsyncPostRender: true
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
      for (var i = 0; i < 500; i++) {
        data.items.add(new MapDataItem({
          'title' : 'Record $i',
          'n1' : rnd.nextInt(10),
          'n2' : rnd.nextInt(10),
          'n3' : rnd.nextInt(10),
          'n4' : rnd.nextInt(10),
          'n5' : rnd.nextInt(10),
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
