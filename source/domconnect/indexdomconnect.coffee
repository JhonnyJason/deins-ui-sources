indexdomconnect = {name: "indexdomconnect"}

############################################################
indexdomconnect.initialize = () ->
    global.content = document.getElementById("content")
    global.chatframe = document.getElementById("chatframe")
    global.responseHistory = document.getElementById("response-history")
    global.userInput = document.getElementById("user-input")
    global.sendButton = document.getElementById("send-button")
    return
    
module.exports = indexdomconnect