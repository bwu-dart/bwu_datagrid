library app_element;

import 'dart:math' as math;
import 'dart:html' as dom;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/editors/editors.dart' as ed;
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/groupitem_metadata_providers/groupitem_metadata_providers.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/plugins/cell_selection_model.dart';
import 'package:bwu_datagrid/components/bwu_pager/bwu_pager.dart';
import 'package:bwu_datagrid/components/bwu_column_picker/bwu_column_picker.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

class AvgTotalsFormatter extends core.GroupTotalsFormatter {

  @override
  void call(dom.HtmlElement target, core.GroupTotals totals, Column columnDef) {
    //target.appendHtml(value);
    double val;
    if(totals['avg'] != null && totals['avg'][columnDef.field] != null) {
      val = totals['avg'][columnDef.field];
    }
    if (val != null) {
      target.appendHtml("avg: ${val.round()}%");
    } else {
      target.children.clear();
    }
  }
}

class SumTotalsFormatter extends core.GroupTotalsFormatter  {

  @override
  void call(dom.HtmlElement target, core.GroupTotals totals, Column columnDef) {
    //target.appendHtml(value);
    double val;
    if(totals['sum'] != null && totals['sum'][columnDef.field] != null) {
      val = totals['sum'][columnDef.field];
    }
    if (val != null) {
      target.appendHtml("total: ${(val * 100).round() / 100}%");
    } else {
      target.children.clear();
    }
  }
}

class GroupTitleFormatter extends core.GroupTitleFormatter {
  String name;
  GroupTitleFormatter([this.name = '']);

  @override
  dom.Node call(core.Group group) {
    return new dom.SpanElement()
        ..appendText('${name}: ${group.value} ')
        ..append(
            new dom.SpanElement()
                ..style.color = 'green'
                ..appendText('(${group.count} items)'));
  }
}

class BooleanGroupTitleFormatter extends core.GroupTitleFormatter {
  String name;
  BooleanGroupTitleFormatter([this.name = '']);

  @override
  dom.Node call(core.Group group) {
    return new dom.DocumentFragment()
        ..appendText("Effort-Driven: ${group.value != null ? 'True' : 'False'}")
        ..append(
            new dom.SpanElement()
                ..style.color = 'green'
                ..appendText('(${group.count} items)'));
  }
}


@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  List<Column> columns = [
    new Column(id: "sel", name: "#", field: "num", cssClass: "cell-selection", width: 40, resizable: false, selectable: false, focusable: false),
    new Column(id: "title", name: "Title", field: "title", width: 70, minWidth: 50, cssClass: "cell-title", sortable: true, editor: new ed.TextEditor()),
    new Column(id: "duration", name: "Duration", field: "duration", width: 70, sortable: true, groupTotalsFormatter: new SumTotalsFormatter()),
    new Column(id: "%", name: "% Complete", field: "percentComplete", width: 80, formatter: new fm.PercentCompleteBarFormatter(), sortable: true, groupTotalsFormatter: new AvgTotalsFormatter()),
    new Column(id: "start", name: "Start", field: "start", minWidth: 60, sortable: true),
    new Column(id: "finish", name: "Finish", field: "finish", minWidth: 60, sortable: true),
    new Column(id: "cost", name: "Cost", field: "cost", width: 90, sortable: true, groupTotalsFormatter: new SumTotalsFormatter()),
    new Column(id: "effort-driven", name: "Effort Driven", width: 80, minWidth: 20, maxWidth: 80, cssClass: "cell-effort-driven", field: "effortDriven", formatter: new fm.CheckmarkFormatter(), sortable: true)
  ];

  var gridOptions = new GridOptions(
      enableCellNavigation: true,
      editable: true
  );

  math.Random rnd = new math.Random();

  BwuDatagrid grid;
  List<MapDataItem> data;
  DataView dataView;

  String sortcol = "title";
  int sortdir = 1;
  int percentCompleteThreshold = 0;
  int prevPercentCompleteThreshold = 0;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      // prepare the data
