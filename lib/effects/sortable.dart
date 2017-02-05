library bwu_datagrid.effects.sortable;

import 'dart:html' as dom;
import 'dart:math' show Point;
import 'dart:async' show StreamSubscription;

typedef void SortableStartFn(
    dom.Element element, dom.Element helper, dom.Element placeholder);
typedef void SortableBeforeStopFn(dom.Element element, dom.Element helper);
typedef void SortableStopFn(dom.MouseEvent e);

/// Supported values for the reorder direction
enum ReorderAxis { horizontal, vertical, both }

// TODO(zoechi) Dragable has some improvments compared to Sortable how it
// recognizes and initializes drag-n-drop state. Sortable should be updated to
// do the same. It might be worth making Sortable extend Dragable.
class Sortable {
  /// The parent element of the sortable items.
  final dom.Element sortable;

  /// Currently only `parent` (default) is supported.
  final String containment;

  /// The mouse-move threshold after a mouse-down, before a drag is recognized
  final int distance;

  /// Whether the elements are oriented horizontally or vertically.
  final ReorderAxis axis;

  /// The name of the cursor icon during dragging.
  final String cursor;

  /// unused (fore example 'intersection')
  final String tolerance;

  /// unused
  // The method to create the drag proxy (for example 'clone')
  final String helper;

  /// A space-separated list of CSS class names to be added to the element that
  /// is displayed instead of the original element while the original is dragged.
  final String placeholderCssClass;

  /// Contains the element ids in resulting order after a drag operation.
  final List<Object> reorderedIds = <Object>[];

  /// A callback called when a drag action was recognized (mouse-down and
  /// successive mouse-move more than [distance]
  SortableStartFn start;

  /// A callback called on mouse-up (after a drag action) before drag status
  /// is reset.
  SortableBeforeStopFn beforeStop;

  /// A callback called on mouse-up (after a drag action) after drag status
  /// was reset.
  SortableStopFn stop;

  /// Containers the found sortable items filled by [init]
  List<dom.Element> _items;

  /// `true` when a drag action is in progress
  bool _isDragActive = false;

  /// `true` after a mouse-down was received while the mouse did not yet move
  /// [distance] pixels away from the initial click position.
  bool _isDragStartPending = false;

  /// The mouse position on mouse-down
  Point<int> _dragStartPos;

  /// The min left and max right position an item can be dragged
  int _minLeft, _maxLeft;

  /// The min top and max bottom position an item can be dragged
  int _minTop, _maxTop;

  /// A clone of the dragged element used as drag proxy.
  dom.Element _draggedHelper;

  /// A clone of the dragged element shown at the original position of the
  /// dragged element while it is dragged.
  dom.Element _placeholder;

  /// The reference to the original element being currently dragged.
  dom.Element _draggedElement;

  /// The top-left position of the dragged element before the drag action
  /// started.
  Point<int> _draggedElementStartPos;

  /// The index of the dragged element when the drag action started.
  int _draggedElementIndex;

  /// The mouse-move subscription created after a mouse-down while waiting for
  /// a drag action to start to be recognized.
  StreamSubscription<dynamic> _mouseMoveSubscription;

  /// The mouse-down subscription waiting for a possible drag action to be
  /// initiated.
  List<StreamSubscription<dynamic>> _mouseDownSubscriptions =
      <StreamSubscription<dynamic>>[];

  Sortable(
      {this.sortable,
      this.containment: 'parent',
      this.distance: 3,
      this.axis: ReorderAxis.both,
      this.cursor,
      this.tolerance,
      this.helper,
      this.placeholderCssClass,
      this.start,
      this.beforeStop,
      this.stop}) {
    assert(axis != null);
    assert(distance >= 0);

    init();

    // every mouse-up stops a drag operation
    dom.document.onMouseUp.listen((dom.MouseEvent e) {
      if (_isDragActive) {
        if (e.button != 0) {
          cancel();
        } else {
          _dragEnd(e);
        }
      }
      _isDragStartPending = false;
    });
  }

  void _dragEnd(dom.MouseEvent e ) {
    if (beforeStop != null) {
      beforeStop(_draggedElement, _draggedHelper);
    }
    _mouseMoveSubscription.cancel();
    _mouseMoveSubscription = null;

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

    if (stop != null) {
      stop(e);
    }
  }

