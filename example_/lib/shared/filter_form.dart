@HtmlImport('filter_form.html')
library bwu_datagrid_examples.shared.filter_form;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

@PolymerRegister('filter-form')
class FilterForm extends PolymerElement {
  FilterForm.created() : super.created();

  @property String threshold = '0';
  @property String searchString = '';

  void clearSearch(dom.KeyboardEvent e, Object detail, dom.Element target) {
    if (e.which == dom.KeyCode.ESC) {
      searchString = '';
    }
  }
}