//      data = new MapDataItemProvider();
//      for (var i = 0; i < 100; i++) {
//        data.items.add(new MapDataItem({
//        'num': i,
//        }));
//      }

      var groupItemMetadataProvider = new GroupItemMetadataProvider();
      dataView = new DataView(options: new DataViewOptions(
        groupItemMetadataProvider: groupItemMetadataProvider,
        inlineFilters: true
      ));

      grid.setup(dataProvider: dataView, columns: columns, gridOptions: gridOptions).then((_) {
        grid.registerPlugin(new GroupItemMetadataProvider());
        grid.setSelectionModel = new CellSelectionModel();

        ($['pager'] as BwuPager).init(dataView, grid);

        BwuColumnPicker columnPicker = (new dom.Element.tag('bwu-column-picker') as BwuColumnPicker)
            ..columns = columns
            ..grid = grid;
        dom.document.body.append(columnPicker);

        grid.onBwuSort.listen((e) {
          sortdir = e.sortAsc ? 1 : -1;
          sortcol = e.sortColumn.field;

          // using native sort with comparer
          // preferred method but can be very slow in IE with huge datasets
          dataView.sort(comparer, e.sortAsc);
        });

        // wire up model events to drive the grid
        dataView.onBwuRowCountChanged.listen((e) {
          grid.updateRowCount();
          grid.render();
        });

        dataView.onBwuRowsChanged.listen((e) {
          grid.invalidateRows(e.changedRows);
          grid.render();
        });

        var h_runfilters = null;

//        // wire up the slider to apply the filter to the model
//        $("#pcSlider,#pcSlider2").slider({
//          "range": "min",
//          "slide": function (event, ui) {
//            Slick.GlobalEditorLock.cancelCurrentEdit();
//
//            if (percentCompleteThreshold != ui.value) {
//              window.clearTimeout(h_runfilters);
//              h_runfilters = window.setTimeout(filterAndUpdate, 10);
//              percentCompleteThreshold = ui.value;
//            }
//          }
//        });

        // initialize the model after all the events have been hooked up
        dataView.beginUpdate();
        dataView.setFilter(myFilter);
        dataView.setFilterArgs({
          'percentComplete': percentCompleteThreshold
        });
        loadData(50);
        groupByDuration();
        dataView.endUpdate();

        //$("#gridContainer").resizable();
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

  void filterAndUpdate() {
    bool isNarrowing = percentCompleteThreshold > prevPercentCompleteThreshold;
    bool isExpanding = percentCompleteThreshold < prevPercentCompleteThreshold;
    Range renderedRange = grid.getRenderedRange();

    dataView.setFilterArgs({
      'percentComplete': percentCompleteThreshold
    });
    dataView.setRefreshHints({
      'ignoreDiffsBefore': renderedRange.top,
      'ignoreDiffsAfter': renderedRange.bottom + 1,
      'isFilterNarrowing': isNarrowing,
      'isFilterExpanding': isExpanding
    });
    dataView.refresh();

    prevPercentCompleteThreshold = percentCompleteThreshold;
  }


  bool myFilter(DataItem item, Map args) {
    return item["percentComplete"] >= args['percentComplete'];
  }

  int percentCompleteSort(Map a, Map b) {
    return a["percentComplete"] - b["percentComplete"];
  }

//  int comparer(a, b) {
//    var x = a[sortcol], y = b[sortcol];
//    return (x == y ? 0 : (x > y ? 1 : -1));
//  }

  int comparer(DataItem a, DataItem b) {

    var x = a[sortcol], y = b[sortcol];
    if(x == y ) {
      return 0;
    }

    if(x is Comparable) {
      return x.compareTo(y);
    }

    if(y is Comparable) {
      return 1;
    }

    if(x == null && y != null) {
      return -1;
    } else if (x != null && y == null) {
      return 1;
    }

    if(x is bool) {
      return x == true ? 1 : 0;
    }
    return (x == y ? 0 : (x > y ? 1 : -1));
  }


  void groupByDuration() {
    dataView.setGrouping(<GroupingInfo>[new GroupingInfo(
      getter: "duration",
      formatter: new GroupTitleFormatter('Duration'),
      aggregators: [
        new AvgAggregator("percentComplete"),
        new SumAggregator("cost")
      ],
      doAggregateCollapsed: false,
      isLazyTotalsCalculation: true
    )]);
  }

  void groupByDurationOrderByCount(bool doAggregateCollapsed) {
    dataView.setGrouping(<GroupingInfo>[new GroupingInfo(
      getter: "duration",
      formatter: new GroupTitleFormatter('Duration'),
      comparer: (a, b) {
        return a.count - b.count;
      },
      aggregators: [
        new AvgAggregator("percentComplete"),
        new SumAggregator("cost")
      ],
      doAggregateCollapsed: doAggregateCollapsed,
      isLazyTotalsCalculation: true
    )]);
  }

  void groupByDurationEffortDriven() {
    dataView.setGrouping(<GroupingInfo>[new GroupingInfo(
        getter: "duration",
        formatter : new GroupTitleFormatter('Duration'),
        aggregators: [
          new SumAggregator("duration"),
          new SumAggregator("cost")
        ],
        doAggregateCollapsed: true,
        isLazyTotalsCalculation: true
      ),
      new GroupingInfo(
        getter: "effortDriven",
        formatter : new BooleanGroupTitleFormatter('Effort-Driven'),
        aggregators: [
          new AvgAggregator("percentComplete"),
          new SumAggregator("cost")
        ],
        isCollapsed: true,
        isLazyTotalsCalculation: true
      )
    ]);
  }

  void groupByDurationEffortDrivenPercent() {
    dataView.setGrouping(<GroupingInfo>[
      new GroupingInfo(
        getter: "duration",
        formatter: new GroupTitleFormatter('Duration'),
        aggregators: [
          new SumAggregator("duration"),
          new SumAggregator("cost")
        ],
        doAggregateCollapsed: true,
        isLazyTotalsCalculation: true
      ),
      new GroupingInfo(
        getter: "effortDriven",
        formatter: new BooleanGroupTitleFormatter('Effort-Driven'),
        aggregators :[
          new SumAggregator("duration"),
          new SumAggregator("cost")
        ],
        isLazyTotalsCalculation: true
      ),
      new GroupingInfo(
        getter: "percentComplete",
        formatter: new GroupTitleFormatter('% Complete'),
        aggregators: [
          new AvgAggregator("percentComplete")
        ],
        doAggregateCollapsed: true,
        isCollapsed: true,
        isLazyTotalsCalculation: true
      )
    ]);
  }

  void loadData(int count) {
    var someDates = ["01/01/2009", "02/02/2009", "03/03/2009"];
    data = [];
    // prepare the data
    for (var i = 0; i < count; i++) {
      data.add(new MapDataItem({
        "id": "id_${i}",
        "num": i,
        "title": "Task ${i}",
        "duration" : rnd.nextInt(30),
        "percentComplete": rnd.nextInt(100),
        "start" : someDates[ (rnd.nextDouble() * 2).floor()],
        "finish" : someDates[ (rnd.nextDouble() * 2).floor()],
        "cost" : (rnd.nextDouble() * 10000).round() / 100,
        "effortDriven" : (i % 5 == 0)
      }));
    }
    dataView.setItems(data);
  }
}
