root = exports ? this
playbook = root.playbook.playbook

myCodeMirror = undefined
myPlaybackMirror = undefined
recordingTracks = undefined
recordingStartTime = undefined
recordingNow = off

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

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get 0
  myPlaybackMirror = CodeMirror.fromTextArea $('#playbackArea').get 0,
                                             readOnly: true

  $('#startButton').click ->
    if recordingNow
      unless confirm '''You will lose your current recording by starting anew.
                        Are you sure?'''
        return
    myCodeMirror.focus()
    recordingTracks = {}
    recordingStartTime = new Date()
    recordingNow = on
    $('#recordingStatus').text 'recording!'

    $.each recordingSources, (name, record) ->
      recordingTracks[name] = []
      recordingTracks[name].push
        time: 0
        value: record()

    recordingTracks['evaluatedCode'] = []

  recordCurrentState = ->
    if recordingNow
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
    if recordingNow
      recordingTracks['evaluatedCode'].push
        time: new Date() - recordingStartTime
        value: currentCode
    playbook['evaluatedCode'] currentCode, turtleDiv: $('#turtleSpace').get 0

  playNamedValue = (name, value) ->
    playbook[name](value, { codeMirror: myPlaybackMirror
                          , turtleDiv: $('#turtleSpace').get 0 })

  $('#playButton').click ->
    myPlaybackMirror.focus()
    $.each recordingTracks, (name, track) ->
      $.map track, (event) ->
        setTimeout playNamedValue, event.time, name, event.value

  $('#dumpButton').click ->
    $('#dumpArea').val JSON.stringify recordingTracks, `undefined`, 2

  $('#parseButton').click ->
    if confirm '''Parsing in a new script will delete the old one.
                  Are you sure?'''
      recordingTracks = JSON.parse $('#dumpArea').val()