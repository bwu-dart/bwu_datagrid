@HtmlImport('inline_filter_panel.html')
library bwu_datagrid_examples.e04_model.inline_filter_panel;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

@PolymerRegister('inline-filter-panel')
class InlineFilterPanel extends PolymerElement {
  InlineFilterPanel.created() : super.created();

  @Property(notify: true)
  String threshold = '0';

  @Property(notify: true)
  String searchString = '';

  @reflectable
  void clearSearch(CustomEventWrapper e, [_]) {
    if ((e.original as dom.KeyboardEvent).keyCode == dom.KeyCode.ESC) {
      set('searchString', '');
    }
  }
}
