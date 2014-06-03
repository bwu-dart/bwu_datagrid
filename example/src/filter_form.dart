library bwu_datagrid.example.e04_model.filter_form;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';


@CustomTag('filter-form')
class FilterForm extends PolymerElement {
  FilterForm.created() : super.created();

  @published String threshold = '0';
  @published String searchString = '';

  void clearSearch(dom.KeyboardEvent e, detail, dom.HtmlElement target) {
    if(e.which == dom.KeyCode.ESC) {
      searchString = '';
    }
  }
}
