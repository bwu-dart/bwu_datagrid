@TestOn('browser')
library bwu_datagrid.test.dataview;

import 'package:polymer/polymer.dart';
import 'package:test/test.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
//import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';

import 'package:logging/logging.dart';
import 'package:quiver_log/log.dart';

final _log = new Logger('bwu_datagrid.test.dataview');

void assertEmpty(DataView dv) {
  expect(0, equals(dv.length),
      reason: ".rows is initialized to an empty array");
  expect(dv.getItems().length, equals(0), reason: "getItems().length");
  expect(dv.getIdxById("id"), isNull,
      reason: "getIdxById should return undefined if not found");
  expect(dv.getRowById("id"), isNull,
      reason: "getRowById should return undefined if not found");
  expect(dv.getItemById("id"), isNull,
      reason: "getItemById should return undefined if not found");
  expect(dv.getItemByIdx(0), isNull,
      reason: "getItemByIdx should return undefined if not found");
}

void assertConsistency(DataView dv, [String idProperty]) {
  if (idProperty == null || idProperty.isEmpty) {
    idProperty = "id";
  }
  List<core.ItemBase> items = dv.getItems();
  int filteredOut = 0;

  for (int i = 0; i < items.length; i++) {
    _log.fine(items[i][idProperty]);
    final id = items[i][idProperty];
    expect(dv.getItemByIdx(i), equals(items[i]), reason: "getItemByIdx");
    expect(dv.getItemById(id), equals(items[i]), reason: "getItemById");
    expect(dv.getIdxById(id), equals(i), reason: "getIdxById");

    final row = dv.getRowById(id);
    if (row == null) {
      filteredOut++;
    } else {
      expect(dv.getItem(row), equals(items[i]), reason: "getRowById");
    }
  }

  expect(items.length - dv.length, equals(filteredOut),
      reason: "filtered rows");
}

