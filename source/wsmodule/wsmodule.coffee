############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("wsmodule")
#endregion

############################################################
import * as chat from "./chatsessionmodule.js"

############################################################
socket = null
pingTime = 0
isOpen = false

############################################################
stressHeartbeatMS = 0
stressLoss = 300
############################################################
stressTimeout = null
relaxedInterval = null

############################################################
maxStressHeartbeatMS = 500
minStressHeartbeatMS = 6000
############################################################
relaxedHeartbeatMS = 120_000
urlWebsocketBackend = "https://localhost:3333"

############################################################
resetTimeoutMS = 10_000
resetDisabled = false

############################################################
export initialize = (c) ->
    log "initialize"
    if c and c.heartbeatMS then relaxedHeartbeatMS = c.heartbeatMS
    if c and c.urlWebsocketBackend then urlWebsocketBackend = c.urlWebsocketBackend
    createSocket() # try to connect already here
    return


############################################################
createSocket = ->
    log "createSocket"
    try
        socket = new WebSocket(urlWebsocketBackend)

        socket.addEventListener("open", socketOpened)
        socket.addEventListener("message", receiveData)
        socket.addEventListener("error", receiveError)
        socket.addEventListener("close", socketClosed)

    catch err then log err
    return

############################################################
socketOpened = (evnt) ->
    log "socketOpened"
    sendPing()
    clearTimeout(stressTimeout)
    stressHeartbeatMS = 0
    isOpen = true
    return

receiveData = (evnt) ->
    log "receiveData"
    if !(typeof evnt.data == "string")
        return console.error("WS received non-string message data!")
    msg = evnt.data 
    log msg

    try
        if msg == "pong" then return receivePong()
        cmdEnd = msg.indexOf(" ")
        if cmdEnd < 3 then cmd = msg
        else
            cmd = msg.slice(0, cmdEnd)
            arg = msg.slice(cmdEnd+1) # argStart is cmdEnd+1 leaving out the " "
        
        log cmd
        log arg

        switch cmd
            when "ai:" then chat.startResponseReceive()
            when "ai+" then chat.receiveResponseFragment(arg)
            when "ai/" then chat.endResponseReceive()
            when "key" then chat.setNewSessionKey(arg)
            else console.error("Unsupported Command: "+cmd)

    catch err then console.error(err)
    return

receiveError = (evnt) ->
    log "receiveError"
    olog evnt
    return

socketClosed = (evnt) ->
    log "socketClosed"
    log evnt.reason
    destroySocket()
    startStressReconnect()
    return

destroySocket = ->
    return unless socket?
    socket.removeEventListener("open", socketOpened)
    socket.removeEventListener("message", receiveData)
    socket.removeEventListener("error", receiveError)
    socket.removeEventListener("close", socketClosed)
    socket = null
    pingTime = 0
    isOpen = false
    return

startStressReconnect = ->
    log "startStressReconnect"
    clearTimeout(stressTimeout)
    stressHeartbeatMS = maxStressHeartbeatMS
    stressTimeout = setTimeout(stressedHeartbeat, stressHeartbeatMS)
    return

stressedHeartbeat = ->
    log "stressedHeartbeat"
    heartbeat()
    stressHeartbeatMS += stressLoss
    if stressHeartbeatMS > minStressHeartbeatMS 
        stressHeartbeatMS = minStressHeartbeatMS    
    stressTimeout = setTimeout(stressedHeartbeat, stressHeartbeatMS)
    return


############################################################
sendPing = ->
    log "sendPing"
    if pingTime > 0 
        console.error("No pong has been received through a whole heartbeat!")
        ## maybe do something about the bad network health
    # send fresh ping
    pingTime = performance.now()
    socket.send("ping")
    return

receivePong = (msg) ->
    log "receivePong"
    pongTime = performance.now()
    dif = pongTime - pingTime
    log "ping-pong took #{dif}ms"
    ## TODO save anything about network health state
    pingTime = 0
    return

############################################################
export startHeartbeat = ->
    log "startHeartbeat"
    # fire up the relaxed interval
    relaxedInterval = setInterval(heartbeat, relaxedHeartbeatMS)

    # first heartbeat here - not wait for first interval
    heartbeat() # starts stressMode if we are in"closed" state or have no socket
    return

export heartbeat = ->
    log "heartbeat"
    if !socket? then return createSocket()
    
    if socket.readyState == WebSocket.OPEN then sendPing()

    if socket.readyState == WebSocket.CLOSED
        destroySocket()
        startStressReconnect()

    return

############################################################
export sendAutorizeMe = (key) ->
    log "sendAutorizeMe"
    return unless isOpen

    cmd = "authorizeMe"
    if !key then return socket.send(cmd)

    if typeof key == "string" and key.length > 0 
        socket.send(cmd+" "+key)
    else socket.send(cmd)
    return

export sendInterferenceRequest = (msg) ->
    log "sendInterferenceRequest"
    msg = "interference "+msg
    socket.send(msg)
    return

export sendHistoryReset = ->
    log "sendHistoryReset"
    return if resetDisabled

    setTimeout((() -> resetDisabled = false), resetTimeoutMS)
    resetDisabled = true
    socket.send("resetHistory")
    return

############################################################
export sendMessage = (msg) ->
    log "sendMessage"
    return unless isOpen
    log msg
    socket.send(msg)
    return
