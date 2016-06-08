library bwu_datagrid.effects.dragable;

import 'dart:html' as dom;
import 'dart:math' show Point;
import 'dart:async' show Stream, StreamController, StreamSubscription;

class Dragable {
  StreamController<dom.MouseEvent> _dragStartController =
      new StreamController<dom.MouseEvent>();
  Stream<dom.MouseEvent> _dragStartStream;
  Stream<dom.MouseEvent> get onDragStart => _dragStartStream;

  StreamController<dom.MouseEvent> _dragController =
      new StreamController<dom.MouseEvent>();
  Stream<dom.MouseEvent> _dragStream;
  Stream<dom.MouseEvent> get onDrag => _dragStream;

  StreamController<dom.MouseEvent> _dragEndController =
      new StreamController<dom.MouseEvent>();
  Stream<dom.MouseEvent> _dragEndStream;
  Stream<dom.MouseEvent> get onDragEnd => _dragEndStream;

  dom.MouseEvent _startMouseEvent;

  // The element drag-n-drop action is monitored
  dom.Element dragable;

  /// The mouse-move threshold after a mouse-down, before a drag is recognized
  final int distance;

  /// The mouse-move subscription created after a mouse-down while waiting for
  /// a drag action to start to be recognized.
  StreamSubscription<dynamic> _mouseMoveSubscription;

  /// The mouse-down subscription waiting for a possible drag action to be
  /// initiated.
  StreamSubscription<dynamic> _mouseDownSubscription;

  /// `true` after a mouse-down was received while the mouse did not yet move
  /// [distance] pixels away from the initial click position.
  bool _isDragStartPending = false;

  /// The mouse position on mouse-down
  Point<int> _dragStartPos;

  /// `true` when a drag action is in progress
  bool _isDragActive = false;

  Dragable(this.dragable, {this.distance: 3}) {
    _dragStartStream = _dragStartController.stream.asBroadcastStream();
    _dragStream = _dragController.stream.asBroadcastStream();
    _dragEndStream = _dragEndController.stream.asBroadcastStream();

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

  void _dragEnd(dom.MouseEvent e) {
    _dragEndController.add(e);
    _mouseMoveSubscription.cancel();
    _mouseMoveSubscription = null;

    _isDragActive = false;
    _dragStartPos = null;

    e.preventDefault();
  }

  void cancel() {
    if (_mouseMoveSubscription != null) {
      _mouseMoveSubscription.cancel();
      _mouseMoveSubscription = null;
    }
    _isDragActive = false;
    _isDragStartPending = false;
    _dragStartPos = null;
  }

  void init() {
    _mouseDownSubscription = dragable.onMouseDown.listen((dom.MouseEvent e) {
      if (_isDragActive || _isDragStartPending) {
        return;
      }

      if (e.button == 0) {
        if (!dragable.attributes.containsKey('bwu-draggable')) {
          return;
        }

        _isDragStartPending = true;
        _startMouseEvent = e;
        _dragStartPos = new Point<int>(e.client.x, e.client.y);
        _subscribeMouseMove();
      }
    });
  }

  void _subscribeMouseMove() {
    _mouseMoveSubscription =
        dom.document.onMouseMove.listen((dom.MouseEvent e) {
      if (_dragStartPos != null && _isDragStartPending) {
        if ((((e.client.x - _dragStartPos.x) as int).abs() > distance) ||
            (((e.client.y - _dragStartPos.y) as int).abs() > distance) &&
                !_isDragActive) {
          _dragStart();
        } else {
          // print('drag-pending');
        }
      } else if (_isDragActive) {
        _drag(e);
      }
    });
  }

  void _dragStart() {
    _isDragStartPending = false;
    _isDragActive = true;
    _dragStartController.add(_startMouseEvent);
  }

  void _drag(dom.MouseEvent e) {
    _dragController.add(e);
  }

  void destroy() {
    _mouseDownSubscription.cancel;
    _mouseDownSubscription = null;
    cancel();
  }
}
