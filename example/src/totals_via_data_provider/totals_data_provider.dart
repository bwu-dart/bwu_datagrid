library bwu_datagrid.examples.totals_data_provider;

import 'package:bwu_utils_browser/math/parse_num.dart' as tools;

import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

class TotalsDataProvider extends MapDataItemProvider {
  MapDataItem _totals = new MapDataItem({});
  List<Column> _columns;

  RowMetadata totalsMetadata = new RowMetadata(
    // Style the totals row differently.
    cssClasses: 'totals',
    columns: new Map<String,Column>()
  );

  TotalsDataProvider(List<MapDataItem> data, this._columns) : super(data){
    // Make the totals not editable.
    for (var i = 0; i < _columns.length; i++) {
      totalsMetadata.columns['${i}'] = new Column( editor: null );
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
        var val = items[i][columnId];
        if(val != null) {
          if(val is String) {
            total += (tools.parseInt(items[i][columnId], onErrorDefault: 0));
          } else {
            if(val is int) {
              total += val;
            }
          }
        }
      }
      _totals[columnId] = 'Sum:  ${total}';
    }
  }

  @override
  RowMetadata getItemMetadata (int index) {
    return (index != items.length) ? null : totalsMetadata;
  }

  @override
  int get length => super.length + 1;
}