library bwu_datagrid.effects.sortable;

import 'dart:html' as dom;
import 'dart:math' as math;
import 'dart:async' as async;
//import 'package:collection/equality.dart' as collEqu;

typedef void SortableStartFn(dom.HtmlElement element, dom.HtmlElement helper, dom.HtmlElement placeholder);
typedef void SortableBeforeStopFn(dom.HtmlElement element, dom.HtmlElement helper);
typedef void SortableStopFn(dom.MouseEvent e);

class Sortable {
  final dom.HtmlElement sortable;
  final String containment;
  final int distance;
  final String axis;
  final String cursor;
  final String tolerance;
  final String helper;
  final String placeholderCssClass;
  final List<String> reorderedIds = [];

  SortableStartFn start;
  SortableBeforeStopFn beforeStop;
  SortableStopFn stop;

  List<dom.Element> _items;
  //dom.MutationObserver _mObserver;

  bool _isDragActive = false;
  bool _isDragStartPending = false;
  math.Point<int> _dragStartPos;
  int _minLeft, _maxLeft;
  int _minTop, _maxTop;
  dom.HtmlElement _draggedHelper;
  dom.HtmlElement _placeholder;
  dom.HtmlElement _draggedElement;
  math.Point<int> _draggedElementStartPos;
  int _draggedElementIndex;

  async.StreamSubscription _mouseMoveSubscr;
  List<async.StreamSubscription> _mouseDownSubscr = [];

  Sortable({this.sortable, this.containment : 'parent', this.distance, this.axis, this.cursor, this.tolerance, this.helper, this.placeholderCssClass, this.start, this.beforeStop, this.stop}) {
    init();
//    _mObserver = new dom.MutationObserver((mutations, _) {
//      if(!_isDragActive && !const collEqu.IterableEquality().equals(sortable.children.where((e) => e.attributes['isMovable'] == 'true'), _items)) {
//        destroy();
//        init();
//      }
//    })..observe(sortable, attributes: true, childList: true, subtree: false);

    // every mouse-up stops a drag operation
    dom.document.onMouseUp.listen((e) {
      if(_isDragActive) {
        if(e.which != 1) {
          cancel();
        } else {
          _dragEnd(e);
        }
      }
      _isDragStartPending = false;
    });
  }

  void _dragEnd(dom.MouseEvent e) {
    if(beforeStop != null) {
      beforeStop(_draggedElement, _draggedHelper);
    }
    _mouseMoveSubscr.cancel();
    _mouseMoveSubscr = null;

    _isDragActive = false;
    _dragStartPos = null;

    _draggedHelper.remove();
    _draggedHelper = null;

    _placeholder.replaceWith(_draggedElement);
    _placeholder = null;

    e.preventDefault();
    _updateIds();

    _draggedElement = null;
    _draggedElementIndex = null;
    _draggedElementStartPos = null;

    if(stop != null) {
      stop(e);
    }
  }

  void cancel() {
    if(_mouseMoveSubscr != null) {
      _mouseMoveSubscr.cancel();
      _mouseMoveSubscr = null;
    }
    _isDragActive = false;
    _isDragStartPending = false;
    _dragStartPos = null;
    if(_draggedHelper != null) {
      _draggedHelper.remove();
      _draggedHelper = null;
    }
    if(_placeholder != null) {
      _placeholder.remove();
      _placeholder = null;
    }
    if(_draggedElement != null && _draggedElementIndex != null) {
      sortable.children.insert(_draggedElementIndex, _draggedElement);
      _draggedElement = null;
    }
    _draggedElementIndex = null;
    _draggedElementStartPos = null;
  }

  void init() {
    _items = sortable.children.where((e) => e.attributes['ismovable'] == 'true').toList();
    _mouseDownSubscr.clear();
    _items.forEach((e) {
      _mouseDownSubscr.add(e.onMouseDown.listen((e) {
        if(e.which == 1) {
          _draggedElement = e.target as dom.HtmlElement;
          if(_draggedElement.attributes.containsKey('draggable')) {
            return;
          }

          _isDragStartPending = true;
          while(_draggedElement != null && !_items.contains(_draggedElement)) {
            _draggedElement = _draggedElement.parent;
          }
          if(_draggedElement == null) {
            return;
          }

          _dragStartPos = new math.Point<int>(e.client.x, e.client.y);
          _draggedElementStartPos = new math.Point<int>(_draggedElement.offsetLeft.round(), _draggedElement.offsetTop.round());

          _subscribeMouseMove();
        }
      }));
    });
  }

  void _subscribeMouseMove() {
    _mouseMoveSubscr = dom.document.onMouseMove.listen((e) {
      if(_dragStartPos != null && _isDragStartPending) { // seems we still receive events after _mouseMoveSubscr.cancel()
        if(!_isDragActive) {
          if((((e.client.x - _dragStartPos.x) as int).abs() > distance) ||
              (((e.client.y - _dragStartPos.y) as int).abs() > distance) && !_isDragActive) {
            _dragStart();
          }
        } else {
          _drag(e);
        }
      }
    });
  }

  void _updateIds() {
    reorderedIds.clear();
    sortable.children.forEach((e) => reorderedIds.add(e.id));
  }