  void cancel() {
    if (_mouseMoveSubscription != null) {
      _mouseMoveSubscription.cancel();
      _mouseMoveSubscription = null;
    }
    _isDragActive = false;
    _isDragStartPending = false;
    _dragStartPos = null;
    if (_draggedHelper != null) {
      _draggedHelper.remove();
      _draggedHelper = null;
    }
    if (_placeholder != null) {
      _placeholder.remove();
      _placeholder = null;
    }
    if (_draggedElement != null && _draggedElementIndex != null) {
      sortable.children.insert(_draggedElementIndex, _draggedElement);
      _draggedElement = null;
    }
    _draggedElementIndex = null;
    _draggedElementStartPos = null;
  }

  /// Cancel active listeners and reinitialize.
  void init() {
    _items = sortable.children
        .where((dom.Element e) => e.attributes['ismovable'] == 'true')
        .toList();
    _mouseDownSubscriptions
        .forEach((StreamSubscription<dynamic> s) => s.cancel);
    _mouseDownSubscriptions.clear();

    _items.forEach((dom.Element e) {
      _mouseDownSubscriptions.add(e.onMouseDown.listen((dom.MouseEvent e) {
        if (e.button == 0) {
          _draggedElement = e.target as dom.Element;
          if (_draggedElement.attributes.containsKey('nonsortable')) {
            return;
          }

          _isDragStartPending = true;
          while (_draggedElement != null && !_items.contains(_draggedElement)) {
            _draggedElement = _draggedElement.parent;
          }
          if (_draggedElement == null) {
            return;
          }

          _dragStartPos =
              new Point<int>(e.client.x.toInt(), e.client.y.toInt());
          _draggedElementStartPos = new Point<int>(
              _draggedElement.offsetLeft.round(),
              _draggedElement.offsetTop.round());

          _subscribeMouseMove();
        }
      }));
    });
  }

