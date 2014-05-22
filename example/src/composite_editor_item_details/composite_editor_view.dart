library bwu_datagrid.context_menu;

import 'dart:html' as dom;

import 'package:polymer/polymer.dart';

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

@CustomTag('composite-editor-view')
class CompositeEditorView extends PolymerElement {
  CompositeEditorView.created() : super.created();

  BwuDatagrid grid;
  @observable List<Column> columns;

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

  void btnSaveHandler(dom.MouseEvent e, detail, dom.HtmlElement target) {
    grid.getEditController.commitCurrentEdit();
  }

  void btnCancelHandler(dom.MouseEvent e, detail, dom.HtmlElement target) {
    grid.getEditController.cancelCurrentEdit();
  }

  void destroy() {
    this.remove();
  }
}

