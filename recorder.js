// Zadefinuju si tady promenny globalne, aby nepatrily do scopu jQueryho
// handleru a mohl bych je zkoumat v konzoli.
var myCodeMirror, myPlaybackMirror, recordingTracks, recordingStartTime;

$(function () {

myCodeMirror = CodeMirror.fromTextArea($("#editorArea").get(0));
myPlaybackMirror = CodeMirror.fromTextArea($("#playbackArea").get(0),
                                           {readOnly: true});

// The things I track and how to compute and set them.
var tracking = { bufferContents:
                 { compute: function () { return myCodeMirror.getValue();},
                   set: function (value) { myPlaybackMirror.setValue(value);}},
                 cursorPosition:
                 { compute: function () { return myCodeMirror.getCursor();},
                   set: function (value) { myPlaybackMirror.setCursor(value);}},
                 selectionRange:
                 { compute: function () {
                     return { from: myCodeMirror.getCursor(true),
                              to: myCodeMirror.getCursor(false)};},
                   set: function (value) {
                       myPlaybackMirror.setSelection(value.from, value.to);}},
                 scrollPosition:
                 { compute: function () { return myCodeMirror.getScrollInfo();},
                   set: function (value) {
                      var destination = myPlaybackMirror.getScrollInfo();
                      myPlaybackMirror.scrollTo(value.x / value.width * destination.width,
                                                value.y / value.height * destination.height);}}};

$("#startButton").click(function () {
    recordingTracks = {};
    recordingStartTime = new Date();

    $.each(tracking, function (name, methods) {
        recordingTracks[name] = [];
        recordingTracks[name].push({ time: 0,
                                     value: methods.compute()});
    });
});

function recordCurrentState() {
    $.each(tracking, function (name, methods) {
        var ourTrack = recordingTracks[name];
        var currentState = methods.compute();
        if (!_.isEqual(currentState, _.last(ourTrack).value)) {
            ourTrack.push({ time: new Date() - recordingStartTime,
                            value: currentState});
        };
    });
};

// Timhle odchytime zatim vsechny aktivity CodeMirror bufferu,
// ktere nas zajimaji.
myCodeMirror.setOption("onCursorActivity", recordCurrentState);
myCodeMirror.setOption("onScroll", recordCurrentState);

$("#playButton").click(function () {
    // This doesn't seem to set the focus of the playback CodeMirror
    // buffer correctly.
    $("#playbackArea").get(0).focus();
    $.each(recordingTracks, function (name, track) {
        $.map(track, function (event) {
            setTimeout(function () {
                tracking[name].set(event.value);},
                       event.time);});});
});

$("#dumpButton").click(function () {
    $("#dumpArea").val(JSON.stringify(recordingTracks, undefined, 2));
});

$("#parseButton").click(function () {
    recordingTracks = JSON.parse($("#dumpArea").val());
});

});