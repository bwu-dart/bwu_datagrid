@HtmlImport('context_menu.html')
library bwu_datagrid_examples.e07_events.context_menu;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_datagrid/datagrid/helpers.dart';

@PolymerRegister('context-menu')
class ContextMenu extends PolymerElement {
  ContextMenu.created() : super.created();

  static const String contextMenuSelect = 'context-menu-select';
  static const dom.EventStreamProvider<dom.CustomEvent> _contextMenuSelect =
      const dom.EventStreamProvider<dom.CustomEvent>(contextMenuSelect);

  async.Stream<dom.CustomEvent> get onContextMenuSelect =>
      ContextMenu._contextMenuSelect.forTarget(this);

  Cell cell;

  void attached() {
    super.attached();

    dom.document.body.onClick.listen((_) => hide());

    onClick.listen((dom.MouseEvent e) {
      if (!(e.target is dom.LIElement)) {
        return;
      }
      fire(contextMenuSelect,
          detail: ((e.target as dom.LIElement).attributes['value']));
    });
  }

  void show() {
    style.display = 'inline-block';
  }

  void hide() {
    style.display = 'none';
  }

  void setPosition(int x, int y) {
    style
      ..position = 'absolute'
      ..left = '${x}px'
      ..top = '${y}px';
  }
}
