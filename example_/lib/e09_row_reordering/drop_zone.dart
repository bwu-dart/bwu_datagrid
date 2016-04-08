@HtmlImport('drop_zone.html')
library bwu_datagrid_examples.e09_row_reordering.drop_zone;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

class ZoneDrop {
  dom.MouseEvent causedBy;

  ZoneDrop({this.causedBy});
}

@PolymerRegister('drop-zone')
class DropZone extends PolymerElement {
  DropZone.created() : super.created();

  bool _isAcceptedDragStarted = false;
  List<String> _accept;

  @override
  @Property(observer: 'dropzoneChanged')
  String dropzone;

  @reflectable
  void dropzoneChanged([_, __]) {
    String s = 'move s:text/bwu-datagrid-recycle file:text/blajflaskjfd';
    final Match match = new RegExp(r'^(?:copy|link|move)(.*)').firstMatch(s);
    final Iterable<Match> matches =
        new RegExp(r'(?: +[a-z]*:)([^ ]*)').allMatches(match.group(1));

    List<String> results = [];
    matches.forEach((Match e) {
      results.add(e.group(1));
    });
    _accept = results;
  }

  @override
  void attached() {
    super.attached();

    try {
      dom.document.onDragStart.listen((dom.MouseEvent e) {
        if (_doAccept(e)) {
          _isAcceptedDragStarted = true;
          this.classes.add('drag-valid');
        }
      });

      dom.document.onDragEnd.listen((dom.MouseEvent e) {
        _dragEnded();
      });

      this.onDragEnter.listen((dom.MouseEvent e) {
        if (_isAcceptedDragStarted) {
          this.classes.add('drag-over');
          e.preventDefault();
        }
      });

      this.onDragLeave.listen((dom.MouseEvent e) {
        this.classes.remove('drag-over');
      });

      this.onDragOver.listen((dom.MouseEvent e) {
        if (_isAcceptedDragStarted) {
          e.preventDefault();
        }
      });

      this.onDrop.listen((dom.MouseEvent e) {
        _dragEnded();
      });
    } catch (e, s) {
      print(e);
      print(s);
    }
  }

  void _dragEnded() {
    this.classes.remove('drag-valid');
    this.classes.remove('drag-over');
    _isAcceptedDragStarted = false;
  }

  bool _doAccept(dom.MouseEvent e) {
    bool result = false;

    if (_accept != null) {
      _accept.forEach((String k) {
        if (e.dataTransfer.types.contains(k)) {
          result = true;
        }
      });
    }
    return result;
  }
}
