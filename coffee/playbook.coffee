# How to play back the values of individual properties.
playbook =
  bufferContents: (value, targets) ->
    targets.codeMirror.setValue value

  cursorPosition: (value, targets) ->
    targets.codeMirror.setCursor value

  selectionRange: (value, targets) ->
    targets.codeMirror.setSelection value.from, value.to

  scrollPosition: (value, targets) ->
    destination = targets.codeMirror.getScrollInfo()
    targets.codeMirror.scrollTo value.x / value.width * destination.width,
                                value.y / value.height * destination.height

  evaluatedCode: (value, targets) ->
    turtle.run value, targets.turtleDiv

(exports ? this).playbook =
  playbook: playbook
