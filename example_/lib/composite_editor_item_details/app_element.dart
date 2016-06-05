@HtmlImport('app_element.html')
library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/formatters/formatters.dart' as fm;
import 'package:bwu_datagrid/editors/editors.dart';

import 'package:bwu_datagrid_examples/shared/required_field_validator.dart';
import 'package:bwu_datagrid_examples/shared/composite_editor.dart';
import 'package:bwu_datagrid/core/core.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/asset/example_style.dart';
// ignore: unused_import
import 'package:bwu_datagrid_examples/shared/options_panel.dart';
import 'composite_editor_view.dart';

@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  BwuDatagrid grid;
  final List<Column> columns = <Column>[
    new Column(
        id: "title",
        name: "Title",
        field: "title",
        width: 120,
        cssClass: "cell-title",
        editor: new TextEditor(),
        validator: new RequiredFieldValidator()),
    new Column(
        id: "desc",
        name: "Description",
        field: "description",
        width: 100,
        editor: new TextEditor()),
    new Column(
        id: "duration",
        name: "Duration",
        field: "duration",
        editor: new TextEditor()),
    new Column(
        id: "percent",
        name: "% Complete",
        field: "percentComplete",
        width: 80,
        resizable: false,
        formatter: new fm.PercentCompleteBarFormatter(),
        editor: new PercentCompleteEditor()),
    new Column(
        id: "start",
        name: "Start",
        field: "start",
        minWidth: 60,
        editor: new DateEditor()),
    new Column(
        id: "finish",
        name: "Finish",
        field: "finish",
        minWidth: 60,
        editor: new DateEditor()),
    new Column(
        id: "effort-driven",
        name: "Effort Driven",
        width: 80,
        minWidth: 20,
        maxWidth: 80,
        cssClass: "cell-effort-driven",
        field: "effortDriven",
        formatter: new fm.CheckmarkFormatter(),
        editor: new CheckboxEditor())
  ];

  final GridOptions gridOptions = new GridOptions(
      editable: true,
      enableAddRow: true,
      enableCellNavigation: true,
      asyncEditorLoading: false,
      autoEdit: false);

  math.Random rnd = new math.Random();

  MapDataItemProvider<ItemBase> data;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      data = new MapDataItemProvider<ItemBase>();
      for (int i = 0; i < 500; i++) {
        data.items.add(new MapDataItem(<String, dynamic>{
          'title': 'Task ${i}',
          'description':
              'This is a sample task description.\n  It can be multiline',
          'duration': '5 days',
          'percentComplete': rnd.nextInt(100),
          'start': '2009-01-01',
          'finish': '2009-01-05',
          'effortDriven': (i % 5 == 0)
        }));
      }

      grid.onBwuAddNewRow.listen(_addNewRowHandler);
      grid.onBwuValidationError.listen(_validationErrorHandler);

      grid
          .setup(dataProvider: data, columns: columns, gridOptions: gridOptions)
          .then((_) => grid.setActiveCell(0, 0));
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
  void openDetails(CustomEventWrapper e, [_]) {
    if (grid.getEditorLock.isActive &&
        !grid.getEditorLock.commitCurrentEdit()) {
      return;
    }

    final CompositeEditorView modal = new CompositeEditorView()
      //$("<div class='item-details-form'></div>");
      ..grid = grid
      ..setColumns(columns);
    dom.document.body.append(modal);

    final CompositeEditorOptions ceOptions = new CompositeEditorOptions(
        show: modal.show,
        hide: modal.hide,
        // position: $modal.position, positions the dialog with it's top/left corner above the current field
        destroy: modal.destroy);

    final Map<String, dom.Element> containers = <String, dom.Element>{};

    new async.Future<Null>(() {
      columns.forEach((Column c) => containers[c.id] =
          modal.shadowRoot.querySelector('[data-editorid="${c.id}"]'));

      final CompositeEditor compositeEditor =
          new CompositeEditor.prepare(columns, containers, ceOptions);
      compositeEditor.init();
      grid.editActiveCell(compositeEditor);
    });
  }

  void _addNewRowHandler(AddNewRow e) {
    final DataItem item = e.item;
//    var column = e.column;
    grid.invalidateRow(data.length);
    data.items.add(item);
    grid.updateRowCount();
    grid.render();
  }

  void _validationErrorHandler(ValidationError e) {
    // handle validation errors originating from the CompositeEditor
    if (e.editor != null && (e.editor is CompositeEditor)) {
//      var err;
      int idx = e.validationResults.errors.length;
      while (idx-- > 0) {
//        err = e.validationResults.errors[idx];
        // TODO err.container.stop(true, true).effect('highlight', {'color': 'red'});
      }
    }
  }
}