  void _subscribeMouseMove() {
    _mouseMoveSubscription =
        dom.document.onMouseMove.listen((dom.MouseEvent e) {
      if (_dragStartPos != null && _isDragStartPending) {
        if (!_isDragActive) {
          if ((((e.client.x - _dragStartPos.x) as int).abs() > distance) ||
              (((e.client.y - _dragStartPos.y) as int).abs() > distance) &&
                  !_isDragActive) {
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
    sortable.children.forEach((dom.Element e) => reorderedIds.add(e.id));
  }

  void _dragStart() {
    _updateIds();
    _isDragActive = true;
    _draggedHelper = _draggedElement.clone(true) as dom.Element;
    _draggedElementIndex = sortable.children.indexOf(_draggedElement);
    _draggedHelper.style
      ..zIndex = '1000'
      ..position = 'absolute'
      ..left = '${_draggedElementStartPos.x}px'
      ..top = '${_draggedElementStartPos.y}px';
    _draggedHelper.id = 'draggable';
    sortable.append(_draggedHelper);

    _placeholder = _draggedElement.clone(false) as dom.Element;
    _placeholder.classes
      ..clear()
      ..addAll(
          placeholderCssClass.split(' ').where((String s) => s.length > 0));

    if (start != null) {
      start(_draggedElement, _draggedHelper, _placeholder);
    }
    int dIdx = sortable.children.indexOf(_draggedElement);

    if (axis == ReorderAxis.horizontal || axis == ReorderAxis.both) {
      _minLeft = _draggedElement.offsetLeft.round();
      _maxLeft =
          (_draggedElement.offsetLeft + _draggedElement.offsetWidth).round();
      for (int i = dIdx - 1; i >= 0; i--) {
        final dom.Element elm = sortable.children[i];
        if (elm.attributes['ismovable'] != 'true') {
          break;
        }
        _minLeft = elm.offsetLeft.round();
      }

      for (int i = dIdx + 1; i < sortable.children.length; i++) {
        final dom.Element elm = sortable.children[i];
        if (elm.attributes['ismovable'] != 'true') {
          break;
        }
        if (elm == _draggedHelper) {
          continue;
        }
        _maxLeft = (elm.offsetLeft + elm.offsetWidth).round();
      }
      _minLeft -= (_draggedHelper.offsetWidth / 2).round();
      _maxLeft += (_draggedHelper.offsetWidth / 2).round();
    }

    if (axis == ReorderAxis.vertical || axis == ReorderAxis.both) {
      _minTop = _draggedElement.offsetTop.round();
      _maxTop =
          (_draggedElement.offsetTop + _draggedElement.offsetHeight).round();
      for (int i = dIdx - 1; i >= 0; i--) {
        final dom.Element elm = sortable.children[i];
        if (elm.attributes['ismovable'] != 'true') {
          break;
        }
        _minTop = elm.offsetTop.round();
      }

      for (int i = dIdx + 1; i < sortable.children.length; i++) {
        final dom.Element elm = sortable.children[i];
        if (elm.attributes['ismovable'] != 'true') {
          break;
        }
        if (elm == _draggedHelper) {
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
    Point<int> _newPos = new Point<int>(
        _draggedElementStartPos.x.toInt() +
            e.client.x.toInt() -
            _dragStartPos.x.toInt(),
        _draggedElementStartPos.y.toInt() +
            e.client.y.toInt() -
            _dragStartPos.y.toInt());
    if (axis == ReorderAxis.both || axis == ReorderAxis.horizontal) {
      if (_newPos.x < _minLeft) {
        _newPos = new Point<int>(_minLeft, _newPos.y);
      }
      if (_newPos.x + _placeholder.offsetWidth > _maxLeft) {
        _newPos = new Point<int>(
            (_maxLeft - _placeholder.offsetWidth).round(), _newPos.y);
      }
      _draggedHelper.style.left = '${_newPos.x}px';
    }
    if (axis == null ||
        axis == ReorderAxis.both ||
        axis == ReorderAxis.vertical) {
      if (_newPos.y < _minTop) {
        _newPos = new Point<int>(_newPos.x, _minTop);
      }
      if (_newPos.y + _placeholder.offsetHeight > _maxTop) {
        _newPos = new Point<int>(
            _newPos.x, (_maxTop - _placeholder.offsetHeight).round());
      }
      _draggedHelper.style.top = '${_newPos.y}px';
    }

    int placeholderIdx = sortable.children.indexOf(_placeholder);

    // TODO check only relevant children

    sortable.children.toList().forEach((dom.Element elm) {
      final dom.Rectangle<int> bcr =
          elm.getBoundingClientRect() as dom.Rectangle<int>;
      int left = bcr.left.round();
      int right = (bcr.left + bcr.width).round();
      int midX = (left + bcr.width / 2).round();
      int top = bcr.top.round();
      int bottom = (bcr.top + bcr.height).round();
      int midY = (top + bcr.height / 2).round();

      int overIdx = sortable.children.indexOf(elm);

      if (axis != null &&
          (axis == ReorderAxis.both || axis == ReorderAxis.horizontal)) {
        if (elm != _placeholder &&
            elm != _draggedHelper &&
            elm.attributes['ismovable'] == 'true' &&
            e.client.x > left &&
            e.client.x < right) {
          if (e.client.x > midX && placeholderIdx < overIdx) {
            sortable.children.insert(overIdx + 1, _placeholder);
          } else if (e.client.x < midX && placeholderIdx > overIdx) {
            sortable.children.insert(overIdx, _placeholder);
          }
        }
      }

      if (axis != null &&
          (axis == ReorderAxis.both || axis == ReorderAxis.vertical)) {
        if (elm != _placeholder &&
            elm != _draggedHelper &&
            elm.attributes['ismovable'] == 'true' &&
            e.client.y > top &&
            e.client.y < bottom) {
          if (e.client.y > midY && placeholderIdx < overIdx) {
            sortable.children.insert(overIdx + 1, _placeholder);
          } else if (e.client.y < midY && placeholderIdx > overIdx) {
            sortable.children.insert(overIdx, _placeholder);
          }
        }
      }
    });
  }

  void destroy() {
    _mouseDownSubscriptions.forEach(
        (StreamSubscription<dynamic> subscription) => subscription.cancel());
    _mouseDownSubscriptions.clear();
    cancel();
  }
}
