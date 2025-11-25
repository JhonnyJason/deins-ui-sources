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
noSession = true
chatHistory = null

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
    return

############################################################
checkStateOnType = (evnt) ->
    if noSession then chat.startAuthorizedSession()
    noSession = false

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
    ## Remove responseWaitFrame  - add liveResponse frame
    if responseWaitFrame.isConnected then responseHistory.removeChild(responseWaitFrame)
    responseHistory.appendChild(liveResponse) unless liveResponse.isConnected

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
setPreChattingState = ->
    log "setPreChattingState"
    chatframe.classList = "no-response"
    header.classList = "no-history"
    return

setChattingState = ->
    log "setChattingState"
    chatframe.classList = "response"
    header.classList = "history"
    return

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
    stopStreaming()

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
export setProcessingResponseState = ->
    log "setProcessingResponseState"
    stopStreaming()

    chatframe.classList = "response"
    clearInputState()
    inputOuter.className = "frozen"

    ## remove liveResponse and add responseWaitFrame
    if liveResponse.isConnected then responseHistory.removeChild(liveResponse)
    responseHistory.appendChild(responseWaitFrame) unless responseWaitFrame.isConnected
    return

export setDefaultState = ->
    log "setDefaultState"
    stopStreaming()

    if chatHistory? then setChattingState()
    else setPreChattingState()

    inputOuter.className = ""

    ## Remove liveResponse and responseWaitFrame    
    if liveResponse.isConnected then responseHistory.removeChild(liveResponse)
    if responseWaitFrame.isConnected then responseHistory.removeChild(responseWaitFrame)
    return
