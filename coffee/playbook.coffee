# How to play back the values of individual properties.
playbook =
  bufferContents: (value, environment) ->
    environment.codeMirror.setValue value

  cursorPosition: (value, environment) ->
    environment.codeMirror.setCursor value

  selectionRange: (value, environment) ->
    environment.codeMirror.setSelection value.from, value.to

  scrollPosition: (value, environment) ->
    destination = environment.codeMirror.getScrollInfo()
    environment.codeMirror.scrollTo value.x / value.width * destination.width,
                                    value.y / value.height * destination.height

  evaluatedCode: (value, environment) ->
    if not environment.evaluationContext?
      environment.evaluationContext = "turtle2d"

    switch environment.evaluationContext
      when "turtle2d" then turtle.run value, environment.turtleDiv
      when "turtle3d" then turtle3d.run value


(exports ? this).playbook =
  playbook: playbook
