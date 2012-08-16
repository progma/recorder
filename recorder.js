// Zadefinuju si tady promenny globalne, aby nepatrily do scopu jQueriho
// handleru a mohl bych je zkoumat v konzoli.
var myCodeMirror, myPlaybackMirror, recordedLog, recordingStartTime;

$(function () {

myCodeMirror = CodeMirror.fromTextArea($("#editorArea").get(0));
myPlaybackMirror = CodeMirror.fromTextArea($("#playbackArea").get(0),
                                           {readOnly: true});

function captureCurrentState () {
    return { bufferContents: myCodeMirror.getValue(),
             cursorPosition: myCodeMirror.getCursor(),
             selectionRange: { from: myCodeMirror.getCursor(true),
                               to: myCodeMirror.getCursor(false) },
             scrollPosition: myCodeMirror.getScrollInfo() };
};

$("#startButton").click(function () {
    recordedLog = [];
    recordingStartTime = new Date();

    // Tady bychom mohli delat to same jako v recordCurrentState,
    // ale potom by prvni zaznam v recordedLog mel nenulovy cas
    // a tudiz by nebyl pro interval mezi 0 a tim casem definovany
    // zadny stav.
    var initialState = captureCurrentState();
    initialState.time = 0;

    recordedLog.push(initialState);
});

function recordCurrentState() {
    var currentState = captureCurrentState();
    currentState.time = new Date() - recordingStartTime;

    recordedLog.push(currentState);
};    

// Timhle odchytime zatim vsechny aktivity CodeMirror bufferu,
// ktere nas zajimaji.
myCodeMirror.setOption("onCursorActivity", recordCurrentState);
myCodeMirror.setOption("onScroll", recordCurrentState);

$("#playButton").click(function () {
    $("#playbackArea").get(0).focus();
    $.map(recordedLog, function (event) {
        setTimeout(function () {
            // Opakovany volani menici stav CodeMirroru muzou bejt takhle
            // zabaleny do jedny operace, aby nemusel prepocitavat vzhled
            // v tech mezistavech. Operation bere funkci, ale namisto toho,
            // aby vratilo tu agregovanou, tak ji jeste rovnou zavola, takze
            // se to jeste cele musi obalit do lambdy.
            myPlaybackMirror.operation(function () {
                // Tohle je asi jedina vec, kterou nechceme setovat zbytecne.
                if (myPlaybackMirror.getValue() !== event.bufferContents) {
                    myPlaybackMirror.setValue(event.bufferContents);
                }
                myPlaybackMirror.setCursor(event.cursorPosition);
                myPlaybackMirror.setSelection(event.selectionRange.from,
                                              event.selectionRange.to);
                myPlaybackMirror.scrollTo(event.scrollPosition.x,
                                          event.scrollPosition.y);});},
                   event.time);});
});

$("#dumpButton").click(function () {
    $("#dumpArea").val(JSON.stringify(recordedLog, undefined, 2));
});

$("#parseButton").click(function () {
    recordedLog = JSON.parse($("#dumpArea").val());
});

});