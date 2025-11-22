############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("wsmodule")
#endregion

############################################################
socket = null

############################################################
heartbeatMS = 2000
urlWebsocketBackend = "https://localhost:3333"

############################################################
export initialize = (c) ->
    log "initialize"
    if c and c.heartbeatMS then heartbeatMS = c.heartbeatMS
    if c and c.urlWebsocketBackend then urlWebsocketBackend = c.urlWebsocketBackend
    createSocket()    
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
    socket.send("ping")
    return

receiveData = (evnt) ->
    log "receiveData"
    try
        log evnt.data
        ##TODO check what to do here :-)
        # data = JSON.parse(evnt.data)
        # olog data
        ## Update other parts
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
    return

destroySocket = ->
    return unless socket?
    socket.removeEventListener("open", socketOpened)
    socket.removeEventListener("message", receiveData)
    socket.removeEventListener("error", receiveError)
    socket.removeEventListener("close", socketClosed)
    socket = null
    return


############################################################
export startHeartbeat = ->
    log "startHeartbeat"
    setInterval(heartbeat, heartbeatMS)
    return

export heartbeat = ->
    log "heartbeat"
    if !socket? then return createSocket()
    
    if socket.readyState == WebSocket.OPEN
        socket.send("ping")

    if socket.readyState == WebSocket.CLOSED
        destroySocket()

    return

############################################################
export sendMessage = (msg) ->
    log "sendMessage"
    log msg
    return
