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

#new global vars, array for events regardless of type and number of them
eventHolder = []
checkboxCount = 0
#array for holding events of the replay window
timedEvents = []
#variable for the number of the currently selected state of the track
selectedState = 0

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

startRecording = ->
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

#stops previous replay and starts a new one
playTrack = ->
  #clear previous replay
  clearTimeout event for event in timedEvents
  timedEvents = []
  
  myPlaybackMirror.focus()
  $.each recordingTracks, (name, track) ->
    $.map track, (event) ->
      playTheValue = ->
        playbook[name] event.value,
                       codeMirror: myPlaybackMirror
                       turtleDiv: $('#turtleSpace').get(0)
                       turtle3dCanvas: $('#turtleCanvas').get(0)
                       evaluationContext: EVALUATION_CONTEXT
      #set timeout for next event and save this
      timedEvents.push setTimeout playTheValue, event.time

#normalisation function for the eventHolder
normaliseEventHolder = ->
  eventHolder.sort (a,b) -> return if a.time > b.time then 1 else -1

#conversion functions between recordingTracks and eventHolder
recordingTracksToEventHolder = ->
  eventHolder = []
  for own key of recordingTracks
      for event in recordingTracks[key]
        eventHolder.push
          name: key
          time: event.time
          value: event.value
  normaliseEventHolder()

eventHolderToRecordingTracks = ->
  recordingTracks = {}
  for event in eventHolder
    if !(event.name of recordingTracks)
      recordingTracks[event.name] = []
    recordingTracks[event.name].push
      time: event.time
      value: event.value

#function for creating the html list of events
outputListOfEvents = ->
  $('#tableOfEvents').empty()
  $('<tr><td>No.</td><td>Selected</td><td>Time</td>
    <td>Type of event</td><td>Value</td></tr>').appendTo $('#tableOfEvents')
  checkboxCount = 0
  for event in eventHolder
        checkboxCount++
        newRow = $('<tr class="clickable" id=' + checkboxCount + '>')
        newRow.append $('<td>' + checkboxCount + '</td>')
        newRow.append $('<td>').append $('<input>',
          type: "checkbox"
          id: "checkbox" + checkboxCount
          )
        newRow.append $('<td>' + event.time + '</td>')
        newRow.append $('<td>' + event.name + '</td>')
        str = JSON.stringify (event.value), `undefined`, 2
        newRow.append $('<td class = "value">' + str + '</td>')
        $('#tableOfEvents').append newRow
   #if something was selected, it is not anymore
   selectedState = 0

#get current values of range selecting spinners
# if the left resp. right boundary is not given, prefix resp. suffix of the list is selected
getSpinnerRange = ->
  from = $('#spinnerFrom').spinner "value"
  to = $('#spinnerTo').spinner "value"
  from = if from == null then 1 else from
  to = if to == null then checkboxCount else to
  return [from, to]

#check/uncheck a range of checkboxes based on boolVal = true/false
setCheckboxRange = (from, to, boolVal) ->
  for i in [from..to]
    name = '#checkbox' + i
    $(name).prop "checked", boolVal

#This shift method shifts selected events and resorts
shiftEvents = ->
  shift = $('#spinnerShift').spinner "value"
  for i in [1..checkboxCount]
    checkboxName = '#checkbox' + i
    if $(checkboxName).prop "checked"
      eventHolder[i-1].time += shift
  normaliseEventHolder()
  outputListOfEvents()
      

#Delete selected lines
deleteEvents = ->
  offset = 0
  for i in [1..checkboxCount]
    checkboxName = '#checkbox' + i
    if $(checkboxName).prop "checked"
      eventHolder.splice i-1-offset, 1
      offset++
  outputListOfEvents()

#After recording an additional track into recordingTracks,
#insert it into current track stored in eventHolder at time given by spinnerInsert
#update recordingTracks accordingly
insertTrack = ->
  #compute insertion time, 0 if no event was selected
  insertTime = if selectedState == 0 then 0 else eventHolder[selectedState-1].time

  #save old track
  tempEventHolder = eventHolder.slice()
  
  #load new track
  recordingTracksToEventHolder()
  normaliseEventHolder()
  
  #shift part of the old track which should take place after the new track
  shift = eventHolder[eventHolder.length-1].time
  event.time += shift for event in tempEventHolder when event.time > insertTime
  
  #shift the new track to the desired time stamp
  event.time += insertTime for event in eventHolder
  
  #merge old and new tracks
  eventHolder = eventHolder.concat tempEventHolder
  normaliseEventHolder()
  outputListOfEvents()

selectState = ->
  #color the selected line
  if selectedState == this.id
    $('#'+this.id).css 'background-color', 'white'
    selectedState = 0
  else
    $('#'+this.id).css 'background-color', 'yellow'
    if selectedState != 0
      $('#'+selectedState).css 'background-color', 'white'
    selectedState = this.id

   #display the selected state
   displayState this.id - 1

displayState = (event) ->
  for i in [0..event]
        playbook[eventHolder[i].name] eventHolder[i].value,
                                      codeMirror: myCodeMirror
                                      turtleDiv: $('#turtleSpace').get(0)
                                      turtle3dCanvas: $('#turtleCanvas').get(0)
                                      evaluationContext: EVALUATION_CONTEXT
  myCodeMirror.focus()


$ ->
  if EVALUATION_CONTEXT == "turtle3d"
    $('#turtleSpace').append $('<canvas>', id: 'turtleCanvas')

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get 0
  myPlaybackMirror = CodeMirror.fromTextArea $('#playbackArea').get(0),
                                             readOnly: true

  # Timhle odchytime zatim vsechny aktivity CodeMirror bufferu,
  # ktere nas zajimaji.
  myCodeMirror.setOption 'onCursorActivity', recordCurrentState
  myCodeMirror.setOption 'onScroll', recordCurrentState

  
  ### BUTTONS ###

  $('#startButton').click startRecording

  $('#evalButton').click evalCode
  $(document).add(myCodeMirror.getInputField()).bind 'keydown.alt_c', evalCode

  $('#nextButton').add('#prevButton').click ->
    if recordingNow
      recordingTracks['buttonPressed'].push
        time: new Date() - recordingStartTime
        value: this.id

  $('#playButton').click playTrack

  $('#dumpButton').click ->
    $('#dumpArea').val JSON.stringify recordingTracks, `undefined`, 2
		
  $('#parseButton').click ->
    if confirm '''Parsing in a new script will delete the old one.
                  Are you sure?'''
      recordingTracks = JSON.parse $('#dumpArea').val()

# This button produces a list of all events sorted by time from recordingTracks 
  $('#listButton').click ->
    recordingTracksToEventHolder()
    outputListOfEvents()

# button for checking a range of checkboxes
  $('#checkButton').click ->
    [from, to] = getSpinnerRange()
    setCheckboxRange from, to, true

#button for unchecking a range of checkboxes
  $('#uncheckButton').click ->
    [from, to] = getSpinnerRange()
    setCheckboxRange from, to, false

  $('#shiftButton').click shiftEvents

#This method parses the changes back into recordingTracks 
  $('#parsebackButton').click ->
    if confirm '''Parsing in a new script will delete the old one.
                  Are you sure?'''
      eventHolderToRecordingTracks()

  $('#deleteButton').click deleteEvents

  $('#insertButton').click insertTrack

#selecting an event after which to insert new stuff
  $('#tableOfEvents').on 'click', '.clickable', selectState