void main() {
  Logger.root.level = Level.ALL;
  new PrintAppender(BASIC_LOG_FORMATTER).attachLogger(_log);

  group('basic', () {
    test("initial setup", () {
      final dv = new DataView();
      assertEmpty(dv);
    });

    test("initial setup, refresh", () {
      final dv = new DataView();
      dv.refresh();
      assertEmpty(dv);
    });
  });

  group('setItems', () {
    test("empty", () {
      final dv = new DataView();
      dv.setItems([]);
      assertEmpty(dv);
    });

    test("basic", () {
      final dv = new DataView();
      dv.setItems([new MapDataItem({'id': 0}), new MapDataItem({'id': 1})]);
      expect(dv.length, equals(2), reason: "rows.length");
      expect(dv.getItems().length, equals(2), reason: "getItems().length");
      assertConsistency(dv);
    });

    test("alternative idProperty", () {
      final dv = new DataView();
      dv.setItems(<DataItem>[
        new MapDataItem({'uid': 0}),
        new MapDataItem({'uid': 1})
      ], "uid");
      assertConsistency(dv, "uid");
    });

    test("requires an id on objects", () {
      final dv = new DataView();
      expect(() => dv.setItems(<DataItem>[
        new MapDataItem({'a': 1}),
        new MapDataItem({'b': 2}),
        new MapDataItem({'c': 3})
      ]), throwsA(equals(
              "Each data element must implement a unique 'id' property")),
          reason: "exception expected");
    });

    test("requires a unique id on objects", () {
      final dv = new DataView();
      //        try {
      expect(() => dv.setItems(<DataItem>[
        new MapDataItem({'id': 0}),
        new MapDataItem({'id': 0})
      ]), throwsA(equals(
              "Each data element must implement a unique 'id' property")),
          reason: "exception expected");
    });

    test("requires a unique id on objects (alternative idProperty)", () {
      final dv = new DataView();
      expect(() => dv.setItems(<DataItem>[
        new MapDataItem({'uid': 0}),
        new MapDataItem({'uid': 0})
      ], "uid"), throwsA(
          equals("Each data element must implement a unique 'id' property")));
    });

    test("events fired on setItems", () {
      final dv = new DataView();

      final expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((e) {
        expectRowsChangedCalled();
      });

      final expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((e) {
        expect(e.oldCount, equals(0), reason: "previous arg");
        expect(e.newCount, equals(2), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(2), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });
      dv.setItems(
          <DataItem>[new MapDataItem({'id': 0}), new MapDataItem({'id': 1})]);
      dv.refresh();
    });

    test("no events on setItems([])", () {
      final dv = new DataView();
      dv.onBwuRowsChanged.first.then((e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first
          .then((e) => fail("onPagingInfoChanged called"));
      dv.setItems([]);
      dv.refresh();
    });

    test("no events on setItems followed by refresh", () {
      final dv = new DataView();
      dv.setItems(
          <DataItem>[new MapDataItem({'id': 0}), new MapDataItem({'id': 1})]);
      dv.onBwuRowsChanged.first.then((e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first
          .then((e) => fail("onPagingInfoChanged called"));
      dv.refresh();
    });

    test("no refresh while suspended", () {
      final dv = new DataView();
      dv.beginUpdate();
      dv.onBwuRowsChanged.first.then((e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first
          .then((e) => fail("onPagingInfoChanged called"));
      dv.setItems(
          <DataItem>[new MapDataItem({'id': 0}), new MapDataItem({'id': 1})]);
      dv.setFilter((a, b) => true);
      dv.refresh();
      expect(dv.length, equals(0), reason: "rows aren't updated until resumed");
    });

    test("refresh fires after resume", () {
      final dv = new DataView();
      dv.beginUpdate();
      dv.setItems(
          <DataItem>[new MapDataItem({'id': 0}), new MapDataItem({'id': 1})]);
      expect(dv.getItems().length, equals(2),
          reason: "items updated immediately");
      dv.setFilter((o, b) => true);
      dv.refresh();

      final expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((e) {
        expect(e.changedRows, equals([0, 1]), reason: "args");
        expectRowsChangedCalled();
      });

      final expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((e) {
        expect(e.oldCount, equals(0), reason: "previous arg");
        expect(e.newCount, equals(2), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(2), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });
      dv.endUpdate();
      expect(dv.getItems().length, equals(2), reason: "items are the same");
      expect(dv.length, equals(2), reason: "rows updated");
    });
  });

  group('sort', () {
    test("happy path", () {
      final itemsList = <DataItem>[
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 0, 'val': 0})
      ];

      final items = <DataItem>[itemsList[0], itemsList[1], itemsList[2]];
      final dv = new DataView();
      dv.setItems(items);

      dv.onBwuRowsChanged.first.then((e) => fail("onRowsChanged called"));

      dv.onBwuRowCountChanged.first
          .then((e) => fail("onRowCountChanged called"));

      dv.onBwuPagingInfoChanged.first
          .then((e) => fail("onPagingInfoChanged called"));
      dv.sort((x, y) => x['val'] - y['val'], true);
      expect(dv.getItems(), equals(items),
          reason: "original array should get sorted");
      expect(items, orderedEquals([itemsList[2], itemsList[1], itemsList[0]]),
          reason: "sort order");
      assertConsistency(dv);
    });

    test("asc by default", () {
      final itemsList = <DataItem>[
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 0, 'val': 0})
      ];
      final items = [itemsList[0], itemsList[1], itemsList[2]];
      final dv = new DataView();
      dv.setItems(items);
      dv.sort((x, y) => x['val'] - y['val']);
      expect(items, orderedEquals([itemsList[2], itemsList[1], itemsList[0]]),
          reason: "sort order");
    });

    test("desc", () {
      final itemsList = <DataItem>[
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
      ];
      final items = [itemsList[0], itemsList[1], itemsList[2]];
      final dv = new DataView();
      dv.setItems(items);
      dv.sort((x, y) => -1 * (x['val'] - y['val']));
      expect(items, orderedEquals([itemsList[1], itemsList[2], itemsList[0]]),
          reason: "sort order");
    });

    test("sort is stable", () {
      final itemsList = <DataItem>[
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 3, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
      ];
      final items = [itemsList[0], itemsList[1], itemsList[2], itemsList[3],];
      final dv = new DataView();
      dv.setItems(items);

      dv.sort((x, y) => x['val'] - y['val']);
      expect(items, orderedEquals(
              [itemsList[0], itemsList[3], itemsList[1], itemsList[2]]),
          reason: "sort order");

      dv.sort((x, y) => x['val'] - y['val']);
      expect(items, orderedEquals(
              [itemsList[0], itemsList[3], itemsList[1], itemsList[2]]),
          reason: "sorting on the same column again doesn't change the order");

      dv.sort((x, y) => -1 * (x['val'] - y['val']));
      expect(items, orderedEquals(
              [itemsList[1], itemsList[2], itemsList[3], itemsList[0]]),
          reason: "sort order");
    });
  });

  group("filtering", () {
    test("applied immediately", () {
      final dv = new DataView();

      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1})
      ]);

      final expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((e) {
        expectRowsChangedCalled();
        expect(e.changedRows, equals([0]), reason: "args");
      });

      final expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((e) {
        expectRowCountChangedCalled();
        expect(e.oldCount, equals(3), reason: "previous arg");
        expect(e.newCount, equals(1), reason: "current arg");
      });

      final expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((e) {
        expectPagingInfoChangedCalled();
        expect(e.pagingInfo.pageSize, 0, reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, 0, reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, 1, reason: "totalRows arg");
      });
      dv.setFilter((o, b) => o['val'] == 1);
      expect(dv.getItems().length, equals(3),
          reason: "original data is still there");
      expect(dv.length, equals(1), reason: "rows are filtered");
      assertConsistency(dv);
    });

    test("re-applied on refresh", () {
      final dv = new DataView();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      dv.setFilterArgs({'id': 0});
      dv.setFilter((o, args) => o['val'] >= args['id']);
      expect(dv.length, equals(3), reason: "nothing is filtered out");
      assertConsistency(dv);

      final expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((e) {
        expectRowsChangedCalled();
        expect(e.changedRows, equals([0]), reason: "args");
      });

      final expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((e) {
        expectRowCountChangedCalled();
        expect(e.oldCount, equals(3), reason: "previous arg");
        expect(e.newCount, equals(1), reason: "current arg");
      });

      final expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((e) {
        expectPagingInfoChangedCalled();
        expect(e.pagingInfo.pageSize, 0, reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, 0, reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, 1, reason: "totalRows arg");
      });

      dv.setFilterArgs({'id': 2});
      dv.refresh();
      expect(dv.getItems().length, 3, reason: "original data is still there");
      expect(dv.length, equals(1), reason: "rows are filtered");
      assertConsistency(dv);
    });
  });
}

