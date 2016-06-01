@HtmlImport('app_element.html')
library app_element;

import 'dart:math' as math;
import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

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
import 'package:bwu_datagrid/components/jq_ui_style/jq_ui_style.dart';
import 'package:bwu_datagrid_examples/asset/example_style.dart';
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

/// Silence analyzer [exampleStyleSilence], [OptionsPanel], [jqUiStyleSilence],
class AvgTotalsFormatter extends core.GroupTotalsFormatter {
  @override
  void format(dom.Element target, core.GroupTotals totals, Column columnDef) {
    double val;
    if (totals['avg'] != null && totals['avg'][columnDef.field] != null) {
      val = totals['avg'][columnDef.field];
    }
    if (val != null) {
      target.appendHtml("avg: ${val.round()}%");
    } else {
      target.children.clear();
    }
  }
}

class SumTotalsFormatter extends core.GroupTotalsFormatter {
  @override
  void format(dom.Element target, core.GroupTotals totals, Column columnDef) {
    //target.appendHtml(value);
    double val;
    if (totals['sum'] != null && totals['sum'][columnDef.field] != null) {
      val = totals['sum'][columnDef.field];
    }
    if (val != null) {
      target.appendHtml("total: ${(val * 100).round() / 100}");
    } else {
      target.children.clear();
    }
  }
}

class GroupTitleFormatter extends fm.GroupTitleFormatter {
  String name;

  GroupTitleFormatter([this.name = '']);

  @override
  dom.Node format(core.Group group) {
    return new dom.SpanElement()
      ..appendText('${name}: ${group.value} ')
      ..append(new dom.SpanElement()
        ..style.color = 'green'
        ..appendText('(${group.count} items)'));
  }
}

class BooleanGroupTitleFormatter extends fm.GroupTitleFormatter {
  String name;

  BooleanGroupTitleFormatter([this.name = '']);

