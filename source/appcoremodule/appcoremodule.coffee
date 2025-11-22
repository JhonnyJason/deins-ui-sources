############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("appcoremodule")
#endregion

############################################################
import * as nav from "navhandler"
import * as triggers from "./navtriggers.js"
import * as uiState from "./uistatemodule.js"

############################################################
defaultBaseState = "chat"

############################################################
appBaseState = defaultBaseState
uiAppMod = "none"
appContext = {}

############################################################
currentVersion = document.getElementById("current-version")

############################################################
export initialize = (c) ->
    log "initialize"
    if c and c.appVersion then currentVersion.textContent = c.appVersion
    return