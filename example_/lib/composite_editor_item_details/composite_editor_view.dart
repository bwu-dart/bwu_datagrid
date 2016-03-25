@HtmlImport('composite_editor_view.html')
library bwu_datagrid.context_menu;

import 'dart:html' as dom;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

@PolymerRegister('composite-editor-view')
class CompositeEditorView extends PolymerElement {
  factory CompositeEditorView() =>
      new dom.Element.tag('composite-editor-view') as CompositeEditorView;

  CompositeEditorView.created() : super.created();

  BwuDatagrid grid;
  @property
  List<Column> columns;
  void setColumns(List<Column> value) {
    async(() => set('columns', value));
  }

  void attached() {
    style.visibility = 'hidden';
    super.attached();
  }

  void show() {
    style.visibility = 'visible';
  }

  void hide() {
    style.visibility = 'hidden';
  }

  void position(NodeBox box) {
    style
      ..position = 'absolute'
      ..left = '${box.left}px'
      ..top = '${box.top}px';
  }

  void keyDownHandler(dom.KeyboardEvent e) {
    if (e.which == dom.KeyCode.ENTER) {
      grid.getEditController.commitCurrentEdit();
      e.stopPropagation();
      e.preventDefault();
    } else if (e.which == dom.KeyCode.ESC) {
      grid.getEditController.cancelCurrentEdit();
      e.stopPropagation();
      e.preventDefault();
    }
  }

  @reflectable
  void btnSaveHandler(dom.MouseEvent e, [_]) {
    grid.getEditController.commitCurrentEdit();
  }

  @reflectable
  void btnCancelHandler(dom.MouseEvent e, [_]) {
    grid.getEditController.cancelCurrentEdit();
  }

  void destroy() {
    this.remove();
  }
}
