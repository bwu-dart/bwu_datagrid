@HtmlImport('filter_form.html')
library bwu_datagrid_examples.shared.filter_form;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

@PolymerRegister('filter-form')
class FilterForm extends PolymerElement {
  FilterForm.created() : super.created();

  @Property(notify: true) String threshold = '0';
  @Property(notify: true) String searchString = '';

  @reflectable
  void clearSearch(dom.KeyboardEvent e, [_]) {
    if (e.which == dom.KeyCode.ESC) {
      set('searchString', '');
    }
  }
}
