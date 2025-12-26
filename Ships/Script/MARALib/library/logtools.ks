// logtools.ks - custom logging program for loggint to the kOS terminal and ext. files
// MIT License
// https://github.com/maraketty/MARALib/

@lazyGlobal off.

global f_logsInitialized is false.

// The source program/flight controller should call initLog() to start any actual
// logging. This was done as "run once <file>" on this file would otherwise mess with
// logging settings.
function initLog {
    global verbose is false. // log to file only if false; otherwise both file & term
    global verbosityLevel is 0. // see setVerboseLevel()
    set f_logsInitialized to true.
}

// 0 - Nothing
// 1 - Alerts/Warnings Only
// 2 - Normal
// 3 - Everything
function setVerboseLevel {
    parameter level is 0.

    set verbosityLevel to level.
}

// returns current verbosity level
function verboseLevel {
    return verbosityLevel.
}

function toggleVerbose {
    if verbose {
        set verbose to false.
    } else {
        set verbose to true.
    }
}

function enableVerbose {
    if not verbose {
        set verbose to true.
    }
}

function disableVerbose {
    if verbose {
        set verbose to false.
    }
}

function logToTerminal {
    parameter message.

    if verbose {
        // [UT:<time> MET:<time>] <message>
        print "[UT:" + round(timestamp():seconds,2) + " MET:" + round(missionTime,2) + "] " + message.
    }
}

// unfinished
function logToFile {
    parameter message.

    // need to add file stuff here
}

// underscore is used to avoid conflict with existing kOS log function
function log_ {
    parameter message.
    parameter messageLevel is 2.

    if not f_logsInitialized {
        return.
    }

    if message:startswith("[ALERT]") or message:startswith("[WARNING]") and messageLevel <> 1 {
        set messageLevel to 1.
    }

    if messageLevel <= verbosityLevel and verbosityLevel > 0 {
        logToTerminal(message).
        logToFile(message).
    }
}