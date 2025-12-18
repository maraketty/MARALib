// Ease Factor (EF): Time in seconds to wait for a vessel to hopefully be fully loaded in order to avoid issues related to
//  attempting to run scripts before the game engine is ready. This isn't an exact science that actually confirms that
//  the vessel is fully loaded and ready, but a conservative estimate that should be enough for any vessel enough time to load.
//
//  We caculate EF as one (1) second for every 15 parts on the vessel OR five (5) seconds, whichever is greater.
//      EF = (PartCount / 15) OR 5
FUNCTION GetEaseFactor {
    SET partCount TO SHIP:ROOTPART:CHILDREN:LENGTH + 1.
    SET easeFactor TO FLOOR(MAX((partCount / 15), 5)).
    RETURN easeFactor.
}

FUNCTION LoadProgramAfterVesselIsUnpacked {
    PARAMETER programName IS "".
    PARAMETER easeTime IS GetEaseFactor().

    CLEARSCREEN.
    PRINT "LOADING: " + programName.
    PRINT "WAITING FOR VESSEL UNPACKING".
    WAIT UNTIL SHIP:UNPACKED. // kOS loads in before parts are loaded, this forces kOS to pause until parts are loaded.

    CLEARSCREEN.
    PRINT "STARTING: " + programName.
    PRINT "VESSEL UNPACKED".
    WAIT 1.

    CLEARSCREEN.
    PRINT "STARTING: " + programName.
    PRINT "EASING...".
    WAIT easeTime. // Time allowed for the vessel to settle/ease into the physics engine to avoid applying forces too early.
}

FUNCTION LoadProgram {
    PARAMETER programName IS "".
    PARAMETER easeTime IS GetEaseFactor().

    IF SHIP:STATUS() = "PRELAUNCH" {
        LoadProgramAfterVesselIsUnpacked(programName, FLOOR(easeTime * 1.25)).
    } ELSE {
        LoadProgramAfterVesselIsUnpacked(programName, easeTime).
    }

    CLEARSCREEN.
}