//        final expectRowsChangedCalled =
//            expectAsync(() {}, reason: "onRowsChanged called");

//        final expectRowCountChangedCalled =
//        expectAsync(() {}, reason: "onRowCountChanged called");

//        final expectPagingInfoChangedCalled =
//          expectAsync(() {}, reason: "onPagingInfoChanged called");


//
//test("re-applied on sort", function() {
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.setFilter(function(o) { return o.val === 1; });
//    same(dv.getLength(), 1, "one row is remaining");
//
//    dv.onRowsChanged.subscribe(function() { ok(false, "onRowsChanged called") });
//    dv.onRowCountChanged.subscribe(function() { ok(false, "onRowCountChanged called") });
//    dv.onPagingInfoChanged.subscribe(function() { ok(false, "onPagingInfoChanged called") });
//    dv.sort(function(x,y) { return x.val-y.val; }, false);
//    same(dv.getItems().length, 3, "original data is still there");
//    same(dv.getLength(), 1, "rows are filtered");
//    assertConsistency(dv);
//});
//
//test("all", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(false, "onRowsChanged called");
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        same(args.previous, 3, "previous arg");
//        same(args.current, 0, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        same(args.pageSize, 0, "pageSize arg");
//        same(args.pageNum, 0, "pageNum arg");
//        same(args.totalRows, 0, "totalRows arg");
//        count++;
//    });
//    dv.setFilter(function(o) { return false; });
//    equal(count, 2, "events fired");
//    same(dv.getItems().length, 3, "original data is still there");
//    same(dv.getLength(), 0, "rows are filtered");
//    assertConsistency(dv);
//});
//
//test("all then none", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.setFilterArgs(false);
//    dv.setFilter(function(o, args) { return args; });
//    same(dv.getLength(), 0, "all rows are filtered out");
//
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[0,1,2]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        same(args.previous, 0, "previous arg");
//        same(args.current, 3, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        same(args.pageSize, 0, "pageSize arg");
//        same(args.pageNum, 0, "pageNum arg");
//        same(args.totalRows, 3, "totalRows arg");
//        count++;
//    });
//    dv.setFilterArgs(true);
//    dv.refresh();
//    equal(count, 3, "events fired");
//    same(dv.getItems().length, 3, "original data is still there");
//    same(dv.getLength(), 3, "all rows are back");
//    assertConsistency(dv);
//});
//
//test("inlining replaces absolute returns", function() {
//    var dv = new Slick.Data.DataView({ inlineFilters: true });
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.setFilter(function(o) {
//        if (o.val === 1) { return true; }
//        else if (o.val === 4) { return true }
//        return false});
//    same(dv.getLength(), 1, "one row is remaining");
//
//    dv.onRowsChanged.subscribe(function() { ok(false, "onRowsChanged called") });
//    dv.onRowCountChanged.subscribe(function() { ok(false, "onRowCountChanged called") });
//    dv.onPagingInfoChanged.subscribe(function() { ok(false, "onPagingInfoChanged called") });
//    same(dv.getItems().length, 3, "original data is still there");
//    same(dv.getLength(), 1, "rows are filtered");
//    assertConsistency(dv);
//});
//
//test("inlining replaces evaluated returns", function() {
//    var dv = new Slick.Data.DataView({ inlineFilters: true });
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.setFilter(function(o) {
//        if (o.val === 0) { return o.id === 2; }
//        else if (o.val === 1) { return o.id === 2 }
//        return o.val === 2});
//    same(dv.getLength(), 1, "one row is remaining");
//
//    dv.onRowsChanged.subscribe(function() { ok(false, "onRowsChanged called") });
//    dv.onRowCountChanged.subscribe(function() { ok(false, "onRowCountChanged called") });
//    dv.onPagingInfoChanged.subscribe(function() { ok(false, "onPagingInfoChanged called") });
//    same(dv.getItems().length, 3, "original data is still there");
//    same(dv.getLength(), 1, "rows are filtered");
//    assertConsistency(dv);
//});
//
//module("updateItem");
//
//test("basic", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[1]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(false, "onRowCountChanged called");
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(false, "onPagingInfoChanged called");
//    });
//
//    dv.updateItem(1,{id:1,val:1337});
//    equal(count, 1, "events fired");
//    same(dv.getItem(1), {id:1,val:1337}, "item updated");
//    assertConsistency(dv);
//});
//
//test("updating an item not passing the filter", function() {
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2},{id:3,val:1337}]);
//    dv.setFilter(function(o) { return o["val"] !== 1337; });
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(false, "onRowsChanged called");
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(false, "onRowCountChanged called");
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(false, "onPagingInfoChanged called");
//    });
//    dv.updateItem(3,{id:3,val:1337});
//    same(dv.getItems()[3], {id:3,val:1337}, "item updated");
//    assertConsistency(dv);
//});
//
//test("updating an item to pass the filter", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2},{id:3,val:1337}]);
//    dv.setFilter(function(o) { return o["val"] !== 1337; });
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[3]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 4, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        same(args.pageSize, 0, "pageSize arg");
//        same(args.pageNum, 0, "pageNum arg");
//        same(args.totalRows, 4, "totalRows arg");
//        count++;
//    });
//    dv.updateItem(3,{id:3,val:3});
//    equal(count, 3, "events fired");
//    same(dv.getItems()[3], {id:3,val:3}, "item updated");
//    assertConsistency(dv);
//});
//
//test("updating an item to not pass the filter", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2},{id:3,val:3}]);
//    dv.setFilter(function(o) { return o["val"] !== 1337; });
//    dv.onRowsChanged.subscribe(function(e,args) {
//        console.log(args)
//        ok(false, "onRowsChanged called");
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 4, "previous arg");
//        equal(args.current, 3, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        same(args.pageSize, 0, "pageSize arg");
//        same(args.pageNum, 0, "pageNum arg");
//        same(args.totalRows, 3, "totalRows arg");
//        count++;
//    });
//    dv.updateItem(3,{id:3,val:1337});
//    equal(count, 2, "events fired");
//    same(dv.getItems()[3], {id:3,val:1337}, "item updated");
//    assertConsistency(dv);
//});
//
//
//module("addItem");
//
//test("must have id", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    try {
//        dv.addItem({val:1337});
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//});
//
//test("must have id (custom)", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{uid:0,val:0},{uid:1,val:1},{uid:2,val:2}], "uid");
//    try {
//        dv.addItem({id:3,val:1337});
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//});
//
//test("basic", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[3]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 4, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        equal(args.pageSize, 0, "pageSize arg");
//        equal(args.pageNum, 0, "pageNum arg");
//        equal(args.totalRows, 4, "totalRows arg");
//        count++;
//    });
//    dv.addItem({id:3,val:1337});
//    equal(count, 3, "events fired");
//    same(dv.getItems()[3], {id:3,val:1337}, "item updated");
//    same(dv.getItem(3), {id:3,val:1337}, "item updated");
//    assertConsistency(dv);
//});
//
//test("add an item not passing the filter", function() {
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.setFilter(function(o) { return o["val"] !== 1337; });
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(false, "onRowsChanged called");
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(false, "onRowCountChanged called");
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(false, "onPagingInfoChanged called");
//    });
//    dv.addItem({id:3,val:1337});
//    same(dv.getItems()[3], {id:3,val:1337}, "item updated");
//    assertConsistency(dv);
//});
//
//module("insertItem");
//
//test("must have id", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    try {
//        dv.insertItem(0,{val:1337});
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//});
//
//test("must have id (custom)", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{uid:0,val:0},{uid:1,val:1},{uid:2,val:2}], "uid");
//    try {
//        dv.insertItem(0,{id:3,val:1337});
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//});
//
//test("insert at the beginning", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[0,1,2,3]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 4, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        equal(args.pageSize, 0, "pageSize arg");
//        equal(args.pageNum, 0, "pageNum arg");
//        equal(args.totalRows, 4, "totalRows arg");
//        count++;
//    });
//    dv.insertItem(0, {id:3,val:1337});
//    equal(count, 3, "events fired");
//    same(dv.getItem(0), {id:3,val:1337}, "item updated");
//    equal(dv.getItems().length, 4, "items updated");
//    equal(dv.getLength(), 4, "rows updated");
//    assertConsistency(dv);
//});
//
//test("insert in the middle", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[2,3]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 4, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        equal(args.pageSize, 0, "pageSize arg");
//        equal(args.pageNum, 0, "pageNum arg");
//        equal(args.totalRows, 4, "totalRows arg");
//        count++;
//    });
//    dv.insertItem(2,{id:3,val:1337});
//    equal(count, 3, "events fired");
//    same(dv.getItem(2), {id:3,val:1337}, "item updated");
//    equal(dv.getItems().length, 4, "items updated");
//    equal(dv.getLength(), 4, "rows updated");
//    assertConsistency(dv);
//});
//
//test("insert at the end", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[3]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 4, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        equal(args.pageSize, 0, "pageSize arg");
//        equal(args.pageNum, 0, "pageNum arg");
//        equal(args.totalRows, 4, "totalRows arg");
//        count++;
//    });
//    dv.insertItem(3,{id:3,val:1337});
//    equal(count, 3, "events fired");
//    same(dv.getItem(3), {id:3,val:1337}, "item updated");
//    equal(dv.getItems().length, 4, "items updated");
//    equal(dv.getLength(), 4, "rows updated");
//    assertConsistency(dv);
//});
//
//module("deleteItem");
//
//test("must have id", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:0,val:0},{id:1,val:1},{id:2,val:2}]);
//    try {
//        dv.deleteItem(-1);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//    try {
//        dv.deleteItem(undefined);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//    try {
//        dv.deleteItem(null);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//    try {
//        dv.deleteItem(3);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//});
//
//test("must have id (custom)", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{uid:0,id:-1,val:0},{uid:1,id:3,val:1},{uid:2,id:null,val:2}], "uid");
//    try {
//        dv.deleteItem(-1);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//    try {
//        dv.deleteItem(undefined);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//    try {
//        dv.deleteItem(null);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//    try {
//        dv.deleteItem(3);
//        ok(false, "exception thrown");
//    }
//    catch (ex) {}
//});
//
//test("delete at the beginning", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:05,val:0},{id:15,val:1},{id:25,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[0,1]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 2, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        equal(args.pageSize, 0, "pageSize arg");
//        equal(args.pageNum, 0, "pageNum arg");
//        equal(args.totalRows, 2, "totalRows arg");
//        count++;
//    });
//    dv.deleteItem(05);
//    equal(count, 3, "events fired");
//    equal(dv.getItems().length, 2, "items updated");
//    equal(dv.getLength(), 2, "rows updated");
//    assertConsistency(dv);
//});
//
//test("delete in the middle", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:05,val:0},{id:15,val:1},{id:25,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(true, "onRowsChanged called");
//        same(args, {rows:[1]}, "args");
//        count++;
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 2, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        equal(args.pageSize, 0, "pageSize arg");
//        equal(args.pageNum, 0, "pageNum arg");
//        equal(args.totalRows, 2, "totalRows arg");
//        count++;
//    });
//    dv.deleteItem(15);
//    equal(count, 3, "events fired");
//    equal(dv.getItems().length, 2, "items updated");
//    equal(dv.getLength(), 2, "rows updated");
//    assertConsistency(dv);
//});
//
//test("delete at the end", function() {
//    var count = 0;
//    var dv = new Slick.Data.DataView();
//    dv.setItems([{id:05,val:0},{id:15,val:1},{id:25,val:2}]);
//    dv.onRowsChanged.subscribe(function(e,args) {
//        ok(false, "onRowsChanged called");
//    });
//    dv.onRowCountChanged.subscribe(function(e,args) {
//        ok(true, "onRowCountChanged called");
//        equal(args.previous, 3, "previous arg");
//        equal(args.current, 2, "current arg");
//        count++;
//    });
//    dv.onPagingInfoChanged.subscribe(function(e,args) {
//        ok(true, "onPagingInfoChanged called");
//        equal(args.pageSize, 0, "pageSize arg");
//        equal(args.pageNum, 0, "pageNum arg");
//        equal(args.totalRows, 2, "totalRows arg");
//        count++;
//    });
//    dv.deleteItem(25);
//    equal(count, 2, "events fired");
//    equal(dv.getItems().length, 2, "items updated");
//    equal(dv.getLength(), 2, "rows updated");
//    assertConsistency(dv);
//});
//
//// TODO: paging
//// TODO: combination
//
//
//})(jQuery);
