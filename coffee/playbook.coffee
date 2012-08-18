# How to play back the values of individual properties.
playbook =
  bufferContents: (value, targetMirror) ->
    targetMirror.setValue value

  cursorPosition: (value, targetMirror) ->
    targetMirror.setCursor value

  selectionRange: (value, targetMirror) ->
    targetMirror.setSelection value.from, value.to

  scrollPosition: (value, targetMirror) ->
    destination = targetMirror.getScrollInfo()
    targetMirror.scrollTo value.x / value.width * destination.width,
                          value.y / value.height * destination.height

  evaluatedCode: (value, turtleDiv) ->
    turtle.run value, turtleDiv

(exports ? this).playbook =
  playbook: playbook
