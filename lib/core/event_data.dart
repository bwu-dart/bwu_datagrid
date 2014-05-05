part of bwu_dart.bwu_datagrid.core;

/***
 * An event object for passing data to event handlers and letting them control propagation.
 * <p>This is pretty much identical to how W3C and jQuery implement events.</p>
 * @class EventData
 * @constructor
 */
class EventData {
  var sender;
  Map details;

  bool _isPropagationStopped = false;
  bool _isImmediatePropagationStopped = false;

  /***
   * Returns whether stopPropagation was called on this event object.
   * @method isPropagationStopped
   * @return {Boolean}
   */
  bool get isPropagationStopped => _isPropagationStopped;

  /***
   * Stops event from propagating up the DOM tree.
   * @method stopPropagation
   */
  void stopPropagation() {
    _isPropagationStopped = true;
  }

  /***
   * Returns whether stopImmediatePropagation was called on this event object.\
   * @method isImmediatePropagationStopped
   * @return {Boolean}
   */
  bool get isImmediatePropagationStopped => _isImmediatePropagationStopped;

  /***
   * Prevents the rest of the handlers from being executed.
   * @method stopImmediatePropagation
   */
  void stopImmediatePropagation() {
    _isImmediatePropagationStopped = true;
  }

  EventData({this.sender, this.details});
}
