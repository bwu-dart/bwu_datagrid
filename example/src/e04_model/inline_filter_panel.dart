library bwu_datagrid.example.e04_model.inline_filter_panel;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';

@CustomTag('inline-filter-panel')
class InlineFilterPanel extends PolymerElement {
  InlineFilterPanel.created() : super.created();

  @published String threshold = '0';
  @published String searchString = '';

  void clearSearch(dom.KeyboardEvent e, detail, dom.HtmlElement target) {
    if(e.which == dom.KeyCode.ESC) {
      searchString = '';
    }
  }
}