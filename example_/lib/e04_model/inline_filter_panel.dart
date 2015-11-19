@HtmlImport('inline_filter_panel.html')
library bwu_datagrid_examples.e04_model.inline_filter_panel;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

@PolymerRegister('inline-filter-panel')
class InlineFilterPanel extends PolymerElement {
  InlineFilterPanel.created() : super.created();

  @property String threshold = '0';
  @property String searchString = '';

  void clearSearch(dom.KeyboardEvent e, detail, dom.Element target) {
    if (e.which == dom.KeyCode.ESC) {
      searchString = '';
    }
  }
}
