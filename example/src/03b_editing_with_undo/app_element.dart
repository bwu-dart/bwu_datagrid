library app_element;

import 'dart:math' as math;
import 'dart:html' as dom;
import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart';
import '../required_field_validator.dart';
import 'package:bwu_datagrid/core/core.dart';


@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
      new Column(id: "title", name: "Title", field: "title", width: 120, cssClass: "cell-title", editor: new TextEditor(), validator: new RequiredFieldValidator()),
      new Column(id: "desc", name: "Description", field: "description", width: 100, editor: new LongTextEditor()),
      new Column(id: "duration", name: "Duration", field: "duration", editor: new TextEditor()),
      new Column(id: "%", name: "% Complete", field: "percentComplete", width: 80, resizable: false, formatter: new fm.PercentCompleteBarFormatter(), editor: new PercentCompleteEditor()),
      new Column(id: "start", name: "Start", field: "start", minWidth: 60, editor: new DateEditor()),
      new Column(id: "finish", name: "Finish", field: "finish", minWidth: 60, editor: new DateEditor()),
      new Column(id: "effort-driven", name: "Effort Driven", width: 80, minWidth: 20, maxWidth: 80, cssClass: "cell-effort-driven", field: "effortDriven", formatter: new fm.CheckmarkFormatter(), editor: new CheckboxEditor())
  ];

  var gridOptions = new GridOptions(
      editable: true,
      enableAddRow: false,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      autoEdit: false
  );

  List<EditCommand> _commandQueue = <EditCommand>[];

  bool get isUndoItem => !_commandQueue.isEmpty;

  void queueAndExecuteCommand(/*Item/Map*/ item, Column column, EditCommand editCommand) {
    var oldValue = isUndoItem;
    _commandQueue.add(editCommand);
    editCommand.execute();
    notifyPropertyChange(#isUndoItem, oldValue, isUndoItem);
  }

  void undo(dom.MouseEvent e, detail, dom.HtmlElement target) {
    var oldValue = isUndoItem;
    var command = _commandQueue.removeLast();
    if (command != null && globalEditorLock.cancelCurrentEdit()) {
      command.undo();
      grid.gotoCell(command.row, command.cell, false);
    }
    notifyPropertyChange(#isUndoItem, oldValue, isUndoItem);
  }

  @override
  void attached() {
    super.attached();

    try {
      gridOptions.editCommandHandler = queueAndExecuteCommand;

      grid = $['myGrid'];
      var data = new MapDataItemProvider();
      for (var i = 0; i < 500; i++) {
        data.items.add(new MapDataItem({
          'title': 'Task ${i}',
          "description": 'This is a sample task description.\n  It can be multiline',
          'duration': '5 days',
          'percentComplete': new math.Random().nextInt(100).round(),
          'start': '2009-01-01',
          'finish': '2009-01-05',
          'effortDriven': (i % 5 == 0)
        }));
      }

      grid.setup(dataProvider: data, columns: columns, gridOptions: gridOptions);

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