  @override
  dom.Node format(core.Group group) {
    return new dom.DocumentFragment()
      ..appendText("Effort-Driven: ${group.value != null ? 'True' : 'False'}")
      ..append(new dom.SpanElement()
        ..style.color = 'green'
        ..appendText(' (${group.count} items)'));
  }
}

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  @Property(observer: 'thresholdChanged')
  String threshold = '0';

  AppElement.created() : super.created();

  final List<Column> columns = <Column>[
    new Column(
        id: "sel",
        name: "#",
        field: "num",
        cssClass: "cell-selection",
        width: 40,
        resizable: false,
        selectable: false,
        focusable: false),
    new Column(
        id: "title",
        name: "Title",
        field: "title",
        width: 70,
        minWidth: 50,
        cssClass: "cell-title",
        sortable: true,
        editor: new ed.TextEditor()),
    new Column(
        id: "duration",
        name: "Duration",
        field: "duration",
        width: 70,
        sortable: true,
        groupTotalsFormatter: new SumTotalsFormatter()),
    new Column(
        id: "%",
        name: "% Complete",
        field: "percentComplete",
        width: 80,
        formatter: new fm.PercentCompleteBarFormatter(),
        sortable: true,
        groupTotalsFormatter: new AvgTotalsFormatter()),
    new Column(
        id: "start",
        name: "Start",
        field: "start",
        minWidth: 60,
        sortable: true),
    new Column(
        id: "finish",
        name: "Finish",
        field: "finish",
        minWidth: 60,
        sortable: true),
    new Column(
        id: "cost",
        name: "Cost",
        field: "cost",
        width: 90,
        sortable: true,
        groupTotalsFormatter: new SumTotalsFormatter()),
    new Column(
        id: "effort-driven",
        name: "Effort Driven",
        width: 80,
        minWidth: 20,
        maxWidth: 80,
        cssClass: "cell-effort-driven",
        field: "effortDriven",
        formatter: new fm.CheckmarkFormatter(),
        sortable: true)
  ];

  final GridOptions gridOptions =
      new GridOptions(enableCellNavigation: true, editable: true);

  math.Random rnd = new math.Random();

  BwuDatagrid grid;
  List<MapDataItem> data;
  DataView<core.ItemBase> dataView;

  String sortcol = "title";
  int sortdir = 1;
  int percentCompleteThreshold = 0;
  int prevPercentCompleteThreshold = 0;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      final GroupItemMetadataProvider groupItemMetadataProvider =
          new GroupItemMetadataProvider();
      dataView = new DataView<core.ItemBase>(options: new DataViewOptions(
          groupItemMetadataProvider: groupItemMetadataProvider,
          inlineFilters: true));

      grid
          .setup(
              dataProvider: dataView,
              columns: columns,
              gridOptions: gridOptions)
          .then((_) {
        grid.registerPlugin(new GroupItemMetadataProvider());
        grid.setSelectionModel = new CellSelectionModel();

        ($['pager'] as BwuPager).init(dataView, grid);

        BwuColumnPicker columnPicker =
            (new dom.Element.tag('bwu-column-picker') as BwuColumnPicker)
              ..columns = columns
              ..grid = grid;
        dom.document.body.append(columnPicker);

        grid.onBwuSort.listen((core.Sort e) {
          sortdir = e.sortAsc ? 1 : -1;
          sortcol = e.sortColumn.field;

          // using native sort with comparer
          // preferred method but can be very slow in IE with huge datasets
          dataView.sort(comparer, e.sortAsc);
        });

        // wire up model events to drive the grid
        dataView.onBwuRowCountChanged.listen((core.RowCountChanged e) {
          grid.updateRowCount();
          grid.render();
        });

        dataView.onBwuRowsChanged.listen((core.RowsChanged e) {
          grid.invalidateRows(e.changedRows);
          grid.render();
        });

        // initialize the model after all the events have been hooked up
        dataView.beginUpdate();
        dataView.setFilter(myFilter);
        dataView.setFilterArgs(
            <String, dynamic>{'percentComplete': percentCompleteThreshold});
        loadData(50);
        groupByDuration();
        dataView.endUpdate();

        //$("#gridContainer").resizable();
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

  async.Timer _pendingUpdateFilter;

  @reflectable
  void thresholdChanged([_, __]) {
    core.globalEditorLock.cancelCurrentEdit();

    if (_pendingUpdateFilter != null) {
      _pendingUpdateFilter.cancel();
    }
    _pendingUpdateFilter = new async.Timer(new Duration(milliseconds: 20), () {
      percentCompleteThreshold = int.parse(threshold);
      filterAndUpdate();
    });
  }

  void filterAndUpdate() {
    bool isNarrowing = percentCompleteThreshold > prevPercentCompleteThreshold;
    bool isExpanding = percentCompleteThreshold < prevPercentCompleteThreshold;
    Range renderedRange = grid.getRenderedRange();

    dataView.setFilterArgs(
        <String, dynamic>{'percentComplete': percentCompleteThreshold});
    dataView.setRefreshHints(<String, dynamic>{
      'ignoreDiffsBefore': renderedRange.top,
      'ignoreDiffsAfter': renderedRange.bottom + 1,
      'isFilterNarrowing': isNarrowing,
      'isFilterExpanding': isExpanding
    });
    dataView.refresh();

    prevPercentCompleteThreshold = percentCompleteThreshold;
  }

  bool myFilter(core.ItemBase item, Map<dynamic, dynamic> args) {
    return item["percentComplete"] >= args['percentComplete'];
  }

  int percentCompleteSort(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    return a["percentComplete"] - b["percentComplete"];
  }

  int comparer(core.ItemBase a, core.ItemBase b) {
    final dynamic x = a[sortcol];
    final dynamic y = b[sortcol];
    if (x == y) {
      return 0;
    }

    if (x is Comparable<core.ItemBase>) {
      return x.compareTo(y);
    }

    if (y is Comparable<core.ItemBase>) {
      return 1;
    }

    if (x == null && y != null) {
      return -1;
    } else if (x != null && y == null) {
      return 1;
    }

    if (x is bool) {
      return x == true ? 1 : 0;
    }
    return (x == y ? 0 : (x > y ? 1 : -1));
  }

  @reflectable
  void groupByDuration([_, __]) {
    dataView.setGrouping(<GroupingInfo>[
      new GroupingInfo(
          getter: "duration",
          formatter: new GroupTitleFormatter('Duration'),
          aggregators: <Aggregator>[
            new AvgAggregator("percentComplete"),
            new SumAggregator("cost")
          ],
          doAggregateCollapsed: false,
          isLazyTotalsCalculation: true)
    ]);
  }

  @reflectable
  void groupByDurationOrderByCountHandler([_, __]) {
    groupByDurationOrderByCount();
  }

  @reflectable
  void groupByDurationOrderByCountDoAggregateHandler([_, __]) {
    groupByDurationOrderByCount(true);
  }

  void groupByDurationOrderByCount([bool doAggregateCollapsed = false]) {
    dataView.setGrouping(<GroupingInfo>[
      new GroupingInfo(
          getter: "duration",
          formatter: new GroupTitleFormatter('Duration'),
          comparer: (core.ItemBase a, core.ItemBase b) =>
              (a as core.Group).count - (b as core.Group).count,
          aggregators: <Aggregator>[
            new AvgAggregator("percentComplete"),
            new SumAggregator("cost")
          ],
          doAggregateCollapsed: doAggregateCollapsed,
          isLazyTotalsCalculation: true)
    ]);
  }

  @reflectable
  void groupByDurationEffortDriven([_, __]) {
    dataView.setGrouping(<GroupingInfo>[
      new GroupingInfo(
          getter: "duration",
          formatter: new GroupTitleFormatter('Duration'),
          aggregators: <Aggregator>[
            new SumAggregator("duration"),
            new SumAggregator("cost")
          ],
          doAggregateCollapsed: true,
          isLazyTotalsCalculation: true),
      new GroupingInfo(
          getter: "effortDriven",
          formatter: new BooleanGroupTitleFormatter('Effort-Driven'),
          aggregators: <Aggregator>[
            new AvgAggregator("percentComplete"),
            new SumAggregator("cost")
          ],
          isCollapsed: true,
          isLazyTotalsCalculation: true)
    ]);
  }

  @reflectable
  void groupByDurationEffortDrivenPercent([_, __]) {
    dataView.setGrouping(<GroupingInfo>[
      new GroupingInfo(
          getter: "duration",
          formatter: new GroupTitleFormatter('Duration'),
          aggregators: <Aggregator>[
            new SumAggregator("duration"),
            new SumAggregator("cost")
          ],
          doAggregateCollapsed: true,
          isLazyTotalsCalculation: true),
      new GroupingInfo(
          getter: "effortDriven",
          formatter: new BooleanGroupTitleFormatter('Effort-Driven'),
          aggregators: <Aggregator>[
            new SumAggregator("duration"),
            new SumAggregator("cost")
          ],
          isLazyTotalsCalculation: true),
      new GroupingInfo(
          getter: "percentComplete",
          formatter: new GroupTitleFormatter('% Complete'),
          aggregators: <Aggregator>[new AvgAggregator("percentComplete")],
          doAggregateCollapsed: true,
          isCollapsed: true,
          isLazyTotalsCalculation: true)
    ]);
  }

  @reflectable
  void loadDataHandler(dom.Event e, [_]) {
    int count = int.parse((e.target as dom.Element).dataset['count']);
    loadData(count);
  }

  void loadData(int count) {
    final List<String> someDates = <String>[
      "01/01/2009",
      "02/02/2009",
      "03/03/2009"
    ];
    //var timer = new Stopwatch()..start();
    data = new List<MapDataItem>.generate(
        count,
        (int i) => new MapDataItem(<String, dynamic>{
              "id": "id_${i}",
              "num": i,
              "title": "Task ${i}",
              "duration": rnd.nextInt(30),
              "percentComplete": rnd.nextInt(100),
              "start": someDates[(rnd.nextDouble() * 2).floor()],
              "finish": someDates[(rnd.nextDouble() * 2).floor()],
              "cost": (rnd.nextDouble() * 10000).round() / 100,
              "effortDriven": (i % 5 == 0)
            }),
        growable: true);
    //print(timer.elapsed);
    dataView.items = data;
    //print(timer.elapsed);
    //timer.stop();
  }

  @reflectable
  void groupClearHandler([_, __]) {
    dataView.setGrouping(<GroupingInfo>[]);
  }

  @reflectable
  void collapseAllGroupsHandler([_, __]) {
    dataView.collapseAllGroups();
  }

  @reflectable
  void expandAllGroupsHandler([_, __]) {
    dataView.expandAllGroups();
  }
}
