@TestOn('browser')
library bwu_datagrid.test.dataview;

import 'package:test/test.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
//import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';

import 'package:logging/logging.dart';
import 'package:quiver_log/log.dart';

final Logger _log = new Logger('bwu_datagrid.test.dataview');

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

void assertConsistency(DataView<DataItem> dv, [String idProperty]) {
  if (idProperty == null || idProperty.isEmpty) {
    idProperty = "id";
  }
  List<DataItem> items = dv.getItems();
  int filteredOut = 0;

  for (int i = 0; i < items.length; i++) {
    _log.fine(items[i][idProperty]);
    final Object id = items[i][idProperty];
    expect(dv.getItemByIdx(i), equals(items[i]), reason: "getItemByIdx");
    expect(dv.getItemById(id), equals(items[i]), reason: "getItemById");
    expect(dv.getIdxById(id), equals(i), reason: "getIdxById");

    final int row = dv.getRowById(id);
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
      final DataView dv = new DataView();
      assertEmpty(dv);
    });

    test("initial setup, refresh", () {
      final DataView dv = new DataView();
      dv.refresh();
      assertEmpty(dv);
    });
  });

  group('setItems', () {
    test("empty", () {
      final DataView dv = new DataView();
      dv.setItems([]);
      assertEmpty(dv);
    });

    test("basic", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0}),
        new MapDataItem({'id': 1})
      ]);
      expect(dv.length, equals(2), reason: "rows.length");
      expect(dv.getItems().length, equals(2), reason: "getItems().length");
      assertConsistency(dv);
    });

    test("alternative idProperty", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems(<DataItem>[
        new MapDataItem({'uid': 0}),
        new MapDataItem({'uid': 1})
      ], "uid");
      assertConsistency(dv, "uid");
    });

    test("requires an id on objects", () {
      final DataView dv = new DataView();
      expect(
          () => dv.setItems(<DataItem>[
                new MapDataItem({'a': 1}),
                new MapDataItem({'b': 2}),
                new MapDataItem({'c': 3})
              ]),
          throwsA(equals(
              "Each data element must implement a unique 'id' property")),
          reason: "exception expected");
    });

    test("requires a unique id on objects", () {
      final DataView dv = new DataView();
      //        try {
      expect(
          () => dv.setItems(<DataItem>[
                new MapDataItem({'id': 0}),
                new MapDataItem({'id': 0})
              ]),
          throwsA(equals(
              "Each data element must implement a unique 'id' property")),
          reason: "exception expected");
    });

    test("requires a unique id on objects (alternative idProperty)", () {
      final DataView dv = new DataView();
      expect(
          () => dv.setItems(<DataItem>[
                new MapDataItem({'uid': 0}),
                new MapDataItem({'uid': 0})
              ], "uid"),
          throwsA(equals(
              "Each data element must implement a unique 'id' property")));
    });

    test("events fired on setItems", () {
      final DataView dv = new DataView();

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expectRowsChangedCalled();
      });

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expect(e.oldCount, equals(0), reason: "previous arg");
        expect(e.newCount, equals(2), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(2), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });
      dv.setItems(<DataItem>[
        new MapDataItem({'id': 0}),
        new MapDataItem({'id': 1})
      ]);
      dv.refresh();
    });

    test("no events on setItems([])", () {
      final DataView dv = new DataView();
      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      dv.setItems([]);
      dv.refresh();
    });

    test("no events on setItems followed by refresh", () {
      final DataView dv = new DataView();
      dv.setItems(<DataItem>[
        new MapDataItem({'id': 0}),
        new MapDataItem({'id': 1})
      ]);
      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      dv.refresh();
    });

    test("no refresh while suspended", () {
      final DataView dv = new DataView();
      dv.beginUpdate();
      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      dv.setItems(<DataItem>[
        new MapDataItem({'id': 0}),
        new MapDataItem({'id': 1})
      ]);
      dv.setFilter((_, __) => true);
      dv.refresh();
      expect(dv.length, equals(0), reason: "rows aren't updated until resumed");
    });

    test("refresh fires after resume", () {
      final DataView dv = new DataView();
      dv.beginUpdate();
      dv.setItems(<DataItem>[
        new MapDataItem({'id': 0}),
        new MapDataItem({'id': 1})
      ]);
      expect(dv.getItems().length, equals(2),
          reason: "items updated immediately");
      dv.setFilter((_, __) => true);
      dv.refresh();

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expect(e.changedRows, equals([0, 1]), reason: "args");
        expectRowsChangedCalled();
      });

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expect(e.oldCount, equals(0), reason: "previous arg");
        expect(e.newCount, equals(2), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
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
      final List<DataItem> itemsList = <DataItem>[
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 0, 'val': 0})
      ];

      final List<DataItem> items = <DataItem>[
        itemsList[0],
        itemsList[1],
        itemsList[2]
      ];
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems(items);

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => expectRowsChangedCalled());

      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));

      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      dv.sort((core.ItemBase x, core.ItemBase y) => x['val'] - y['val'] as int,
          true);
      expect(dv.getItems(), equals(items),
          reason: "original array should get sorted");
      expect(items, orderedEquals([itemsList[2], itemsList[1], itemsList[0]]),
          reason: "sort order");
      assertConsistency(dv);
    });

    test("asc by default", () {
      final List<DataItem> itemsList = <DataItem>[
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 0, 'val': 0})
      ];
      final List<DataItem> items = [itemsList[0], itemsList[1], itemsList[2]];
      final DataView dv = new DataView();
      dv.setItems(items);
      dv.sort((core.ItemBase x, core.ItemBase y) => x['val'] - y['val'] as int);
      expect(items, orderedEquals([itemsList[2], itemsList[1], itemsList[0]]),
          reason: "sort order");
    });

    test("desc", () {
      final List<DataItem> itemsList = <DataItem>[
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
      ];
      final List<DataItem> items = [itemsList[0], itemsList[1], itemsList[2]];
      final DataView dv = new DataView();
      dv.setItems(items);
      dv.sort((core.ItemBase x, core.ItemBase y) =>
          -1 * (x['val'] - y['val'] as int));
      expect(items, orderedEquals([itemsList[1], itemsList[2], itemsList[0]]),
          reason: "sort order");
    });

    test("sort is stable", () {
      final List<DataItem> itemsList = <DataItem>[
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 3, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1}),
      ];
      final List<DataItem> items = [
        itemsList[0],
        itemsList[1],
        itemsList[2],
        itemsList[3],
      ];
      final DataView dv = new DataView();
      dv.setItems(items);

      dv.sort((core.ItemBase x, core.ItemBase y) => x['val'] - y['val'] as int);
      expect(
          items,
          orderedEquals(
              [itemsList[0], itemsList[3], itemsList[1], itemsList[2]]),
          reason: "sort order");

      dv.sort((core.ItemBase x, core.ItemBase y) => x['val'] - y['val'] as int);
      expect(
          items,
          orderedEquals(
              [itemsList[0], itemsList[3], itemsList[1], itemsList[2]]),
          reason: "sorting on the same column again doesn't change the order");

      dv.sort((core.ItemBase x, core.ItemBase y) =>
          -1 * (x['val'] - y['val'] as int));
      expect(
          items,
          orderedEquals(
              [itemsList[1], itemsList[2], itemsList[3], itemsList[0]]),
          reason: "sort order");
    });
  });

  group("filtering", () {
    test("applied immediately", () {
      final DataView<DataItem> dv = new DataView<DataItem>();

      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 1, 'val': 1})
      ]);

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expectRowsChangedCalled();
        expect(e.changedRows, equals([0]), reason: "args");
      });

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expectRowCountChangedCalled();
        expect(e.oldCount, equals(3), reason: "previous arg");
        expect(e.newCount, equals(1), reason: "current arg");
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
        expectPagingInfoChangedCalled();
        expect(e.pagingInfo.pageSize, 0, reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, 0, reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, 1, reason: "totalRows arg");
      });
      dv.setFilter((core.ItemBase o, _) => o['val'] == 1);
      expect(dv.getItems().length, equals(3),
          reason: "original data is still there");
      expect(dv.length, equals(1), reason: "rows are filtered");
      assertConsistency(dv);
    });

    test("re-applied on refresh", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      dv.setFilterArgs({'id': 0});
      dv.setFilter((dynamic o, dynamic args) => o['val'] >= args['id']);
      expect(dv.length, equals(3), reason: "nothing is filtered out");
      assertConsistency(dv);

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expectRowsChangedCalled();
        expect(e.changedRows, equals([0]), reason: "args");
      });

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expectRowCountChangedCalled();
        expect(e.oldCount, equals(3), reason: "previous arg");
        expect(e.newCount, equals(1), reason: "current arg");
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
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

    test("re-applied on sort", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      dv.setFilter((dynamic o, _) => o['val'] == 1);
      expect(dv.length, equals(1), reason: "one row is remaining");

      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      dv.sort((core.ItemBase x, core.ItemBase y) => x['val'] - y['val'] as int,
          false);
      expect(dv.getItems().length, equals(3),
          reason: "original data is still there");
      expect(dv.length, equals(1), reason: "rows are filtered");
      assertConsistency(dv);
    });

    test("all", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);

      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expect(e.oldCount, equals(3), reason: "previous arg");
        expect(e.newCount, equals(0), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(0), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });

      dv.setFilter((_, __) => false);
      expect(dv.getItems().length, equals(3),
          reason: "original data is still there");
      expect(dv.length, equals(0), reason: "rows are filtered");
      assertConsistency(dv);
    });

    test("all then none", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      dv.setFilterArgs({'value': false});
      dv.setFilter((dynamic o, dynamic args) => args['value']);
      expect(dv.length, equals(0), reason: "all rows are filtered out");

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expect(e.changedRows, equals([0, 1, 2]), reason: "args");
        expectRowsChangedCalled();
      });

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expect(e.oldCount, equals(0), reason: "previous arg");
        expect(e.newCount, equals(3), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(3), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });
      dv.setFilterArgs({'value': true});
      dv.refresh();
      expect(dv.getItems().length, equals(3),
          reason: "original data is still there");
      expect(dv.length, equals(3), reason: "all rows are back");
      assertConsistency(dv);
    });

    test("inlining replaces absolute returns", () {
      final DataView<DataItem> dv =
          new DataView<DataItem>(options: new DataViewOptions(inlineFilters: true));
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      dv.setFilter((dynamic o, _) {
        if (o['val'] == 1) {
          return true;
        } else if (o['val'] == 4) {
          return true;
        }
        return false;
      } as FilterFn);
      expect(dv.length, equals(1), reason: "one row is remaining");

      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      expect(dv.getItems().length, equals(3),
          reason: "original data is still there");
      expect(dv.length, equals(1), reason: "rows are filtered");
      assertConsistency(dv);
    });

    test("inlining replaces evaluated returns", () {
      final DataView<DataItem> dv =
          new DataView<DataItem>(options: new DataViewOptions(inlineFilters: true));
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      dv.setFilter((Map o, _) {
        if (o['val'] == 0) {
          return o['id'] == 2;
        } else if (o['val'] == 1) {
          return o['id'] == 2;
        }
        return o['val'] == 2;
      } as FilterFn);
      expect(dv.length, equals(1), reason: "one row is remaining");

      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      expect(dv.getItems().length, equals(3),
          reason: "original data is still there");
      expect(dv.length, equals(1), reason: "rows are filtered");
      assertConsistency(dv);
    });
  });

  group("updateItem", () {
    test("basic", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expect(e.changedRows, equals([1]), reason: "args");
        expectRowsChangedCalled();
      });
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));

      dv.updateItem(1, new MapDataItem({'id': 1, 'val': 1337}));
      expect(dv.getItem(1), equals(new MapDataItem({'id': 1, 'val': 1337})),
          reason: "item updated");
      assertConsistency(dv);
    });

    test("updating an item not passing the filter", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 3, 'val': 1337})
      ]);
      dv.setFilter((dynamic o, _) => o['val'] != 1337);
      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      dv.updateItem(3, new MapDataItem({'id': 3, 'val': 1337}));
      expect(dv.getItems()[3], equals(new MapDataItem({'id': 3, 'val': 1337})),
          reason: "item updated");
      assertConsistency(dv);
    });

    test("updating an item to pass the filter", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 3, 'val': 1337})
      ]);
      dv.setFilter((dynamic o, _) => o['val'] != 1337);

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expect(e.changedRows, equals([3]), reason: "args");
        expectRowsChangedCalled();
      });

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expect(e.oldCount, equals(3), reason: "previous arg");
        expect(e.newCount, equals(4), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(4), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });
      dv.updateItem(3, new MapDataItem({'id': 3, 'val': 3}));
      expect(dv.getItems()[3], new MapDataItem({'id': 3, 'val': 3}),
          reason: "item updated");
      assertConsistency(dv);
    });

    test("updating an item to not pass the filter", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
        new MapDataItem({'id': 3, 'val': 3})
      ]);
      dv.setFilter((dynamic o, _) => o["val"] != 1337);

      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expect(e.oldCount, equals(4), reason: "previous arg");
        expect(e.newCount, equals(3), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(3), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });
      dv.updateItem(3, new MapDataItem({'id': 3, 'val': 1337}));
      expect(dv.getItems()[3], equals(new MapDataItem({'id': 3, 'val': 1337})),
          reason: "item updated");
      assertConsistency(dv);
    });
  });

  group("addItem", () {
    test("must have id", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      expect(
          () => dv.addItem(new MapDataItem({'val': 1337})),
          throwsA(equals(
              "Each data element must implement a unique 'id' property")),
          reason: "exception thrown");
    });

    test("must have id (custom)", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'uid': 0, 'val': 0}),
        new MapDataItem({'uid': 1, 'val': 1}),
        new MapDataItem({'uid': 2, 'val': 2}),
      ], "uid");
      expect(
          () => dv.addItem(new MapDataItem({'id': 3, 'val': 1337})),
          throwsA(equals(
              "Each data element must implement a unique 'id' property")),
          reason: "exception thrown");
    });

    test("basic", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);

      final Function expectRowsChangedCalled =
          expectAsync(() {}, reason: "onRowsChanged called");
      dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
        expect(e.changedRows, equals([3]), reason: "args");
        expectRowsChangedCalled();
      });

      final Function expectRowCountChangedCalled =
          expectAsync(() {}, reason: "onRowCountChanged called");
      dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
        expect(e.oldCount, equals(3), reason: "previous arg");
        expect(e.newCount, equals(4), reason: "current arg");
        expectRowCountChangedCalled();
      });

      final Function expectPagingInfoChangedCalled =
          expectAsync(() {}, reason: "onPagingInfoChanged called");
      dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
        expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
        expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
        expect(e.pagingInfo.totalRows, equals(4), reason: "totalRows arg");
        expectPagingInfoChangedCalled();
      });
      dv.addItem(new MapDataItem({'id': 3, 'val': 1337}));
      expect(dv.getItems()[3], equals(new MapDataItem({'id': 3, 'val': 1337})),
          reason: "item updated");
      expect(dv.getItem(3), equals(new MapDataItem({'id': 3, 'val': 1337})),
          reason: "item updated");
      assertConsistency(dv);
    });

    test("add an item not passing the filter", () {
      final DataView<DataItem> dv = new DataView<DataItem>();
      dv.setItems([
        new MapDataItem({'id': 0, 'val': 0}),
        new MapDataItem({'id': 1, 'val': 1}),
        new MapDataItem({'id': 2, 'val': 2}),
      ]);
      dv.setFilter((dynamic o, _) => o["val"] != 1337);
      dv.onBwuRowsChanged.first
          .then((core.RowsChanged e) => fail("onRowsChanged called"));
      dv.onBwuRowCountChanged.first
          .then((core.RowCountChanged e) => fail("onRowCountChanged called"));
      dv.onBwuPagingInfoChanged.first.then(
          (core.PagingInfoChanged e) => fail("onPagingInfoChanged called"));
      dv.addItem(new MapDataItem({'id': 3, 'val': 1337}));
      expect(dv.getItems()[3], new MapDataItem({'id': 3, 'val': 1337}),
          reason: "item updated");
      assertConsistency(dv);
    });

    group("insertItem", () {
      test("must have id", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 0, 'val': 0}),
          new MapDataItem({'id': 1, 'val': 1}),
          new MapDataItem({'id': 2, 'val': 2}),
        ]);

        expect(
            () => dv.insertItem(0, new MapDataItem({'val': 1337})),
            throwsA(equals(
                "Each data element must implement a unique 'id' property")),
            reason: "exception thrown");
      });

      test("must have id (custom)", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'uid': 0, 'val': 0}),
          new MapDataItem({'uid': 1, 'val': 1}),
          new MapDataItem({'uid': 2, 'val': 2}),
        ], "uid");

        expect(
            () => dv.insertItem(0, new MapDataItem({'val': 1337})),
            throwsA(equals(
                "Each data element must implement a unique 'id' property")),
            reason: "exception thrown");
      });

      test("insert at the beginning", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 0, 'val': 0}),
          new MapDataItem({'id': 1, 'val': 1}),
          new MapDataItem({'id': 2, 'val': 2}),
        ]);

        final Function expectRowsChangedCalled =
            expectAsync(() {}, reason: "onRowsChanged called");
        dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
          expect(e.changedRows, [0, 1, 2, 3], reason: "args");
          expectRowsChangedCalled();
        });

        final Function expectRowCountChangedCalled =
            expectAsync(() {}, reason: "onRowCountChanged called");
        dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
          expect(e.oldCount, equals(3), reason: "previous arg");
          expect(e.newCount, equals(4), reason: "current arg");
          expectRowCountChangedCalled();
        });

        final Function expectPagingInfoChangedCalled =
            expectAsync(() {}, reason: "onPagingInfoChanged called");
        dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
          expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
          expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
          expect(e.pagingInfo.totalRows, equals(4), reason: "totalRows arg");
          expectPagingInfoChangedCalled();
        });
        dv.insertItem(0, new MapDataItem({'id': 3, 'val': 1337}));
        expect(dv.getItem(0), new MapDataItem({'id': 3, 'val': 1337}),
            reason: "item updated");
        expect(dv.getItems().length, equals(4), reason: "items updated");
        expect(dv.length, equals(4), reason: "rows updated");
        assertConsistency(dv);
      });

      test("insert in the middle", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 0, 'val': 0}),
          new MapDataItem({'id': 1, 'val': 1}),
          new MapDataItem({'id': 2, 'val': 2}),
        ]);

        final Function expectRowsChangedCalled =
            expectAsync(() {}, reason: "onRowsChanged called");
        dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
          expect(e.changedRows, equals([2, 3]), reason: "args");
          expectRowsChangedCalled();
        });

        final Function expectRowCountChangedCalled =
            expectAsync(() {}, reason: "onRowCountChanged called");
        dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
          expect(e.oldCount, equals(3), reason: "previous arg");
          expect(e.newCount, equals(4), reason: "current arg");
          expectRowCountChangedCalled();
        });

        final Function expectPagingInfoChangedCalled =
            expectAsync(() {}, reason: "onPagingInfoChanged called");
        dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
          expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
          expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
          expect(e.pagingInfo.totalRows, equals(4), reason: "totalRows arg");
          expectPagingInfoChangedCalled();
        });
        dv.insertItem(2, new MapDataItem({'id': 3, 'val': 1337}));
        expect(dv.getItem(2), equals(new MapDataItem({'id': 3, 'val': 1337})),
            reason: "item updated");
        expect(dv.getItems().length, equals(4), reason: "items updated");
        expect(dv.length, equals(4), reason: "rows updated");
        assertConsistency(dv);
      });

      test("insert at the end", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 0, 'val': 0}),
          new MapDataItem({'id': 1, 'val': 1}),
          new MapDataItem({'id': 2, 'val': 2}),
        ]);

        final Function expectRowsChangedCalled =
            expectAsync(() {}, reason: "onRowsChanged called");
        dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
          expect(e.changedRows, equals([3]), reason: "args");
          expectRowsChangedCalled();
        });

        final Function expectRowCountChangedCalled =
            expectAsync(() {}, reason: "onRowCountChanged called");
        dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
          expect(e.oldCount, equals(3), reason: "previous arg");
          expect(e.newCount, equals(4), reason: "current arg");
          expectRowCountChangedCalled();
        });

        final Function expectPagingInfoChangedCalled =
            expectAsync(() {}, reason: "onPagingInfoChanged called");
        dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
          expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
          expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
          expect(e.pagingInfo.totalRows, equals(4), reason: "totalRows arg");
          expectPagingInfoChangedCalled();
        });
        dv.insertItem(3, new MapDataItem({'id': 3, 'val': 1337}));
        expect(dv.getItem(3), equals(new MapDataItem({'id': 3, 'val': 1337})),
            reason: "item updated");
        expect(dv.getItems().length, equals(4), reason: "items updated");
        expect(dv.length, equals(4), reason: "rows updated");
        assertConsistency(dv);
      });
    });

    group("deleteItem", () {
      test("must have id", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 0, 'val': 0}),
          new MapDataItem({'id': 1, 'val': 1}),
          new MapDataItem({'id': 2, 'val': 2}),
        ]);
        expect(() => dv.deleteItem(-1), throwsA(equals('Invalid id')),
            reason: "exception thrown");
        expect(() => dv.deleteItem(null), throwsA(equals('Invalid id')),
            reason: "exception thrown");
        expect(() => dv.deleteItem(3), throwsA(equals('Invalid id')),
            reason: "exception thrown");
      });

      test("must have id (custom)", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'uid': 0, 'id': -1, 'val': 0}),
          new MapDataItem({'uid': 1, 'id': 3, 'val': 1}),
          new MapDataItem({'uid': 2, 'id': null, 'val': 2})
        ], "uid");
        expect(() => dv.deleteItem(-1), throwsA(equals('Invalid id')),
            reason: "exception thrown");
        expect(() => dv.deleteItem(null), throwsA(equals('Invalid id')),
            reason: "exception thrown");
        expect(() => dv.deleteItem(3), throwsA(equals('Invalid id')),
            reason: "exception thrown");
      });

      test("delete at the beginning", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 05, 'val': 0}),
          new MapDataItem({'id': 15, 'val': 1}),
          new MapDataItem({'id': 25, 'val': 2})
        ]);

        final Function expectRowsChangedCalled =
            expectAsync(() {}, reason: "onRowsChanged called");
        dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
          expect(e.changedRows, equals([0, 1]), reason: "args");
          expectRowsChangedCalled();
        });

        final Function expectRowCountChangedCalled =
            expectAsync(() {}, reason: "onRowCountChanged called");
        dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
          expect(e.oldCount, equals(3), reason: "previous arg");
          expect(e.newCount, equals(2), reason: "current arg");
          expectRowCountChangedCalled();
        });

        final Function expectPagingInfoChangedCalled =
            expectAsync(() {}, reason: "onPagingInfoChanged called");
        dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
          expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
          expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
          expect(e.pagingInfo.totalRows, equals(2), reason: "totalRows arg");
          expectPagingInfoChangedCalled();
        });
        dv.deleteItem(05);
        expect(dv.getItems().length, equals(2), reason: "items updated");
        expect(dv.length, equals(2), reason: "rows updated");
        assertConsistency(dv);
      });

      test("delete in the middle", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 05, 'val': 0}),
          new MapDataItem({'id': 15, 'val': 1}),
          new MapDataItem({'id': 25, 'val': 2})
        ]);

        final Function expectRowsChangedCalled =
            expectAsync(() {}, reason: "onRowsChanged called");
        dv.onBwuRowsChanged.first.then((core.RowsChanged e) {
          expect(e.changedRows, equals([1]), reason: "args");
          expectRowsChangedCalled();
        });

        final Function expectRowCountChangedCalled =
            expectAsync(() {}, reason: "onRowCountChanged called");
        dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
          expect(e.oldCount, equals(3), reason: "previous arg");
          expect(e.newCount, equals(2), reason: "current arg");
          expectRowCountChangedCalled();
        });

        final Function expectPagingInfoChangedCalled =
            expectAsync(() {}, reason: "onPagingInfoChanged called");
        dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
          expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
          expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
          expect(e.pagingInfo.totalRows, equals(2), reason: "totalRows arg");
          expectPagingInfoChangedCalled();
        });
        dv.deleteItem(15);
        expect(dv.getItems().length, equals(2), reason: "items updated");
        expect(dv.length, equals(2), reason: "rows updated");
        assertConsistency(dv);
      });

      test("delete at the end", () {
        final DataView<DataItem> dv = new DataView<DataItem>();
        dv.setItems([
          new MapDataItem({'id': 05, 'val': 0}),
          new MapDataItem({'id': 15, 'val': 1}),
          new MapDataItem({'id': 25, 'val': 2})
        ]);

        dv.onBwuRowsChanged.first
            .then((core.RowsChanged e) => fail("onRowsChanged called"));

        final Function expectRowCountChangedCalled =
            expectAsync(() {}, reason: "onRowCountChanged called");
        dv.onBwuRowCountChanged.first.then((core.RowCountChanged e) {
          expect(e.oldCount, equals(3), reason: "previous arg");
          expect(e.newCount, equals(2), reason: "current arg");
          expectRowCountChangedCalled();
        });

        final Function expectPagingInfoChangedCalled =
            expectAsync(() {}, reason: "onPagingInfoChanged called");
        dv.onBwuPagingInfoChanged.first.then((core.PagingInfoChanged e) {
          expect(e.pagingInfo.pageSize, equals(0), reason: "pageSize arg");
          expect(e.pagingInfo.pageNum, equals(0), reason: "pageNum arg");
          expect(e.pagingInfo.totalRows, equals(2), reason: "totalRows arg");
          expectPagingInfoChangedCalled();
        });
        dv.deleteItem(25);
        expect(dv.getItems().length, equals(2), reason: "items updated");
        expect(dv.length, equals(2), reason: "rows updated");
        assertConsistency(dv);
      });
    });
  });
}

// TODO: paging
// TODO: combination
