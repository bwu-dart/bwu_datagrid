library bwu_datagrid.example.e07_events.context_menu;

import 'dart:html' as dom;
import 'dart:async' as async;

import 'package:polymer/polymer.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

@CustomTag('context-menu')
class ContextMenu extends PolymerElement {
  ContextMenu.created() : super.created();

  static const CONTEXT_MENU_SELECT = 'context-menu-select';
  static const dom.EventStreamProvider<dom.CustomEvent> _contextMenuSelect =
      const dom.EventStreamProvider<dom.CustomEvent>(CONTEXT_MENU_SELECT);

  async.Stream<dom.CustomEvent> get onContextMenuSelect =>
      ContextMenu._contextMenuSelect.forTarget(this);

  Cell cell;

  void attached() {
    super.attached();

    dom.document.body.onClick.listen((e) => hide());

    onClick.listen((e) {
      if (!(e.target is dom.LIElement)) {
        return;
      }
      fire(CONTEXT_MENU_SELECT, detail: ((e.target as dom.LIElement).attributes['value']));
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
