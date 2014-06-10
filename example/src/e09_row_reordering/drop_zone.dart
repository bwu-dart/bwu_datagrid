library bwu_datagrid.example.e09_row_reordering.drop_zone;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';

class ZoneDrop {
  dom.MouseEvent causedBy;

  ZoneDrop({this.causedBy});
}

@CustomTag('drop-zone')
class DropZone extends PolymerElement {
  DropZone.created() : super.created();

  bool _isAcceptedDragStarted = false;
  List<String> _accept;

  @published String dropzone;

  void dropzoneChanged(old) {
    String s = 'move s:text/bwu-datagrid-recycle file:text/blajflaskjfd';
    var match = new RegExp(r'^(?:copy|link|move)(.*)').firstMatch(s);
    var matches = new RegExp(r'(?: +[a-z]*:)([^ ]*)').allMatches(match.group(1));

    List<String> results = [];
    matches.forEach((e) {
      results.add(e.group(1));
    });
    _accept = results;
  }

  @override
  void attached() {
    super.attached();

    try {

      dom.document.onDragStart.listen((e) {
        if(_doAccept(e)) {
          _isAcceptedDragStarted = true;
          this.classes.add('drag-valid');
        }
      });

      dom.document.onDragEnd.listen((e) {
        _dragEnded();
      });

      this.onDragEnter.listen((e) {
        if(_isAcceptedDragStarted) {
          this.classes.add('drag-over');
          e.preventDefault();
        }
      });

      this.onDragLeave.listen((e) {
        this.classes.remove('drag-over');
      });


      this.onDragOver.listen((e) {
        if(_isAcceptedDragStarted) {
          e.preventDefault();
        }
      });

      this.onDrop.listen((e) {
        _dragEnded();
      });

    } catch(e, s) {
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

    if(_accept != null) {
      _accept.forEach((k) {
        if(e.dataTransfer.types.contains(k)) {
          result = true;
        }
      });
    }
    return result;
  }
}
