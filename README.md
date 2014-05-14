# Basic non-visual elements for Polymer.dart

A port of polymer.js' [core-elements](http://polymer.github.io/core-docs/) to Polymer.dart. 
The intent of the authors is to contribute the work to the Dart project itself (https://www.dartlang.org).

### Dart ports of Polymer elements from [PolymerLabs](http://www.polymer-project.org/docs/elements/polymer-elements.html) can be found at 
* [polymer_ui_elements](https://github.com/ErikGrimes/polymer_elements)
* [polymer_ui_elements](https://github.com/ErikGrimes/polymer_ui_elements)


## Documentation
* The Dart source files of an element often contain some documentation (Dartdoc) how to use the element. You can also find this documentation online at  
* [DartDoc](http://bwu-dart.github.io/core_elements/docs/index.html)
* Almost each element has an associated demo page which shows how to use the element. 
Open the 'demo' links below to take a look.
The source code of these demo pages can be found in the [example subdirectory of the package](https://github.com/ErikGrimes/polymer_elements/tree/master/example). 
The actual implementation of the demo page is often outsourced to files in the `example/src/element_name` subdirectory.


## Usage
* add the following to your pubspec.yaml file: 

```yaml
dependencies:
  core_elements:
```
For more details take a look at the demo pages. 

## Feedback

Your feedback is very much appreciated. We are excited to hear about your experience using polymer_elements.
We need your feedback to continually improve the qualtiy.

Just [Create a New Issue](https://github.com/bwu-dart/core_elements/issues/new)


## General notes

* Tested with Dart SDK version 1.4.0-dev.6.5

### Status
<!-- (A few demo pages (* aren't rendered properly as GitHub Pages or because they use unfinished elements. We are working on it.) --> 

<!-- * Status `(ported)` means it is ported but not yet usable -->

Element name                    |   Status         | Comment      | Demo
------------------------------- | ---------------- | ------------ | ----
polymer-ajax                    | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_ajax.html)
<!--polymer-anchor-point            | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_anchor_point.html)&nbsp;
polymer-collapse                | ported           | needs some additional stylesheet imports due to Polymer.dart limitations (see examples) | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_collapse.html)
polymer-cookie                  | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_cookie.html)
polymer-file                    | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_file.html)
polymer-flex-layout             | ported           | needs some additional stylesheet imports due to Polymer.dart limitations (see examples) | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_flex_layout.html)&nbsp;
polymer-google-jsapi            | not&nbsp;started |              | 
polymer-grid-layout             | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_grid_layout.html)
polymer-jsonp                   | not&nbsp;started |              |
polymer-key-helper              | not&nbsp;planned |              |
polymer-layout                  | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_layout.html)
polymer-localstorage            | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_localstorage.html)&nbsp;
polymer-media-query             | ported           | small issue in Dart but works fine in JS  | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_media_query.html)
polymer-meta                    | ported           | doesn't work in JavaScript  |
polymer-mock-data               | not&nbsp;started |              |
polymer-overlay                 | not&nbsp;started |              |
polymer-page                    | ported           |              |
polymer-scrub                   | not&nbsp;started |              | (no demo)
polymer-selection               | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_selection.html)
polymer-selector                | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_selector.html)
polymer-shared-lib              | not&nbsp;started |              |
polymer-signals                 | ported           |              | [demo](http://erikgrimes.github.io/polymer_elements/build/polymer_signals.html)
polymer&#8209;view&#8209;source&#8209;link         | not&nbsp;started |              |
-->


### License
BSD 3-clause license (see [LICENSE](https://github.com/bwu-dart/core_elements/blob/master/LICENSE) file).

[![Build Status](https://drone.io/github.com/bwu-dart/core_elements/status.png)](https://drone.io/github.com/bwu-dart/core_elements/latest)
