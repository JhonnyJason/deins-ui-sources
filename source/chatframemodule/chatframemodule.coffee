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
responseBuffer = null

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

############################################################
export addToResponseBuffer = (frag) ->
    log "addToResponseBuffer"
    # return unless typeof responseBuffer == "string"
    responseBuffer += frag
    return

############################################################
export setChatHistory = (messages) ->
    log "setChatHistory"
    chatHistory = messages
    html = ""
    
    if Array.isArray(chatHistory)
        for msgObj in messages
            html += '<div class="'
            html += sToClass[msgObj.s]
            html += '"><p>'+msgObj.m+'</p></div>'

    responseHistory.innerHTML = html
    return


############################################################
export setProcessingResponseState = ->
    log "setProcessingResponseState"
    responseBuffer = ""
    chatframe.classList = "response"
    return

export setDefaultState = ->
    log "setDefaultState"
    responseBuffer = null
    if chatHistory? then chatframe.classList = "response"
    else chatframe.classList = "no-response"
    return
