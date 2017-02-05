@HtmlImport('app_element.html')
library app_element;

import 'dart:html' show window, Event;
import 'dart:math' as math;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
// ignore: unused_import
import 'package:bwu_datagrid_examples/asset/example_style.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

class CustomMapDataItemProvider extends DataProvider<core.ItemBase> {
  Function _getItem;
  Function _getLength;

  CustomMapDataItemProvider(this._getItem, this._getLength)
      : super(<core.ItemBase>[]);

  @override
  int get length => _getLength() as int;

  @override
  DataItem getItem(int index) => _getItem(index) as DataItem;

  @override
  RowMetadata getItemMetadata(int index) => null;
}

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  final List<Column> columns = <Column>[
    new Column(
        id: "title", name: "Title", field: "title", width: 240, sortable: true),
    new Column(
        id: "c1", name: "Sort 1", field: "c1", width: 240, sortable: true),
    new Column(
        id: "c2", name: "Sort 2", field: "c2", width: 240, sortable: true),
    new Column(
        id: "c3", name: "Sort 3", field: "c3", width: 240, sortable: true)
  ];

  final GridOptions gridOptions =
      new GridOptions(enableCellNavigation: false, enableColumnReorder: false);

  math.Random rnd = new math.Random();
  static const int numberOfItems = 25000;
  List<int> items = new List<int>(numberOfItems);
  Map indices;
  bool isAsc = true;
  Column currentSortCol = new Column(id: "title");
  int i;

  BwuDatagrid grid;
  MapDataItemProvider<core.ItemBase> data;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'] as BwuDatagrid;
      // prepare the data
      data = new MapDataItemProvider<core.ItemBase>();

      for (int i = 0; i < numberOfItems; i++) {
        items[i] = i;

        data.items.add(new MapDataItem<String, dynamic>(
            <String, dynamic>{'title': 'Task ${i}'}));
      }

      indices = <String, dynamic>{
        'title': items,
        'c1': randomize(items),
        'c2': randomize(items),
        'c3': randomize(items)
      };

      // Assign values to the data.
      for (int i = 0; i < numberOfItems; i++) {
        data.items[indices['c1'][i] as int]['c1'] = "Value ${i + 1}";
        data.items[indices['c2'][i] as int]['c2'] = "Value ${i + 1}";
        data.items[indices['c3'][i] as int]['c3'] = "Value ${i + 1}";
      }

      CustomMapDataItemProvider dataProvider =
          new CustomMapDataItemProvider(getItem, getLength);

      window.onResize.listen((Event e) => grid.resizeCanvas(e));

      grid
          .setup(
              dataProvider: dataProvider,
              columns: columns,
              gridOptions: gridOptions)
          .then/*<dynamic>*/((_) {
        grid.onBwuSort.listen((core.Sort args) {
          currentSortCol = args.sortColumn;
          isAsc = args.sortAsc;
          grid.invalidateAllRows();
          grid.render();
        });
      });
    } on NoSuchMethodError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on RangeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on TypeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } catch (e) {
      print('$e');
    }
  }

  // Copies and shuffles the specified array and returns a new shuffled array.
  List<int> randomize(List<int> items) {
    final List<int> randomItems = items.toList();
    int randomIndex;
    int temp;
    int index;
    for (index = 0; index < items.length; index++) {
      randomIndex = rnd.nextInt(items.length - 1);
      if (randomIndex > -1) {
        temp = randomItems[randomIndex];
        randomItems[randomIndex] = randomItems[index];
        randomItems[index] = temp;
      }
    }
    return randomItems;
  }

  // Define function used to get the data and sort it.
  core.ItemBase getItem(int index) {
    return isAsc
        ? data.items[indices[currentSortCol.id][index] as int]
        : data.items[
            indices[currentSortCol.id][(data.length - 1) - index] as int];
  }

  int getLength() {
    return data.length;
  }
}
