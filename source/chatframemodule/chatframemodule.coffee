############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("chatframemodule")
#endregion

############################################################
import * as chat from "./chatsessionmodule.js"
import { sendMessage } from "./wsmodule.js"

############################################################
# placeholderContent = "Bitte gib mir Auskunft zu ..."
placeholderContent = null
primeInputParagraph = null

############################################################
responseBuffer = null
bufferFlushing = false
isStreaming = false
bufferTextNode = null

############################################################
chatHistory = null
isChatting = false

############################################################
sToClass = []
sToClass[chat.FROMUSER] = "user-message"
sToClass[chat.FROMASSBOTO] = "assboto-message"

############################################################
export initialize = ->
    log "initialize"
    primeInputParagraph = userInput.getElementsByTagName("p")[0]
    placeholderContent = primeInputParagraph.innerText
    sendButton.addEventListener("click", sendClicked)
    userInput.addEventListener("keyup", checkStateOnType)
    userInput.addEventListener("blur", checkStateOnBlur)
    return

############################################################
sendClicked = (evnt) ->
    log "sendClicked"
    content = userInput.textContent.trim()
    log content
    if content == "" or content == placeholderContent then return

    chat.addUserMessage(content)

    ## This is the only entry into chatting State :-)
    clearInputState()
    isChatting = true
    setResponseWaitingState()
    return

############################################################
checkStateOnType = (evnt) ->
    chat.sessionKeyProbe()

    content = userInput.textContent.trim()
    if !(content == placeholderContent) or evnt.key == "Enter" then userInput.className = ""
    return

checkStateOnBlur = (evnt) ->
    content = userInput.textContent.trim()
    if content == "" or content == placeholderContent then resetInputState()
    return

############################################################
resetInputState = ->
    userInput.innerHTML = ""
    userInput.appendChild(primeInputParagraph)
    primeInputParagraph.textContent = placeholderContent
    userInput.className = "initial"
    return

clearInputState = ->
    userInput.innerHTML = ""
    # userInput.appendChild(primeInputParagraph)
    # primeInputParagraph.textContent = placeholderContent
    # userInput.className = "initial"
    return

############################################################
historyScrollBottom = -> responseHistory.scrollIntoView({behavior: "instant", block: "end"})

############################################################
stopStreaming = ->
    isStreaming = false
    bufferFlushing = false
    responseBuffer = ""
    if bufferTextNode? then bufferTextNode.data = ""
    return

startStreaming = ->
    setResponseStreamingState()
    ## crate fresh bufferTextNode
    if bufferTextNode? then bufferTextNode.data += responseBuffer
    else
        bufferTextNode = document.createTextNode(responseBuffer)
        liveResponse.appendChild(bufferTextNode)
    responseBuffer = ""

    isStreaming = true
    return

############################################################
flushNext = ->
    if responseBuffer
        bufferTextNode.data += responseBuffer
        responseBuffer = ""
        historyScrollBottom()
    bufferFlushing = false
    return
 
############################################################
#region Local UI State Setters
setChattingState = ->
    if isStreaming then setResponseStreamingState()
    else setResponseWaitingState()
    return

setNonChattingState = ->
    log "setNonChattingState"
    stopStreaming()
    if !chatHistory? then return setNoHistoryState()
    if chat.getErrorState() then return setErrorState()
    if !chat.hasValidSessionKey() then return setDeprecatedHistoryState()
    setActiveHistoryState()
    return

############################################################
setNoHistoryState = ->
    log "setNoHistoryState"
    chatframe.classList = "no-response"
    inputOuter.classList = "active"
    header.classList = "no-history"

    if liveResponse.isConnected then responseHistory.removeChild(liveResponse)
    if responseWaitFrame.isConnected then responseHistory.removeChild(responseWaitFrame)
    return

setErrorState = ->
    log "setErrorState"
    inputOuter.classList = "error"
    ## We can only have an error, when trying to get a response
    #    So we have a history :-)
    chatframe.classList = "response"
    header.classList = "history"

    if liveResponse.isConnected then responseHistory.removeChild(liveResponse)
    if responseWaitFrame.isConnected then responseHistory.removeChild(responseWaitFrame)
    return

setDeprecatedHistoryState = ->
    log "setDeprecatedHistoryState"
    ## here we could not do anything but look at our old chat or delete it
    chatframe.classList = "response"
    inputOuter.classList = "frozen"
    header.classList = "history"

    if liveResponse.isConnected then responseHistory.removeChild(liveResponse)
    if responseWaitFrame.isConnected then responseHistory.removeChild(responseWaitFrame)
    return
    
setActiveHistoryState = ->
    log "setActiveHistoryState"
    ## regular chattable state with responses
    chatframe.classList = "response"
    inputOuter.classList = "active"
    header.classList = "history"

    if liveResponse.isConnected then responseHistory.removeChild(liveResponse)
    if responseWaitFrame.isConnected then responseHistory.removeChild(responseWaitFrame)
    return

############################################################
setResponseWaitingState = ->
    log "setResponseWaitingState"
    chatframe.classList = "response"
    inputOuter.classList = "frozen"
    header.classList = "history-non-deletable"

    ## Remove liveResponse  - add responseWaitFrame frame
    if liveResponse.isConnected then responseHistory.removeChild(liveResponse)
    responseHistory.appendChild(responseWaitFrame) unless responseWaitFrame.isConnected
    return

setResponseStreamingState = ->
    log "setResponseStreamingState"
    chatframe.classList = "response"
    inputOuter.classList = "frozen"
    header.classList = "history-non-deletable"

    ## Remove responseWaitFrame  - add liveResponse frame
    if responseWaitFrame.isConnected then responseHistory.removeChild(responseWaitFrame)
    responseHistory.appendChild(liveResponse) unless liveResponse.isConnected
    return

#endregion

############################################################
export addToResponseBuffer = (frag) ->
    log "addToResponseBuffer"
    # return unless typeof responseBuffer == "string"
    responseBuffer += frag
    startStreaming() unless isStreaming
    requestAnimationFrame(flushNext) unless bufferFlushing
    return

############################################################
export setChatHistory = (messages) ->
    log "setChatHistory"
    chatHistory = messages

    ## Chat History is only being set when we are not chatting
    isChatting = false
    setNonChattingState() 

    html = ""
    if Array.isArray(chatHistory)
        for msgObj in messages
            html += '<div class="'
            html += sToClass[msgObj.s]
            html += '"><p>'+msgObj.m+'</p></div>'

    responseHistory.innerHTML = html
    requestAnimationFrame(historyScrollBottom)
    return

############################################################
export resetState = ->
    log "resetState"
    if isChatting then setChattingState()
    else setNonChattingState()
    return