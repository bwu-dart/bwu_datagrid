library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;

class CpuUtilizationFormatter extends fm.Formatter {
  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    if (value != null && value > 90) {
      target.children.clear();
      target.append(
          new dom.SpanElement()
              ..classes.add('load-hi')
              ..text = '${value}%'
      );
    }
    else if (value != null && value > 70) {
      target.children.clear();
      target.append(
          new dom.SpanElement()
              ..classes.add('load-medium')
              ..text = '${value}%'
      );
    }
    else {
      target.children.clear();
      target.text = value != null ? '${value}%' : '0%';
    }
  }
}

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
    new Column(id: "server", name: "Server", field: "server", width: 180),
  ];

  var gridOptions = new GridOptions(
      editable: false,
      enableAddRow: false,
      enableCellNavigation: true,
      cellHighlightCssClass: 'changed', // TODO JS example has this, seems not to be uses anywhere
      cellFlashingCssClass: 'current-server'
  );

  MapDataItemProvider data;
  math.Random rnd = new math.Random();

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      for (var i = 0; i < 4; i++) {
        columns.add(new Column(
          id: 'cpu${i}',
          name: 'CPU${i}',
          field: 'cpu${i}',
          width: 80,
          formatter: new CpuUtilizationFormatter()
        ));
      }

      data = new MapDataItemProvider();
      for (var i = 0; i < 500; i++) {
        var item = new MapDataItem({
          'server': 'Server ${i}',
        });
        data.items.add(item);

        for(var j = 0; j < 4; j++) {
          item['cpu${j}'] = rnd.nextInt(100);
        }
      }

      grid.setup(dataProvider: data, columns: columns, gridOptions: gridOptions);

      currentServer = (rnd.nextDouble() * (data.length - 1)).round();

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

  int currentServer;

  void simulateRealTimeUpdates([dom.MouseEvent e, detail, dom.HtmlElement target]) {
      var changes = new Map<int,Map<String,String>>();
      int numberOfUpdates = (rnd.nextDouble() * (data.length / 10)).round();

      for (var i = 0; i < numberOfUpdates; i++) {
        var server = rnd.nextInt(data.length - 1);
        var cpu = rnd.nextInt(columns.length - 1);
        var delta = rnd.nextInt(50) - 25;
        //var col = grid.getColumnIndex('cpu${cpu}');
        //print('col: ${col}');
        var val = data.items[server]['cpu${cpu}'] + delta ;
        val = math.max(0, val);
        val = math.min(100, val);

        data.items[server]['cpu${cpu}'] = val;

        if (!changes.containsKey(server)) {
          changes[server] = {};
        }

        changes[server]['cpu${cpu}'] = 'changed';

        grid.invalidateRow(server);
      }

      grid.setCellCssStyles('highlight', changes);
      grid.render();

      new async.Future.delayed(new Duration(milliseconds: 500), () => simulateRealTimeUpdates());
    }

    void findCurrentServer(dom.MouseEvent e, detail, dom.HtmlElement target) {
      grid.scrollRowIntoView(currentServer);
      grid.flashCell(currentServer, grid.getColumnIndex("server"), 100);
    }
}
