library bwu_datagrid.example.src.e08_alternative_display.filter_form;

//import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

@CustomTag('row-item')
class RowItem extends PolymerElement {
  RowItem.created() : super.created();

  set data(MapDataItem d) {
    d.keys.forEach((e) {
      $[e].text = d[e];
    });
  }
}
