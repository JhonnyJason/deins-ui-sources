############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("chatsessionmodule")
#endregion

############################################################
import * as S from "./statemodule.js"
import * as ws from "./wsmodule.js"
import * as frame from "./chatframemodule.js"

############################################################
chatStorage = null
newResponse = ""

############################################################
newKey = null
validKey = false
errorState = null

############################################################
intfStartTime = null
intfStreamStartTime = null

############################################################
export FROMUSER = 0
export FROMASSBOTO = 1

############################################################
export initialize = ->
    log "initialize"
    chatStorage = S.load("chatStorage")
    S.setChangeDetectionFunction("chatStorage", (() -> true))

    olog chatStorage

    if !chatStorage?
        chatStorage = {}
        saveStorage()

    if chatStorage.key? then ws.sendAutorizeMe(chatStorage.key)
    if chatStorage.msgs? and (chatStorage.msgs.length > 0)
        frame.setChatHistory(chatStorage.msgs)

    deleteHistoryButton.addEventListener("click", deleteHistory)
    return

############################################################
saveStorage = -> S.save("chatStorage", chatStorage)

setStartTime = ->
    log "setStartTime"
    intfStartTime = Date.now()
    intfStreamStartTime = null
    return

stopAndReportTimings = ->
    log "stopAndReportTimings"
    end = Date.now()
    console.log "Whole Response took: "+(end - intfStartTime)+"ms"
    console.log "Request to stream-start: "+(intfStreamStartTime - intfStartTime)+"ms"
 
    intfStartTime = null
    intfStreamStartTime = null
    return

############################################################
createSession = (key) ->
    log "createSession"    
    chatStorage.key = key
    chatStorage.msgs = []
    validKey = true
    newKey = null

    frame.setChatHistory(null)
    saveStorage()
    return

############################################################
deleteHistory = ->
    log "deleteHistory"
    if validKey then ws.sendHistoryReset()

    if newKey? then createSession(newKey)
    else
        chatStorage = {}
        frame.setChatHistory(null)
        saveStorage()
    return

############################################################
checkKeySituation = (key) ->
    log "checkKeySituation"
    if chatStorage.key? and chatStorage.key == key then validKey = true
    if chatStorage.key? and chatStorage.key != key then validKey = false
    
    # No key here set but the relay service has one for us 
    if !chatStorage.key?
        log "We did not have a key - set new Session!"
        createSession(key) # set correct state here
        # we need to reset History as locally we have/had none
        ws.sendHistoryReset()
    else log "Checking against old session resulted in validKey="+validKey
    return

############################################################
handleMessageLimitReached = ->
    log "handleMessageLimitReached - not implemented yet!"
    ## TODO implement
    return

handleProcessingState = ->
    log "handleProcessingState - not implemented yet!"
    ## TODO implement
    return

handleWaitingAckState = ->
    log "handleWaitingAckState - not implemented yet!"
    ## TODO implement
    return

############################################################
export sessionKeyProbe = ->
    log "startAuthorizedSession"
    return if validKey

    ws.sendAutorizeMe("")
    return

export hasValidSessionKey = -> validKey

############################################################
export getErrorState = -> errorState

############################################################
export startResponseReceive = ->
    log "startResponseReceive"
    newResponse = ""
    return

export receiveResponseFragment = (frag) ->
    log "receiveResponseFragment"
    if !intfStreamStartTime then intfStreamStartTime = Date.now()
    newResponse += frag
    frame.addToResponseBuffer(frag)
    return

export endResponseReceive = ->
    log "endResponseReceive"
    log "Full Response:\n"+newResponse
    ws.sendInterferenceAck() # immediately acknowledge 

    stopAndReportTimings() # Just to see the timing
    msgObj = { m:newResponse, s:FROMASSBOTO }
    
    # actually this should be impossible... but keep it :-)
    if !chatStorage.msgs? then chatStorage.msgs = []
    
    chatStorage.msgs.push(msgObj)
    frame.setChatHistory(chatStorage.msgs)
    # frame.setDefaultState()
    saveStorage()
    return

export setSessionKey = (key) ->
    log "setSessionKey"
    checkKeySituation(key)
    if !validKey then newKey = key
    return

############################################################
export noticeSessionState = (state) ->
    log "noticeSessionState"
    log state    
    stateEnd = state.indexOf(" ")
    if stateEnd > 0
        key = state.slice(stateEnd+1)
        state = state.slice(0, stateEnd)

    olog {state, key}

    ## check if we have the valid key Locally
    if key? then checkKeySituation(key)
    else validKey = false
    
    switch state
        when "MessageLimitReached" then handleMessageLimitReached()
        when "Processing" then handleProcessingState()
        when "WaitingAck" then handleWaitingAckState()
        when "Idle" then log "All good :-)"
        when "InvalidKey" then validKey = false
        else console.error("Unhandled State: "+state)

    frame.resetState()
    return

############################################################
export addUserMessage = (msg) ->
    log "addUserMessage"
    msgObj = { m:msg, s:FROMUSER }
    if !chatStorage.msgs? then chatStorage.msgs = []
    chatStorage.msgs.push(msgObj)
    frame.setChatHistory(chatStorage.msgs)
    saveStorage()
    setStartTime()
    ws.sendInterferenceRequest(msg)
    return