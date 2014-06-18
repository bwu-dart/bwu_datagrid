library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart';

import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/components/bwu_column_picker/bwu_column_picker.dart';
import 'package:bwu_datagrid/plugins/row_selection_model.dart';
import 'package:bwu_datagrid/components/bwu_pager/bwu_pager.dart';
import 'package:bwu_utils_browser/math/parse_num.dart' as tools;

import '../required_field_validator.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
    new Column(id: "sel", name: "#", field: "num", behavior: ["select"], cssClass: "cell-selection", width: 40, cannotTriggerInsert: true, resizable: false, selectable: false, isMovable: false),
    new Column(id: "title", name: "Title", field: "title", width: 120, minWidth: 120, cssClass: "cell-title", editor: new TextEditor(), validator: new RequiredFieldValidator(), sortable: true),
    new Column(id: "duration", name: "Duration", field: "duration", editor: new TextEditor(), sortable: true),
    new Column(id: "%", defaultSortAsc: false, name: "% Complete", field: "percentComplete", width: 80, resizable: false, formatter: new fm.PercentCompleteBarFormatter(), editor: new PercentCompleteEditor(), sortable: true),
    new Column(id: "start", name: "Start", field: "start", minWidth: 60, editor: new DateEditor(), sortable: true),
    new Column(id: "finish", name: "Finish", field: "finish", minWidth: 60, editor: new DateEditor(), sortable: true),
    new Column(id: "effort-driven", name: "Effort Driven", width: 80, minWidth: 20, maxWidth: 80, cssClass: "cell-effort-driven", field: "effortDriven", formatter: new fm.CheckmarkFormatter(), editor: new CheckboxEditor(), cannotTriggerInsert: true, sortable: true)
  ];

  var gridOptions = new GridOptions(
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: true,
      forceFitColumns: false,
      topPanelHeight: 25
  );

  math.Random rnd = new math.Random();

  List<DataItem> data;
  DataView dataView;

  String sortcol = "title";
  int sortdir = 1;
  @observable String percentCompleteThreshold;
  @observable String searchString;


  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      data = new List<DataItem>();
      for (var i = 0; i < 50000; i++) {
        data.add(new MapDataItem({
          "id" : "id_${i}",
          "num" : i,
          "title" : 'Task ${i}',
          "duration" : "5 days",
          "percentComplete" : rnd.nextInt(100),
          "start" : "01/01/2009",
          "finish" : "01/05/2009",
          "effortDriven" : (i % 5 == 0)
        }));
      }

      dataView = new DataView(options: new DataViewOptions(inlineFilters: true));
      grid.setup(dataProvider: dataView, columns: columns, gridOptions: gridOptions).then((_) {
        grid.setSelectionModel = new RowSelectionModel();

        ($['pager'] as BwuPager).init(dataView, grid);
        BwuColumnPicker columnPicker = new dom.Element.tag('bwu-column-picker') as BwuColumnPicker;
        columnPicker.columns = columns;
        columnPicker.grid = grid;
        dom.document.body.append(columnPicker);
        //columnPicker.options = new ColumnPickerOptions(/*gridOptions*/);

        grid.onBwuCellChange.listen((e) {
          dataView.updateItem(e.item['id'], e.item);
        });

        grid.onBwuAddNewRow.listen((e) {
          var item = new MapDataItem({"num": data.length, "id": "new_${rnd.nextInt(10000)}", "title": "New task", "duration": "1 day", "percentComplete": 0, "start": "01/01/2009", "finish": "01/01/2009", "effortDriven": false});
          item.extend(e.item);
          dataView.addItem(item);
        });

        grid.onBwuKeyDown.listen(onKeyDownHandler);

        grid.onBwuSort.listen(onSort);

        // wire up model events to drive the grid
        dataView.onBwuRowCountChanged.listen((e) {
          grid.updateRowCount();
          grid.render();
        });

        dataView.onBwuRowsChanged.listen((e) {
          grid.invalidateRows(e.changedRows);
          grid.render();
        });

        dataView.onBwuPagingInfoChanged.listen((e) {
          var isLastPage = e.pagingInfo.pageNum == e.pagingInfo.totalPages - 1;
          var enableAddRow = isLastPage || e.pagingInfo.pageSize == 0;
          var options = grid.getGridOptions;

          if (options.enableAddRow != enableAddRow) {
            grid.setGridOptions = new GridOptions.unitialized()..enableAddRow = enableAddRow;
          }
        });

        // initialize the model after all the events have been hooked up
        dataView.beginUpdate();
        dataView.setItems(data);
        dataView.setFilterArgs({
          'percentCompleteThreshold': tools.parseInt(percentCompleteThreshold, onErrorDefault: 0),
          'searchString': searchString
        });
        dataView.setFilter(myFilter);
        dataView.endUpdate();

        // if you don't want the items that are not visible (due to being filtered out
        // or being on a different page) to stay selected, pass 'false' to the second arg
        dataView.syncGridSelection(grid, true);

        // TODO $("#gridContainer").resizable();
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

  void btnSelectRowsHandler(dom.MouseEvent e, detail, dom.HtmlElement target) {

//  $['filter-form'].on['select-rows'].listen((e) {
    if (!core.globalEditorLock.commitCurrentEdit()) {
      return;
    }

    var rows = [];
    for (var i = 0; i < 10 && i < dataView.length; i++) {
      rows.add(i);
    }

    grid.setSelectedRows(rows);
  }

  void searchStringChanged(old) {
    updateFilter();
  }

  async.Timer _pendingUpdateFilter;
  void percentCompleteThresholdChanged(old) {
    if(_pendingUpdateFilter != null) {
      _pendingUpdateFilter.cancel();
    }

    _pendingUpdateFilter = new async.Timer(new Duration(milliseconds: 20), () {
      updateFilter();
      _pendingUpdateFilter = null;
    });
  }

  void updateFilter() {
    core.globalEditorLock.cancelCurrentEdit();

    if(searchString == null) {
      searchString = '';
    }

    if(percentCompleteThreshold == null) {
      percentCompleteThreshold = '0';
    }

    dataView.setFilterArgs({
      'percentCompleteThreshold': tools.parseInt(percentCompleteThreshold, onErrorDefault: 0),
      'searchString': searchString
    });
    dataView.refresh();
  }

  void onSort(core.Sort e) {
    sortdir = e.sortAsc ? 1 : -1;
    sortcol = e.sortColumn.field;

    dataView.sort(comparer, e.sortAsc);
  }

  bool myFilter(DataItem item, Map args) {
    if (item["percentComplete"] < args['percentCompleteThreshold']) {
      return false;
    }

    if (args['searchString'] != '' && item['title'].indexOf(args['searchString']) == -1) {
      return false;
    }

    return true;
  }

  int percentCompleteSort(Map a, Map b) {
    return a["percentComplete"] - b["percentComplete"];
  }

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

  // Header row search icon
  void toggleFilterRow(dom.MouseEvent e, detail, dom.HtmlElement target) {
    grid.setTopPanelVisibility = !grid.getGridOptions.showTopPanel;
  }

  void iconMouseOver(dom.MouseEvent e, detail, dom.HtmlElement target) {
    target.classes.add('ui-state-hover');
  }

  void iconMouseOut(dom.MouseEvent e, detail, dom.HtmlElement target) {
    target.classes.remove('ui-state-hover');
  }

  void onKeyDownHandler(core.KeyDown e) {
    // select all rows on ctrl-a
    if (e.causedBy.which != dom.KeyCode.A || !e.causedBy.ctrlKey) {
      return; // false;
    }

    var rows = [];
    for (var i = 0; i < dataView.length; i++) {
      rows.add(i);
    }

    grid.setSelectedRows(rows);
    e.preventDefault();
    return;
  }
}
