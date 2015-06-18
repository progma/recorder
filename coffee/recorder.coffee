root = exports ? this
playbook = root.playbook.playbook

# Set this to the meaning that Eval! should have. Currently supported
# values include 'turtle2d' and 'turtle3d'.
EVALUATION_CONTEXT = "turtle2d"

myCodeMirror = undefined
myPlaybackMirror = undefined
recordingTracks = undefined
recordingStartTime = undefined
recordingNow = off
checkboxCount = 0

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
  if EVALUATION_CONTEXT == "turtle3d"
    $('#turtleSpace').append $('<canvas>', id: 'turtleCanvas')

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get 0
  myPlaybackMirror = CodeMirror.fromTextArea $('#playbackArea').get(0),
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
    recordingTracks['buttonPressed'] = []

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

  # Eval nemerime pri eventech, ale sbirame pri kliknuti tlacitka 'Eval!'
  # anebo klavesove zkratky Alt-C.
  evalCode = ->
    currentCode = myCodeMirror.getValue()
    if recordingNow
      recordingTracks['evaluatedCode'].push
        time: new Date() - recordingStartTime
        value: currentCode
    playbook['evaluatedCode'] currentCode,
                              turtleDiv: $('#turtleSpace').get(0)
                              turtle3dCanvas: $('#turtleCanvas').get(0)
                              evaluationContext: EVALUATION_CONTEXT

  $('#evalButton').click evalCode
  $(document).add(myCodeMirror.getInputField()).bind 'keydown.alt_c', evalCode

  $('#nextButton').add('#prevButton').click ->
    if recordingNow
      recordingTracks['buttonPressed'].push
        time: new Date() - recordingStartTime
        value: this.id

  $('#playButton').click ->
    myPlaybackMirror.focus()
    $.each recordingTracks, (name, track) ->
      $.map track, (event) ->
        playTheValue = ->
          playbook[name] event.value,
                         codeMirror: myPlaybackMirror
                         turtleDiv: $('#turtleSpace').get(0)
                         turtle3dCanvas: $('#turtleCanvas').get(0)
                         evaluationContext: EVALUATION_CONTEXT
        setTimeout playTheValue, event.time

  $('#dumpButton').click ->
    $('#dumpArea').val JSON.stringify recordingTracks, `undefined`, 2
		
  $('#parseButton').click ->
    if confirm '''Parsing in a new script will delete the old one.
                  Are you sure?'''
      recordingTracks = JSON.parse $('#dumpArea').val()
  
# new stuff from here 
  
# This method produces a list of all events sorted by time 
  $('#listButton').click ->
    eventHolder = []
    for own key of recordingTracks 
      for i in recordingTracks[key]
        j = {
          name: key
          time: i.time
          value: i.value
        }
        eventHolder.push j
    eventHolder.sort (a,b) -> return if a.time > b.time then 1 else -1
    for j in eventHolder
        str = JSON.stringify j, `undefined`, 2
        checkboxCount++
        $('#listOfEvents').append ('<li id="item' + checkboxCount + '"><input type="checkbox" id="checkbox' + 
        checkboxCount + '">' + str + '</li>')

# This method checks events in the range given by the spinners
# if the left resp. right boundary is not given, prefix resp. suffix of the list is selected
  $('#checkButton').click ->
    from = $('#spinnerFrom').spinner "value"
    to = $('#spinnerTo').spinner "value"
    from = if from == null then 1 else from
    to = if to == null then checkboxCount else to
    for i in [from..to]
      name = '#checkbox' + i
      $(name).prop "checked", true

#Same as previous but for unchecking
  $('#uncheckButton').click ->   
    from = $('#spinnerFrom').spinner "value"
    to = $('#spinnerTo').spinner "value"
    from = if from == null then 1 else from
    to = if to == null then checkboxCount else to
    for i in [from..to]
      name = '#checkbox' + i
      $(name).prop "checked", false

# This shift method shifts the times leaving the events potentially assorted
#  $('#shiftButton').click ->
#    shift = $('#spinnerShift').spinner "value"
#    for i in [1..checkboxCount]
#      checkboxName = '#checkbox' + i
#      if $(checkboxName).prop "checked"
#        itemName = '#item' + i
#        content = JSON.parse $(itemName).text()
#        content.time += shift
#        $(itemName).html '<input type="checkbox" id="checkbox'+i+'">'+JSON.stringify content, `undefined`, 2
#        $(checkboxName).prop "checked", true
#

#This shift method sorts the events by time
  $('#shiftButton').click ->
    shift = $('#spinnerShift').spinner "value"
    eventHolder = []
    for i in [1..checkboxCount]
      checkboxName = '#checkbox' + i
      itemName = '#item' + i
      content = JSON.parse $(itemName).text()
      if $(checkboxName).prop "checked"
        content.time += shift
      eventHolder.push content
    eventHolder.sort (a,b) -> return if a.time > b.time then 1 else -1
    $('#listOfEvents').empty()
    checkboxCount = 0
    for j in eventHolder
        str = JSON.stringify j, `undefined`, 2
        checkboxCount++
        $('#listOfEvents').append ('<li id="item' + checkboxCount + '"><input type="checkbox" id="checkbox' + 
        checkboxCount + '">' + str + '</li>')
        
#This method parses the changes back into recordingTracks 
  $('#parsebackButton').click ->
    if confirm '''Parsing in a new script will delete the old one.
                  Are you sure?'''
      newRecordingTracks = {}
      for i in [1..checkboxCount]
        itemName = '#item' + i
        content = JSON.parse $(itemName).text()
        if !(content.name of newRecordingTracks)
          newRecordingTracks[content.name] = []
        newRecordingTracks[content.name].push
          time: content.time
          value: content.value
      recordingTracks = newRecordingTracks


