library app_element;

import 'dart:math' as math;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/editors/editors.dart';

import 'totals_data_provider.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [];

  var gridOptions = new GridOptions(
      enableCellNavigation: true,
      headerRowHeight: 30,
      editable: true
  );

  math.Random rnd = new math.Random();

  TotalsDataProvider data;

  @override
  void attached() {
    super.attached();

    try {
      for (int i = 0; i < 10; i++) {
        columns.add(new Column(
          id: '${i}',
          name: new String.fromCharCode('A'.codeUnitAt(0) + i),
          field: '${i}',
          width: 60,
          editor: new IntegerEditor()
        ));
      }


      grid = $['myGrid'];

      data = new TotalsDataProvider(<MapDataItem>[], columns);
      for (var i = 0; i < 10; i++) {
        var d = new MapDataItem({'id': i});
        data.items.add(d);
        for(int j = 0; j < columns.length; j++) {
          d['${j}'] = rnd.nextInt(10);
        }
      }
      data.updateTotals();

      grid.setup(dataProvider: data, columns: columns, gridOptions: gridOptions);

      grid.onBwuCellChange.listen((e) {
        // The data has changed - recalculate the totals.
        data.updateTotals();

        // Rerender the totals row (last row).
        grid.invalidateRow(data.length - 1);
        grid.render();
      });

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
