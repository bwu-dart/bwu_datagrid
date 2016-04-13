library bwu_datagrid.formatters;

import 'dart:html' as dom;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart' as core;

/// Contains basic BwuDatagrid formatters.
///
/// NOTE:  These are merely examples.  You will most likely need to implement something more
///        robust/extensible/localizable/etc. for your use!
///
/// @module Formatters
/// @namespace Slick

class DefaultFormatter extends CellFormatter {
  @override
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase dataContext) {
    target.children.clear();
    if (value != null) {
      target.text =
          '${value}'; //('$value'.replaceAll(r'&',"&amp;").replaceAll(r'<',"&lt;").replaceAll(r'>',"&gt;"));
    }
  }
}

abstract class Formatter {}

abstract class CellFormatter extends Formatter {
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase dataContext);
}

abstract class GroupTitleFormatter extends Formatter {
  dom.Node format(core.Group totals);
}

class PercentCompleteFormatter extends CellFormatter {
  @override
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase dataContext) {
    target.children.clear();
    if (value == null || value == "") {
      target.text = '-';
    } else if (value < 50) {
      target.append(new dom.SpanElement()
        ..style.color = 'red'
        ..style.fontWeight = 'bold'
        ..text = '${value}%');
    } else {
      target.appendHtml("<span style='color:green'>${value}%</span>");
    }
  }
}

class PercentCompleteBarFormatter extends CellFormatter {
  @override
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase dataContext) {
    if (value == null || value == "") {
      //target.text = '';
      value = 0;
    }

    String color;

    if (value < 30) {
      color = 'red';
    } else if (value < 70) {
      color = 'silver';
    } else {
      color = 'green';
    }

    target.children.clear();
    target.append(new dom.SpanElement()
      ..classes.add('percent-complete-bar')
      ..style.background = color
      ..style.width = '${value}%');
  }
}

class YesNoFormatter extends CellFormatter {
  @override
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase dataContext) {
    target.text = value ? 'Yes' : 'No';
  }
}

class CheckmarkFormatter extends CellFormatter {
  @override
  void format(dom.Element target, int row, int cell, dynamic value,
      Column columnDef, core.ItemBase dataContext) {
    target.children.clear();
    if (value != null && value is bool && value) {
      target.append(new dom.ImageElement(
          src: 'packages/bwu_datagrid/asset/images/tick.png'));
    }
  }
}
