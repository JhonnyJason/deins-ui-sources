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
resetTimeoutMS = 12_000
resetDisabled = false

############################################################
setFailed = null
setReady = null
ready = new Promise((
    (rslv,rjct) -> 
        setReady = rslv
        setFailed = rjct
))

############################################################
speedDelay = null

############################################################
export initialize = (c) ->
    log "initialize"
    if c and c.heartbeatMS then relaxedHeartbeatMS = c.heartbeatMS
    if c and c.urlWebsocketBackend then urlWebsocketBackend = c.urlWebsocketBackend
    createSocket() # try to connect already here
    return

############################################################
resetReadinessPromise = ->
    log "resetReadinessPromise"
    if setFailed? then setFailed()
    ready = new Promise((
        (rslv,rjct) -> 
            setReady = rslv
            setFailed = rjct
    ))    
    return

setSpeedDelay = ->
    log "setSpeedDelay"
    speedDelay = new Promise(((rslv) -> setTimeout(rslv, resetTimeoutMS)))
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

destroySocket = ->
    return unless socket?
    resetReadinessPromise()
    socket.removeEventListener("open", socketOpened)
    socket.removeEventListener("message", receiveData)
    socket.removeEventListener("error", receiveError)
    socket.removeEventListener("close", socketClosed)
    socket = null
    pingTime = 0
    return

############################################################
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

heartbeat = ->
    log "heartbeat"
    if !socket? then return createSocket()
    
    if socket.readyState == WebSocket.OPEN then sendPing()

    if socket.readyState == WebSocket.CLOSED
        destroySocket()
        startStressReconnect()

    return

############################################################
socketOpened = (evnt) ->
    log "socketOpened"
    clearTimeout(stressTimeout)
    stressHeartbeatMS = 0
    setReady()
    sendSateRequest()
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
            when "key" then chat.setSessionKey(arg)
            when "stt" then chat.noticeSessionState(arg)
            when "err" then noticeError(arg)
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

############################################################
noticeError = (err) ->
    log "noticeError"
    log err
    switch err
        when "TooFast" then setSpeedDelay()
        else console.error("Unhandeled Error! (#{err})")

############################################################
sendPing = ->
    log "sendPing"
    if pingTime > 0 
        console.error("No pong has been received through a whole heartbeat!")
        ## maybe do something about the bad network health
    # send fresh ping
    pingTime = performance.now()
    send("ping")
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
send = (msg) ->
    sent = false
    while !sent
        try
            await ready
            await speedDelay
            log "sending: "+msg
            socket.send(msg)
            sent = true
        catch err then console.error(err)

############################################################
export startHeartbeat = ->
    log "startHeartbeat"
    # fire up the relaxed interval
    relaxedInterval = setInterval(heartbeat, relaxedHeartbeatMS)

    # first heartbeat here - not wait for first interval
    heartbeat() # starts stressMode if we are in"closed" state or have no socket
    return

############################################################
export sendAutorizeMe = (key) ->
    log "sendAutorizeMe"

    cmd = "authorizeMe"
    if !key then return send(cmd)

    if typeof key == "string" and key.length > 0 then send(cmd+" "+key)
    else send(cmd)
    return

export sendInterferenceRequest = (msg) ->
    log "sendInterferenceRequest"
    msg = "interference "+msg
    send(msg)
    return

export sendInterferenceAck = ->
    log "sendInterferenceAck"
    msg = "interferenceAck"
    send(msg)
    return

export sendHistoryReset = ->
    log "sendHistoryReset"
    return if resetDisabled

    setTimeout((() -> resetDisabled = false), resetTimeoutMS)
    resetDisabled = true
    send("resetHistory")
    return

export sendSateRequest = ->
    log "sendSateRequest"
    msg = "sendState"
    send(msg)
    return

############################################################
export sendMessage = (msg) ->
    log "sendMessage"
    log msg
    send(msg)
    return
