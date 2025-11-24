import { addModulesToDebug } from "thingy-debug"

############################################################
export modulesToDebug = {

    # appcoremodule: true
    wsmodule: true
    chatframemodule: true
    chatsessionmodule: true
    # navtriggers: true
    # uistatemodule: true
}

addModulesToDebug(modulesToDebug)
