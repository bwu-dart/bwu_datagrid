@HtmlImport('bwu_pager.html')
library bwu_datagrid.components.bwu_pager;

import 'dart:html' as dom;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:bwu_utils/bwu_utils_browser.dart' as utils;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/components/jq_ui_style/jq_ui_style.dart';

class NavState extends JsProxy {
  @reflectable bool canGotoFirst;
  @reflectable bool canGotoLast;
  @reflectable bool canGotoPrev;
  @reflectable bool canGotoNext;
  PagingInfo pagingInfo;

  NavState(
      {this.canGotoFirst: false,
      this.canGotoLast: false,
      this.canGotoPrev: false,
      this.canGotoNext: false});
}

/// Silence analyzer [jqUiStyleSilence]
@PolymerRegister('bwu-pager')
class BwuPager extends PolymerElement {
  BwuPager.created() : super.created();

  DataView _dataView;
  BwuDatagrid _grid;

  @property bool pagerSettingsHidden = true;
  @property String pagerStatusText = '';
  @property final NavState navState = new NavState();

  dom.Element status;

  void init(DataView dataView, BwuDatagrid grid) {
    _dataView = dataView;
    _grid = grid;
    _dataView.onBwuPagingInfoChanged.listen((core.PagingInfoChanged e) {
      updatePager(e.pagingInfo);
    });

    updatePager(_dataView.getPagingInfo());
  }

  void updateNavState() {
    bool cannotLeaveEditMode = !core.globalEditorLock.commitCurrentEdit();
    navState.pagingInfo = _dataView.getPagingInfo();
    int lastPage = navState.pagingInfo.totalPages - 1;

    set(
        'navState.canGotoFirst',
        !cannotLeaveEditMode &&
            navState.pagingInfo.pageSize != 0 &&
            navState.pagingInfo.pageNum > 0);
    set(
        'navState.canGotoLast',
        !cannotLeaveEditMode &&
            navState.pagingInfo.pageSize != 0 &&
            navState.pagingInfo.pageNum != lastPage);
    set(
        'navState.canGotoPrev',
        !cannotLeaveEditMode &&
            navState.pagingInfo.pageSize != 0 &&
            navState.pagingInfo.pageNum > 0);
    set(
        'navState.canGotoNext',
        !cannotLeaveEditMode &&
            navState.pagingInfo.pageSize != 0 &&
            navState.pagingInfo.pageNum < lastPage);
  }

  void setPageSize(int n) {
    _dataView.setRefreshHints(<String, bool>{'isFilterUnchanged': true});
    _dataView.setPagingOptions(new PagingInfo(pageSize: n));
  }

  @reflectable
  void gotoFirst([_, __]) {
    updateNavState();
    if (navState.canGotoFirst) {
      _dataView.setPagingOptions(new PagingInfo(pageNum: 0));
    }
  }

  @reflectable
  void gotoLast([_, __]) {
    updateNavState();
    if (navState.canGotoLast) {
      _dataView.setPagingOptions(
          new PagingInfo(pageNum: navState.pagingInfo.totalPages - 1));
    }
  }

  @reflectable
  void gotoPrev([_, __]) {
    updateNavState();
    if (navState.canGotoPrev) {
      _dataView.setPagingOptions(
          new PagingInfo(pageNum: navState.pagingInfo.pageNum - 1));
    }
  }

  @reflectable
  void gotoNext([_, __]) {
    updateNavState();
    if (navState.canGotoNext) {
      _dataView.setPagingOptions(
          new PagingInfo(pageNum: navState.pagingInfo.pageNum + 1));
    }
  }

  @reflectable
  void pageSizeClickHandler(dom.MouseEvent e, [_]) {
    int pagesize = utils.parseInt((e.target as dom.Element).dataset['value'],
        onErrorDefault: 0);
    //if (pagesize != 0) {
    if (pagesize == -1) {
      Range vp = _grid.getViewport();
      setPageSize(vp.bottom - vp.top);
    } else {
      setPageSize(pagesize);
    }
    //}
  }

  // TODO(zoechi) the hover classes should be set on the outer span, not the inner
  // maybe PolymerDom().. fixes this?
  @reflectable
  void toggleMouseOver(dom.MouseEvent e, [_]) {
    (e.target as dom.Element).classes.add('ui-state-hover');
  }

  @reflectable
  void toggleMouseOut(dom.MouseEvent e, [_]) {
    (e.target as dom.Element).classes.remove('ui-state-hover');
  }

  @reflectable
  void togglePagerSettingsHidden([_, __]) {
    set('pagerSettingsHidden', !pagerSettingsHidden);
  }

  void updatePager(PagingInfo pagingInfo) {
    updateNavState();

    if (pagingInfo.pageSize == 0) {
      final int totalRowsCount = _dataView.getItems().length;
      final int visibleRowsCount = pagingInfo.totalRows;
      if (visibleRowsCount < totalRowsCount) {
        set('pagerStatusText',
            'Showing ${visibleRowsCount} of ${totalRowsCount} rows');
      } else {
        set('pagerStatusText', 'Showing all ${totalRowsCount} rows');
      }
      set('pagerStatusText', 'Showing all ${pagingInfo.totalRows} rows');
    } else {
      set('pagerStatusText',
          'Showing page ${pagingInfo.pageNum + 1} of ${pagingInfo.totalPages}');
    }
  }

  @reflectable
  String firstClasses(bool enabled) =>
      'ui-icon ui-icon-seek-first ${enabled ? '':  "ui-state-disabled"  }';
  @reflectable
  String prevClasses(bool enabled) =>
      'ui-icon ui-icon-seek-prev ${enabled ? '': "ui-state-disabled" }';
  @reflectable
  String nextClasses(bool enabled) =>
      'ui-icon ui-icon-seek-next ${enabled ? '': "ui-state-disabled" }';
  @reflectable
  String lastClasses(bool enabled) =>
      'ui-icon ui-icon-seek-end ${enabled ? '': "ui-state-disabled" }';

  @reflectable
  String pagerSettingsHiddenClasses(bool pagerSettingsHidden) =>
      pagerSettingsHidden ? 'bwu-pager-settings-hidden' : '';
}
