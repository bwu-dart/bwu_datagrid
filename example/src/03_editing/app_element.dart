library app_element;

import 'dart:math' as math;
import 'dart:html' as dom;
import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart';

class RequiredFieldValidator extends Validator {
  ValidationResult call(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return new ValidationResult(false, 'This is a required field');
    } else {
      return new ValidationResult(true);
    }
  }
}

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  List<Column> columns = [
    new Column(id: "title", name: "Title", field: "title", width: 120, cssClass: "cell-title", editor: new TextEditor(), validator: new RequiredFieldValidator()),
    new Column(id: "desc", name: "Description", field: "description", width: 100, editor: new LongTextEditor()),
    new Column(id: "duration", name: "Duration", field: "duration", editor: new TextEditor()),
    new Column(id: "%", name: "% Complete", field: "percentComplete", width: 80, resizable: false, formatter: new fm.PercentCompleteBarFormatter(), editor: new PercentCompleteEditor()),
    new Column(id: "start", name: "Start", field: "start", width: 120, minWidth: 60, editor: new DateEditor()),
    new Column(id: "finish", name: "Finish", field: "finish", width: 120, minWidth: 60, editor: new DateEditor()),
    new Column(id: "effort-driven", name: "Effort Driven", width: 80, minWidth: 20, maxWidth: 80, cssClass: "cell-effort-driven", field: "effortDriven", formatter: new fm.CheckmarkFormatter(), editor: new CheckboxEditor())
  ];

  var gridOptions = new GridOptions(
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      autoEdit: false
  );

  @override
  void enteredView() {
    super.enteredView();
    grid = $['myGrid'];

    try {
      var data = new List<Map>(500);
      for (var i = 0; i < 500; i++) {
        data[i] = {
          'title': 'Task ${i}',
          'description': 'This is a sample task description.\n  It can be multiline',
          'duration': '5 days',
          'percentComplete': new math.Random().nextInt(100),
          'start': '2009-01-01',
          'finish': '2009-01-05',
          'effortDriven': (i % 5 == 0)
        };
      }

      grid.data = data;
      grid.columns = columns;
      grid.gridOptions = gridOptions;

    } on NoSuchMethodError catch (e) {
      print('$e\n\n${e.stackTrace}');
    }  on RangeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on TypeError catch(e) {
      print('$e\n\n${e.stackTrace}');
    } catch(e) {
      print('$e');
      //print(s);
    }
  }

  void enableAutoEdit(dom.MouseEvent e, dynamic details, dom.HtmlElement target) {
    grid.setGridOptions = new GridOptions.unitialized()..autoEdit = true;
  }
  void disableAutoEdit(dom.MouseEvent e, dynamic details, dom.HtmlElement target) {
    grid.setGridOptions = new GridOptions.unitialized()..autoEdit = false;
  }
}