  void _dragStart() {
    _updateIds();
    _isDragActive = true;
    _draggedHelper = _draggedElement.clone(true);
    _draggedElementIndex = sortable.children.indexOf(_draggedElement);
    _draggedHelper.style
      ..zIndex = '1000'
      ..position = 'absolute'
      ..left = '${_draggedElementStartPos.x}px'
      ..top = '${_draggedElementStartPos.y}px';
    _draggedHelper.id = 'draggable';
    sortable.append(_draggedHelper);

    _placeholder = _draggedElement.clone(false);
    _placeholder.classes
      ..clear()
      ..add(placeholderCssClass);

    if(start != null) {
      start(_draggedElement, _draggedHelper, _placeholder);
    }
    int dIdx = sortable.children.indexOf(_draggedElement);

    if(axis.contains('x')) {
      _minLeft = _draggedElement.offsetLeft.round();
      _maxLeft = (_draggedElement.offsetLeft + _draggedElement.offsetWidth).round();
      for(int i = dIdx - 1; i >= 0; i--) {
        var elm = sortable.children[i];
        if(elm.attributes['ismovable'] != 'true') {
          break;
        }
        _minLeft = elm.offsetLeft.round();

      }

      for(int i = dIdx + 1; i < sortable.children.length; i++) {
        var elm = sortable.children[i];
        if(elm.attributes['ismovable'] != 'true') {
          break;
        }
        if(elm == _draggedHelper) {
          continue;
        }
        _maxLeft = (elm.offsetLeft + elm.offsetWidth).round();
      }
      _minLeft -= (_draggedHelper.offsetWidth / 2).round();
      _maxLeft += (_draggedHelper.offsetWidth / 2).round();
    }

    if(axis.contains('y')) {
      _minTop = _draggedElement.offsetTop.round();
      _maxTop = (_draggedElement.offsetTop + _draggedElement.offsetHeight).round();
      for(int i = dIdx - 1; i >= 0; i--) {
        var elm = sortable.children[i];
        if(elm.attributes['ismovable'] != 'true') {
          break;
        }
        _minTop = elm.offsetTop.round();
      }

      for(int i = dIdx + 1; i < sortable.children.length; i++) {
        var elm = sortable.children[i];
        if(elm.attributes['ismovable'] != 'true') {
          break;
        }
        if(elm == _draggedHelper) {
          continue;
        }
        _maxTop = (elm.offsetTop + elm.offsetHeight).round();
      }
      _minTop -= (_draggedHelper.offsetHeight / 2).round();
      _maxTop += (_draggedHelper.offsetHeight / 2).round();
    }

    _draggedElement.replaceWith(_placeholder);
  }

  void _drag(dom.MouseEvent e) {
    math.Point<int> _newPos = new math.Point<int>(
        _draggedElementStartPos.x + e.client.x - _dragStartPos.x,
        _draggedElementStartPos.y + e.client.y - _dragStartPos.y);
    if(axis == null || axis.isEmpty || axis == 'x') {
      if(_newPos.x < _minLeft) {
        _newPos = new math.Point(_minLeft, _newPos.y);
      }
      if(_newPos.x + _placeholder.offsetWidth > _maxLeft) {
        _newPos = new math.Point((_maxLeft - _placeholder.offsetWidth).round(), _newPos.y);
      }
      _draggedHelper.style.left = '${_newPos.x}px';
    }
    if(axis == null || axis.isEmpty || axis == 'y') {
      if(_newPos.y < _minTop) {
        _newPos = new math.Point(_newPos.x, _minTop);
      }
      if(_newPos.y + _placeholder.offsetHeight > _maxTop) {
        _newPos = new math.Point(_newPos.x, (_maxTop - _placeholder.offsetHeight).round());
      }
      _draggedHelper.style.top = '${_newPos.y}px';
    }

    int placeholderPos;
    dom.HtmlElement hoverElement;
    int placeholderIdx = sortable.children.indexOf(_placeholder);

    // TODO check only relevant children

    sortable.children.toList().forEach((elm) {
      var bcr = elm.getBoundingClientRect();
      int left = bcr.left.round();
      int right = (bcr.left + bcr.width).round();
      int midX = (left + bcr.width / 2).round();
      int top = bcr.top.round();
      int bottom = (bcr.top + bcr.height).round();
      int midY = (top + bcr.height / 2).round();

      int overIdx = sortable.children.indexOf(elm);

      if(axis != null && axis.contains('x')) {
        if(elm != _placeholder && elm != _draggedHelper &&
            elm.attributes['ismovable'] == 'true'
            && e.client.x > left && e.client.x < right) {
          if(e.client.x > midX && placeholderIdx < overIdx) {
            sortable.children.insert(overIdx + 1, _placeholder);
          } else if(e.client.x < midX && placeholderIdx > overIdx) {
            sortable.children.insert(overIdx, _placeholder);
          }
        }
      }

      if(axis != null && axis.contains('y')) {
        if(elm != _placeholder && elm != _draggedHelper &&
            elm.attributes['ismovable'] == 'true'
            && e.client.y > top && e.client.y < bottom) {
          if(e.client.y > midY && placeholderIdx < overIdx) {
            sortable.children.insert(overIdx + 1, _placeholder);
          } else if(e.client.y < midY && placeholderIdx > overIdx) {
            sortable.children.insert(overIdx, _placeholder);
          }
        }
      }

    });
  }

  void destroy() {
    _mouseDownSubscr.forEach((e) => e.cancel());
//    _mObserver.disconnect();
//    _mObserver = null;
    cancel();
  }
}
