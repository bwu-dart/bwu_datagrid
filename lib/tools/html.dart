library bwu_datagrid.tools.html;

import 'dart:html' as dom;

int parseInt(String s) {
  if(s == null || s.trim() == '') {
    return 0;
  }
  if(s.endsWith('%')) {
    return int.parse(s.substring(0, s.length-1));
  } else if (s.endsWith('px')) {
//      print(s);
//      print(s.substring(0,s.length-2));
    return int.parse(s.substring(0, s.length-2));
  }
  try {
    return int.parse(s);
  } on FormatException catch (e) {
    print('message: ${e.message}; value: "${s}"');
    rethrow;
  }
}

int innerWidth(dom.HtmlElement e) {
  var cs = e.getComputedStyle();
   return parseInt(cs.width) + parseInt(cs.paddingLeft) + parseInt(cs.paddingRight);
}

dom.HtmlElement closest(dom.HtmlElement e, String selector, {dom.HtmlElement context, bool goThroughShadowBoundaries: false}) {
  dom.HtmlElement curr = e;

  if(context != null) {
    print('tools.closest: context not yet supported: ${context}');
  }

  dom.HtmlElement parent = curr.parentNode;
  if(parent is dom.ShadowRoot) {
    if(goThroughShadowBoundaries) {
      parent = (parent as dom.ShadowRoot).host;
    }
  }

  var found = e;
  while(parent != null && found != null) {
    var found = parent.querySelector(selector);

    curr = parent;
    if(parent is dom.ShadowRoot) {
      if(goThroughShadowBoundaries) {
        parent = (parent as dom.ShadowRoot).host;
      }
    } else {
      parent = parent.parent;
    }
  }

  if(found != null) {
    return found;
  }

  if(parent == null) {
    return null;
  } else {
    return curr;
  }
}