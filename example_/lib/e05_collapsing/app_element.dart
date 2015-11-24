@HtmlImport('app_element.html')
library app_element;

import 'dart:async' as async;
import 'dart:convert' show HtmlEscape;
import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart';

import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_utils/bwu_utils_browser.dart' as tools;
import 'package:bwu_datagrid/components/jq_ui_style/jq_ui_style.dart';

import 'package:bwu_datagrid_examples/shared/filter_form.dart';
import 'package:bwu_datagrid_examples/shared/required_field_validator.dart';
import 'package:bwu_datagrid_examples/asset/example_style.dart';
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

/// Silence analyzer [FilterForm], [exampleStyleSilence], [jqUiStyleSilence],
/// [OptionsPanel]
class TaskNameFormatter extends fm.CellFormatter {
  List<DataItem> data;
  DataView dataView;
  TaskNameFormatter({this.data, this.dataView});

  @override
  void format(dom.Element target, int row, int cell, Object value,
      Column columnDef, core.ItemBase dataContext) {
    target.children.clear();
    String val = new HtmlEscape().convert(value.toString());
    final dom.SpanElement spacer = new dom.SpanElement()
      ..style.display = 'inline-block'
      ..style.height = '1px'
      ..style.width = '${(15 * dataContext['indent'])}px';
    target.append(spacer);
    int idx = dataView.getIdxById(dataContext['id']);
    final dom.SpanElement toggle = new dom.SpanElement()..classes.add('toggle');

    if (data[idx + 1] != null &&
        data[idx + 1]['indent'] > data[idx]['indent']) {
      if ((dataContext as DataItem).collapsed) {
        toggle.classes.add('expand');
      } else {
        toggle.classes.add('collapse');
      }
    }
    target.append(toggle);
    target.appendHtml('&nbsp;${val}');
  }
}

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  static TaskNameFormatter tnFormatter = new TaskNameFormatter();

  BwuDatagrid grid;
  final List<Column> columns = <Column>[
    new Column(
        id: 'title',
        name: 'Title',
        field: 'title',
        width: 220,
        cssClass: 'cell-title',
        formatter: tnFormatter,
        editor: new TextEditor(),
        validator: new RequiredFieldValidator()),
    new Column(
        id: 'duration',
        name: 'Duration',
        field: 'duration',
        editor: new TextEditor()),
    new Column(
        id: '%',
        name: '% Complete',
        field: 'percentComplete',
        width: 80,
        resizable: false,
        formatter: new fm.PercentCompleteBarFormatter(),
        editor: new PercentCompleteEditor()),
    new Column(
        id: 'start',
        name: 'Start',
        field: 'start',
        minWidth: 60,
        editor: new DateEditor()),
    new Column(
        id: 'finish',
        name: 'Finish',
        field: 'finish',
        minWidth: 60,
        editor: new DateEditor()),
    new Column(
        id: 'effort-driven',
        name: 'Effort Driven',
        width: 80,
        minWidth: 20,
        maxWidth: 80,
        cssClass: 'cell-effort-driven',
        field: 'effortDriven',
        formatter: new fm.CheckmarkFormatter(),
        editor: new CheckboxEditor(),
        cannotTriggerInsert: true)
  ];

  final GridOptions gridOptions = new GridOptions(
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: true);

  math.Random rnd = new math.Random();

  List<DataItem> data;
  DataView<DataItem> dataView;

  String sortcol = 'title';
  int sortdir = 1;

  @Property(observer: 'percentCompleteThresholdChanged')
  String percentCompleteThreshold;
  @Property(observer: 'searchStringChanged')
  String searchString = '';

  @override
  void attached() {
    super.attached();

    int indent = 0;
    final List<int> parents = <int>[];

    try {
      // prepare the data
      data = new List<DataItem>();
      for (int i = 0; i < 1000; i++) {
        final MapDataItem d = new MapDataItem();
        data.add(d);
        int parent;

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

        d['id'] = 'id_${i}';
        d['indent'] = indent;
        d['parent'] = parent;
        d['title'] = 'Task ${i}';
        d['duration'] = '5 days';
        d['percentComplete'] = rnd.nextInt(100);
        d['start'] = '01/01/2009';
        d['finish'] = '01/05/2009';
        d['effortDriven'] = (i % 5 == 0);
      }

      dataView = new DataView<DataItem>(
          options: new DataViewOptions(inlineFilters: true))
        ..beginUpdate()
        ..items = data
        ..setFilterArgs({
          'percentCompleteThreshold':
              tools.parseInt(percentCompleteThreshold, onErrorDefault: 0),
          'searchString': searchString
        })
        ..setFilter(myFilter)
        ..endUpdate();

      tnFormatter
        ..data = data
        ..dataView = dataView;

      grid
          .setup(
              dataProvider: dataView,
              columns: columns,
              gridOptions: gridOptions)
          .then((_) {
        grid.onBwuCellChange.listen(
            (core.CellChange e) => dataView.updateItem(e.item['id'], e.item));

        grid.onBwuAddNewRow.listen((core.AddNewRow e) {
          final MapDataItem item = new MapDataItem({
            'id': 'new_${rnd.nextInt(10000)}',
            'indent': 0,
            'title': 'New task',
            'duration': '1 day',
            'percentComplete': 0,
            'start': '01/01/2009',
            'finish': '01/01/2009',
            'effortDriven': false
          });
          item.extend(e.item);
          dataView.addItem(item);
        });

        grid.onBwuClick.listen((core.Click e) {
          if ((e.causedBy.target as dom.Element).classes.contains('toggle')) {
            final DataItem item = dataView.getItem(e.cell.row);
            if (item != null) {
              item.collapsed = !item.collapsed;

              dataView.updateItem(item['id'], item);
            }
            e.stopImmediatePropagation();
          }
        });

        dataView.onBwuRowCountChanged.listen((core.RowCountChanged e) {
          grid.updateRowCount();
          grid.render();
        });

        dataView.onBwuRowsChanged.listen((core.RowsChanged e) {
          grid.invalidateRows(e.changedRows);
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

  @reflectable
  void searchStringChanged([_, __]) {
    if (dataView == null) {
      return;
    }
    updateFilter();
  }

  async.Timer _pendingUpdateFilter;
  @reflectable
  void percentCompleteThresholdChanged([_, __]) {
    if (dataView == null) {
      return;
    }
    if (_pendingUpdateFilter != null) {
      _pendingUpdateFilter.cancel();
    }

    _pendingUpdateFilter = new async.Timer(new Duration(milliseconds: 20), () {
      updateFilter();
      _pendingUpdateFilter = null;
    });
  }

  void updateFilter() {
    core.globalEditorLock.cancelCurrentEdit();

    if (searchString == null) {
      set('searchString', '');
    }

    if (percentCompleteThreshold == null) {
      set('percentCompleteThreshold', '0');
    }

    dataView.setFilterArgs({
      'percentCompleteThreshold':
          tools.parseInt(percentCompleteThreshold, onErrorDefault: 0),
      'searchString': searchString
    });
    dataView.refresh();
  }

  bool myFilter(DataItem item, Map args) {
    if (item['percentComplete'] < args['percentCompleteThreshold']) {
      return false;
    }

    if (args['searchString'] != '' &&
        (item['title'] as String).indexOf(args['searchString']) == -1) {
      return false;
    }

    if (item['parent'] != null) {
      DataItem parent = data[item['parent']];

      while (parent != null) {
        if (parent.collapsed ||
            (parent['percentComplete'] <
                tools.parseInt(percentCompleteThreshold, onErrorDefault: 0)) ||
            (searchString != '' &&
                (parent['title'] as String).indexOf(searchString) == -1)) {
          return false;
        }

        if (parent['parent'] != null) {
          parent = data[parent['parent']];
        } else {
          parent = null;
        }
      }
    }
    return true;
  }

  int percentCompleteSort(Map a, Map b) {
    return a['percentComplete'] - b['percentComplete'];
  }
}
