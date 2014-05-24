library app_element;

import 'dart:math' as math;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/tools/html.dart' as tools;

import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/editors/editors.dart';

class TotalsDataProvider extends MapDataItemProvider {
  Map<int,String> _totals = {};
  List<Column> _columns;

  var totalsMetadata = new RowMetadata(
    // Style the totals row differently.
    cssClasses: "totals",
    columns: new Map<String,Column>()
  );

  TotalsDataProvider(List<MapDataItem> data, this._columns) : super(data){
    // Make the totals not editable.
    for (var i = 0; i < _columns.length; i++) {
      totalsMetadata._columns['${i}'] = new Column( editor: null );
    }

    updateTotals();
  }

  @override
  DataItem getItem (int index) {
    return (index < items.length) ? items[index] : _totals;
  }

  void updateTotals () {
    var columnIdx = _columns.length;
    while (columnIdx-- > 0) {
      var columnId = _columns[columnIdx].id;
      var total = 0;
      var i = items.length;
      while (i-- > 0) {
        total += (tools.parseIntSafe(items[i][columnId], onErrorDefault: 0));
      }
      _totals[columnId] = 'Sum:  ${total}';
    }
  }

  @override
  RowMetadata getItemMetadata (int index) {
    return (index != items.length) ? null : totalsMetadata;
  }
}

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

        for(int j = 0; j < columns.length; j++) {
          d['${j}'] = rnd.nextInt(10);
        }
      }

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
