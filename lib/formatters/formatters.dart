library bwu_dart.bwu_datagrid.formatters;

import 'package:bwu_datagrid/datagrid/helpers.dart';

/***
 * Contains basic BwuDatagrid formatters.
 *
 * NOTE:  These are merely examples.  You will most likely need to implement something more
 *        robust/extensible/localizable/etc. for your use!
 *
 * @module Formatters
 * @namespace Slick
 */

//(function ($) {
//  // register namespace
//  $.extend(true, window, {
//    "Slick": {
//      "Formatters": {
//        "PercentComplete": PercentCompleteFormatter,
//        "PercentCompleteBar": PercentCompleteBarFormatter,
//        "YesNo": YesNoFormatter,
//        "Checkmark": CheckmarkFormatter
//      }
//    }
//  });

abstract class Formatter {
}

class PercentCompleteFormatter extends Formatter {

  String call(int row, int cell, int value, Column columnDef, int dataContext) {
    if (value == null || value == "") {
      return "-";
    } else if (value < 50) {
      return "<span style='color:red;font-weight:bold;'>${value}%</span>";
    } else {
      return "<span style='color:green'>${value}%</span>";
    }
  }
}

class PercentCompleteBarFormatter extends Formatter {

  String call(int row, int cell, int value, ColumnDefinition columnDef, int dataContext) {
    if (value == null || value == "") {
      return "";
    }

    var color;

    if (value < 30) {
      color = "red";
    } else if (value < 70) {
      color = "silver";
    } else {
      color = "green";
    }

    return "<span class='percent-complete-bar' style='background:" + color + ";width:${value}%'></span>";
  }
}

class YesNoFormatter extends Formatter {
  String call(int row, int cell, bool value, ColumnDefinition columnDef, int dataContext) {
    return value ? "Yes" : "No";
  }
}

class CheckmarkFormatter extends Formatter {
  String call(int row, int cell, bool value, ColumnDefinition columnDef, int dataContext) {
    return value ? "<img src='../images/tick.png'>" : "";
  }
}
