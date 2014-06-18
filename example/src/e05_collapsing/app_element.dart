library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart';

import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_utils_browser/math/parse_num.dart' as tools;

import '../required_field_validator.dart';

class TaskNameFormatter extends fm.Formatter {
  List<DataItem> data;
  DataView dataView;
  TaskNameFormatter({this.data, this.dataView});

  void call(dom.HtmlElement target, int row, int cell, dynamic value, Column columnDef, DataItem dataContext) {
    target.children.clear();
    // TODO value = value.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
    var spacer = new dom.SpanElement()
        ..style.display = 'inline-block'
        ..style.height= '1px'
        ..style.width = '${(15 * dataContext["indent"])}px';
        target.append(spacer);
    int idx = dataView.getIdxById(dataContext['id']);
    var toggle = new dom.SpanElement()
    ..classes.add('toggle');

    if (data[idx + 1] != null && data[idx + 1]['indent'] > data[idx]['indent']) {
      if (dataContext.collapsed) {
        toggle.classes.add('expand');
      } else {
        toggle.classes.add('collapse');
      }
    }
    target.append(toggle);
    target.appendHtml('&nbsp;${value}');
  }
}


@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  static TaskNameFormatter tnFormatter = new TaskNameFormatter();

  BwuDatagrid grid;
  List<Column> columns = [
    new Column(id: "title", name: "Title", field: "title", width: 220, cssClass: "cell-title", formatter: tnFormatter, editor: new TextEditor(), validator: new RequiredFieldValidator()),
    new Column(id: "duration", name: "Duration", field: "duration", editor: new TextEditor()),
    new Column(id: "%", name: "% Complete", field: "percentComplete", width: 80, resizable: false, formatter: new fm.PercentCompleteBarFormatter(), editor: new PercentCompleteEditor()),
    new Column(id: "start", name: "Start", field: "start", minWidth: 60, editor: new DateEditor()),
    new Column(id: "finish", name: "Finish", field: "finish", minWidth: 60, editor: new DateEditor()),
    new Column(id: "effort-driven", name: "Effort Driven", width: 80, minWidth: 20, maxWidth: 80, cssClass: "cell-effort-driven", field: "effortDriven", formatter: new fm.CheckmarkFormatter(), editor: new CheckboxEditor(), cannotTriggerInsert: true)
  ];

  var gridOptions = new GridOptions(
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: true
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

    int indent = 0;
    List<int> parents = [];

    try {
      // prepare the data
      data = new List<DataItem>();
      for (int i = 0; i < 1000; i++) {
        var d = new MapDataItem();
        data.add(d);
        var parent;

        if (rnd.nextDouble() > 0.8 && i > 0) {
          indent++;
          parents.add(i - 1);
        } else if (rnd.nextDouble() < 0.3 && indent > 0) {
          indent--;
          parents.removeLast();
        }

        if (parents.length > 0) {
          parent = parents[parents.length - 1];
        } else {
          parent = null;
        }

        grid = $['myGrid'];

        d['id'] = "id_${i}";
        d['indent'] = indent;
        d['parent'] = parent;
        d['title'] = 'Task ${i}';
        d['duration'] = "5 days";
        d['percentComplete'] = rnd.nextInt(100);
        d['start'] = "01/01/2009";
        d['finish'] = "01/05/2009";
        d['effortDriven'] =  (i % 5 == 0);
      }

      dataView = new DataView(options: new DataViewOptions(inlineFilters: true))
        ..beginUpdate()
        ..setItems(data)
        ..setFilterArgs({
          'percentCompleteThreshold': tools.parseInt(percentCompleteThreshold, onErrorDefault: 0),
          'searchString': searchString
        })
        ..setFilter(myFilter)
        ..endUpdate();

      tnFormatter
        ..data = data
        ..dataView = dataView;

      grid.setup(dataProvider: dataView, columns: columns, gridOptions: gridOptions).then((_) {

        grid.onBwuCellChange.listen((e) => dataView.updateItem(e.item['id'], e.item));

        grid.onBwuAddNewRow.listen((e) {
          var item = new MapDataItem({"id": "new_${rnd.nextInt(10000)}", 'indent': 0, "title": "New task", "duration": "1 day", "percentComplete": 0, "start": "01/01/2009", "finish": "01/01/2009", "effortDriven": false});
          item.extend(e.item);
          dataView.addItem(item);
        });

        grid.onBwuClick.listen((e) {
          if ((e.causedBy.target as dom.HtmlElement).classes.contains("toggle")) {
            var item = dataView.getItem(e.cell.row);
            if (item != null) {
              item.collapsed = !item.collapsed;

              dataView.updateItem(item['id'], item);
            }
            e.stopImmediatePropagation();
          }
        });

        dataView.onBwuRowCountChanged.listen((e) {
          grid.updateRowCount();
          grid.render();
        });

        dataView.onBwuRowsChanged.listen((e) {
          grid.invalidateRows(e.changedRows);
          grid.render();
        });
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
  bool myFilter(DataItem item, Map args) {
    if (item["percentComplete"] < args['percentCompleteThreshold']) {
      return false;
    }

    if (args['searchString'] != '' && item['title'].indexOf(args['searchString']) == -1) {
      return false;
    }

    if (item['parent'] != null) {
      var parent = data[item['parent']];

      while (parent != null) {
        if (parent.collapsed || (parent["percentComplete"]
            < tools.parseInt(percentCompleteThreshold, onErrorDefault: 0))
                || (searchString != "" && parent["title"].indexOf(searchString) == -1)) {
          return false;
        }

        if(parent['parent'] != null) {
          parent = data[parent['parent']];
        } else {
          parent = null;
        }
      }
    }
    return true;
  }

  int percentCompleteSort(Map a, Map b) {
    return a["percentComplete"] - b["percentComplete"];
  }
}
