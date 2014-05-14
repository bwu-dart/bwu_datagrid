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

int outerWidth(dom.HtmlElement e) {
  var cs = e.getComputedStyle();
   return parseInt(cs.width) + parseInt(cs.paddingLeft) + parseInt(cs.paddingRight) + parseInt(cs.borderLeftWidth) + parseInt(cs.borderRightWidth);
}

int outerHeight(dom.HtmlElement e) {
  var cs = e.getComputedStyle();
   return parseInt(cs.height) + parseInt(cs.paddingTop) + parseInt(cs.paddingBottom) + parseInt(cs.borderTopWidth) + parseInt(cs.borderBottomWidth);
}

dom.HtmlElement closest(dom.HtmlElement e, String selector, {dom.HtmlElement context, bool goThroughShadowBoundaries: false}) {
  dom.HtmlElement curr = e;

  if(context != null) {
    //print('tools.closest: context not yet supported: ${context}');
  }

  dom.HtmlElement parent = curr.parentNode;
  if(parent is dom.ShadowRoot) {
    if(goThroughShadowBoundaries) {
      parent = (parent as dom.ShadowRoot).host;
    }
  }

  var foundPrevious = e;
  var found;
  while(parent != null && found == null) {
    found = parent.querySelector(selector);
    if(found != null) {
      if(parent.querySelectorAll(selector).contains(foundPrevious)) {
        return foundPrevious;
      } else {
        return found;
      }
    }
    foundPrevious = found;


//    curr = parent;
    if(parent is dom.ShadowRoot) {
      if(goThroughShadowBoundaries) {
        parent = (parent as dom.ShadowRoot).host;
      }
    } else {
      parent = parent.parent;
    }
  }

  return found;
//  if(found != null) {
//    return found;
//  }

//  // TODO check if this is still useful
//  if(parent == null) {
//    return null;
//  } else {
//    return curr;
//  }
}