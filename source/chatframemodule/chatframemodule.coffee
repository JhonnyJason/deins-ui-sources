############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("chatframemodule")
#endregion

############################################################
import { sendMessage } from "./wsmodule.js"

############################################################
# placeholderContent = "Bitte gib mir Auskunft zu ..."
placeholderContent = null
primeInputParagraph = null

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

    sendMessage(content)
    return

############################################################
checkStateOnType = (evnt) ->
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
