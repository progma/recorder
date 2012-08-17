root = exports ? this
playbook = root.playbook.playbook

myCodeMirror = undefined
myPlaybackMirror = undefined
recordingTracks = undefined
recordingStartTime = undefined

# The things I track and how to compute them.
recordingSources =
  bufferContents: ->
    myCodeMirror.getValue()

  cursorPosition: ->
    myCodeMirror.getCursor()

  selectionRange: ->
    from: myCodeMirror.getCursor(true)
    to: myCodeMirror.getCursor(false)

  scrollPosition: ->
    myCodeMirror.getScrollInfo()


$ ->

  myCodeMirror = CodeMirror.fromTextArea($('#editorArea').get(0))
  myPlaybackMirror = CodeMirror.fromTextArea($('#playbackArea').get(0),
                                             readOnly: true)

  $('#startButton').click ->
    myCodeMirror.focus()
    recordingTracks = {}
    recordingStartTime = new Date()

    $.each recordingSources, (name, record) ->
      recordingTracks[name] = []
      recordingTracks[name].push
        time: 0
        value: record()

    recordingTracks['evaluatedCode'] = []

  recordCurrentState = ->
    $.each recordingSources, (name, record) ->
      ourTrack = recordingTracks[name]
      currentState = record()
      unless _.isEqual(currentState, _.last(ourTrack).value)
        ourTrack.push
          time: new Date() - recordingStartTime
          value: currentState

  # Timhle odchytime zatim vsechny aktivity CodeMirror bufferu,
  # ktere nas zajimaji.
  myCodeMirror.setOption 'onCursorActivity', recordCurrentState
  myCodeMirror.setOption 'onScroll', recordCurrentState

  # Eval nemerime pri eventech, ale sbirame pri kliknuti tlacitka 'Eval!'.
  $('#evalButton').click ->
    currentCode = myCodeMirror.getValue()
    recordingTracks['evaluatedCode'].push
      time: new Date() - recordingStartTime
      value: currentCode
    playbook['evaluatedCode'] currentCode

  $('#playButton').click ->
    myPlaybackMirror.focus()
    $.each recordingTracks, (name, track) ->
      $.map track, (event) ->
        setTimeout (->
          playbook[name] event.value, myPlaybackMirror),
          event.time

  $('#dumpButton').click ->
    $('#dumpArea').val JSON.stringify(recordingTracks, `undefined`, 2)

  $('#parseButton').click ->
    recordingTracks = JSON.parse($('#dumpArea').val())
