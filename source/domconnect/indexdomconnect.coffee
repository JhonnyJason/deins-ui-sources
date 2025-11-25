indexdomconnect = {name: "indexdomconnect"}

############################################################
indexdomconnect.initialize = () ->
    global.content = document.getElementById("content")
    global.chatframe = document.getElementById("chatframe")
    global.responseHistory = document.getElementById("response-history")
    global.liveResponse = document.getElementById("live-response")
    global.responseWaitFrame = document.getElementById("response-wait-frame")
    global.inputOuter = document.getElementById("input-outer")
    global.userInput = document.getElementById("user-input")
    global.sendButton = document.getElementById("send-button")
    global.header = document.getElementById("header")
    global.deleteHistoryButton = document.getElementById("delete-history-button")
    return
    
module.exports = indexdomconnect