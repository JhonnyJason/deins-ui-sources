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
    
    if chatStorage.msgs? and (chatStorage.msgs.length > 0)
        frame.setChatHistory(chatStorage.msgs)
        frame.setDefaultState()
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
    log "Whole Response took: "+(end - intfStartTime)+"ms"
    log "Request to stream-start: "+(intfStreamStartTime - intfStartTime)+"ms"
 
    intfStartTime = null
    intfStreamStartTime = null
    return

############################################################
export startAuthorizedSession = ->
    log "startAuthorizedSession"
    key = chatStorage.key || ""
    ws.sendAutorizeMe(key)
    return

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
    stopAndReportTimings()
    msgObj = { m:newResponse, s:FROMASSBOTO }
    
    # actually this should be impossible... but keep it :-)
    if !chatStorage.msgs? then chatStorage.msgs = []
    
    chatStorage.msgs.push(msgObj)
    frame.setChatHistory(chatStorage.msgs)
    frame.setDefaultState()
    saveStorage()
    return

export setNewSessionKey = (key) ->
    log "setNewSessionKey"
    if chatStorage.key == key then return
    
    chatStorage.key = key
    chatStorage.msgs = []
    
    frame.setChatHistory(null)
    frame.setDefaultState()

    saveStorage()
    return

############################################################
export addUserMessage = (msg) ->
    log "addUserMessage"
    msgObj = { m:msg, s:FROMUSER }
    if !chatStorage.msgs? then chatStorage.msgs = []
    chatStorage.msgs.push(msgObj)
    frame.setChatHistory(chatStorage.msgs)
    frame.setProcessingResponseState()
    saveStorage()
    setStartTime()
    ws.sendInterferenceRequest(msg)
    return