// How to play back the values of individual properties.
var playbook = { bufferContents:
                 function (value, targetMirror) {
                     targetMirror.setValue(value);},
                 cursorPosition:
                 function (value, targetMirror) {
                     targetMirror.setCursor(value);},
                 selectionRange:
                 function (value, targetMirror) {
                     targetMirror.setSelection(value.from, value.to);},
                 scrollPosition:
                 function (value, targetMirror) {
                     var destination = targetMirror.getScrollInfo();
                     targetMirror.scrollTo(value.x / value.width * destination.width,
                                           value.y / value.height * destination.height);}};
