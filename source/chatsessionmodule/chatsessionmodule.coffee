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
    newResponse += frag
    frame.addToResponseBuffer(frag)
    return

export endResponseReceive = ->
    log "endResponseReceive"
    log "Full Response:\n"+newResponse
    msgObj = { m:newResponse, s:FROMASSBOTO }
    
    # actually this should be impossible... but keep it :-)
    if !chatStorage.msgs? then chatStorage.msgs = []
    
    chatStorage.msgs.push(msgObj)
    frame.setChatHistory(chatStorage.msgs)
    frame.setDefaultState()
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
    ws.sendInterferenceRequest(msg)
    return