library bwu_dart.bwu_datagrid.remote_model;

import 'dart:html' as dom;
import 'dart:async' as async;
import 'dart:math' as math;

import 'package:bwu_datagrid/dataview/dataview.dart';

/***
 * A sample AJAX data store implementation.
 * Right now, it's hooked up to load Hackernews stories, but can
 * easily be extended to support any JSONP-compatible backend that accepts paging parameters.
 */
class RemoteModel {
  // private
  int PAGESIZE = 50;
  Map data = {'length': 0};
  String searchstr = "";
  int sortcol = null;
  int sortdir = 1;
  async.Timer h_request = null;
  var req = null; // ajax request

  // events
  var onDataLoading = new Event();
  var onDataLoaded = new Event();


  void init() {
  }


  bool isDataLoaded(int from, int to) {
    for (var i = from; i <= to; i++) {
      if (data[i] == null) {
        return false;
      }
    }

    return true;
  }


  void clear() {
    for (final key in data) {
      data.remove(key);
    }
    data['length'] = 0;
  }


  void ensureData(int from, int to) {
    if (req != null) {
      req.abort();
      for (var i = req.fromPage; i <= req.toPage; i++)
        data[i * PAGESIZE] = null;
    }

    if (from < 0) {
      from = 0;
    }

    if (data.length > 0) {
      to = math.min(to, data.length - 1);
    }

    var fromPage = (from / PAGESIZE).floor();
    var toPage = (to / PAGESIZE).floor();

    while (data[fromPage * PAGESIZE] != null && fromPage < toPage)
      fromPage++;

    while (data[toPage * PAGESIZE] != null && fromPage < toPage)
      toPage--;

    if (fromPage > toPage || ((fromPage == toPage) && data[fromPage * PAGESIZE] != null)) {
      // TODO:  look-ahead
      onDataLoaded.notify({from: from, to: to});
      return;
    }

    var url = "http://api.thriftdb.com/api.hnsearch.com/items/_search?filter[fields][type][]=submission&q=" + searchstr + "&start=" + (fromPage * PAGESIZE) + "&limit=" + (((toPage - fromPage) * PAGESIZE) + PAGESIZE);

    if (sortcol != null) {
        url += ("&sortby=${sortcol}${sortdir > 0 ? '+asc' : '+desc'}");
    }

    if (h_request != null) {
      h_request.cancel();
      h_request = null;
    }

    h_request = new async.Timer(new Duration(milliseconds: 50), () {
      for (var i = fromPage; i <= toPage; i++)
        data[i * PAGESIZE] = null; // null indicates a 'requested but not available yet'

      onDataLoading.notify({from: from, to: to});

      req = $.jsonp({
        'url': url,
        'callbackParameter': "callback",
        'cache': true,
        'success': onSuccess,
        'error': () {
          onError(fromPage, toPage);
        }
      });
      req.fromPage = fromPage;
      req.toPage = toPage;
    });
  }


  void onError(fromPage, toPage) {
    dom.window.alert("error loading pages ${fromPage} to ${toPage}");
  }

  void onSuccess(int resp) {
    var from = resp.request.start, to = from + resp.results.length;
    data['length'] = math.min(int.parse(resp.hits),1000); // limitation of the API

    for (var i = 0; i < resp.results.length; i++) {
      var item = resp.results[i].item;

      // Old IE versions can't parse ISO dates, so change to universally-supported format.
      item.create_ts = item.create_ts.replace(new RegExp(r"^(\d+)-(\d+)-(\d+)T(\d+:\d+:\d+)Z$"), "\$2/\$3/\$1 \$4 UTC"); // TODO
      item.create_ts = new DateTime(item.create_ts);

      data[from + i] = item;
      data[from + i].index = from + i;
    }

    req = null;

    onDataLoaded.notify({from: from, to: to});
  }


  void reloadData(int from, int to) {
    for (var i = from; i <= to; i++)
      data.remove(i); // TODO was delete data[i]

    ensureData(from, to);
  }


  void setSort(int column, int dir) {
    sortcol = column;
    sortdir = dir;
    clear();
  }

  void setSearch(String str) {
    searchstr = str;
    clear();
  }


//  return {
//    // properties
//    "data": data,
//
//    // methods
//    "clear": clear,
//    "isDataLoaded": isDataLoaded,
//    "ensureData": ensureData,
//    "reloadData": reloadData,
//    "setSort": setSort,
//    "setSearch": setSearch,
//
//    // events
//    "onDataLoading": onDataLoading,
//    "onDataLoaded": onDataLoaded
//  };
}

  // Slick.Data.RemoteModel
//  $.extend(true, window, { Slick: { Data: { RemoteModel: RemoteModel }}});
