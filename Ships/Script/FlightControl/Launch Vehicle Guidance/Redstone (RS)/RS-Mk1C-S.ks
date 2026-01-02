@lazyGlobal off.

run once "0:/MARALib/library/vesselloading.ks".
run once "0:/MARALib/library/uitools.ks".
run once "0:/MARALib/library/throttlecontrol.ks".
run once "0:/MARALib/library/astrodynamics.ks".
run once "0:/MARALib/library/partsearch.ks".
run once "0:/MARALib/library/logtools.ks".
run once "0:/KSLib/library/lib_lazcalc.ks".

copypath("0:/FlightControl/ExecuteNextNode.ks","1:/boot/ExecuteNextNode.ks").

initLog(3).

global targetApoapsis TO 80000.
global targetPeriapsis TO targetApoapsis.
global targetInclination TO 6.
global azimuthStruct TO LAZcalc_init(targetApoapsis,targetInclination).
global targetAzimuth TO LAZcalc(azimuthStruct).
global targetPitch TO 90.
global targetRoll TO 270.
global maxAllowedAcc IS 2.5.
global maxAllowedTWR TO 1.55.
global targetHeading TO UP.
global targetThrottle TO 0.0.
global timedStagingEvents IS list().
global targetTTA is 60.
//global pitchPID to PIDLOOP(0.5,0.1,0,-15,15,0).
//global throttlePID is pidloop(0.5,0.1,0,0.05,1,0).
global adjustmentFactor IS 0.

global f_OutOfAtmosphere TO FALSE.
global f_IgnoreCalculatedPitch TO FALSE.
global f_SafeToStage TO FALSE.
global f_IgnoreCalculatedThrottle TO FALSE.
global f_CutEngines TO FALSE.
//global f_LowAltBoost TO FALSE.

function GetAzimuth {
    RETURN LAZcalc(azimuthStruct).
}

function getMaxAllowedTWR {
    local gForce is (GetGravitationalAccelerationOnVessel(SHIP) / 9.81).
    log_("[GRAV]: " + gForce + "g",3).
    local accForce is maxAllowedAcc - gForce.
    log_("[MAXTWR]: " + accForce,3).
    RETURN accForce.
}

function AdjustThrottle {
    IF f_CutEngines {
        SET targetThrottle TO 0.0.
    } ELSE IF f_IgnoreCalculatedThrottle {
        SET targetThrottle TO 1.0.
    } ELSE {
        //set targetThrottle to min(throttlePID:update(TIME:SECONDS, ship:orbit:eta:apoapsis),TWRToThrottle(getMaxAllowedTWR())).
        SET targetThrottle TO TWRToThrottle(getMaxAllowedTWR()).
    }
    log_("[THROTTLE]: " + targetThrottle,3).
}

function AdjustAzimuth {
    SET targetAzimuth TO GetAzimuth().
}

function AdjustPitch {
    local atmoAscentPercentage is ship:altitude / (ship:orbit:body:atm:height * 0.80).

    set targetPitch to max((1 - atmoAscentPercentage) * 90, 0).
}

function AdjustSteering {
    AdjustAzimuth().
    AdjustPitch().
    IF f_IgnoreCalculatedPitch {
        SET targetHeading TO HEADING(targetAzimuth, 0, targetRoll).
    } ELSE IF f_OutOfAtmosphere <> TRUE {
        SET targetHeading TO HEADING(targetAzimuth,targetPitch, targetRoll).
    }
}

function SwitchToSAS {
    UNLOCK STEERING.
    SAS ON.
    log_("[SAS]: ON").
}

function SwitchToCookedSteering {
    SAS OFF.
    LOCK STEERING TO targetHeading.
    log_("[SAS]: OFF").
}

function SmartStage {
    IF f_SafeToStage {
        log_("[STAGE]: " + STAGE:NUMBER).
        STAGE.
        WAIT 1.
    }
}

function Launch {
    SET targetThrottle TO 1.0.
    SET f_SafeToStage TO TRUE.
    SET f_IgnoreCalculatedThrottle TO TRUE.
    LOCK THROTTLE TO targetThrottle.

    SwitchToSAS().
    WAIT 0.
    SmartStage().
}

function allTimedStagePartModules {
    return modulesDubbed("timedStage").
}

function addTimedStagingEvent {
    parameter met.
    parameter decouplerPart IS "NULL".

    if decouplerPart:istype() {

    }
    local stagingEvent is list(met,decouplerPart).
}

function stagedTimedEvent {

}

function MonitorAscent {

    WHEN MAXTHRUST <= 0 THEN {
        PRINT "Staging.".
        SmartStage().
        WAIT 0.

        PRESERVE.
    }
    
    WHEN SHIP:VERTICALSPEED >= 60 THEN {
        PRINT "Above 100 m/s - Steering Enabled".
        SET f_IgnoreCalculatedThrottle TO FALSE.
        SwitchToCookedSteering().
    }

    WHEN targetPitch < 40 THEN {
        SET maxAllowedTWR TO maxAllowedTWR + 0.5.
    }

    WHEN SHIP:ALTITUDE > SHIP:BODY:ATM:HEIGHT THEN {
        PRINT "Out of ATM".
        SET f_OutOfAtmosphere TO TRUE.
    }

    // Within 5% of target apoapsis
    WHEN (targetApoapsis - SHIP:APOAPSIS) < (targetApoapsis * 0.02) THEN {
        PRINT "Close to AP, slowing engine".
        SET maxAllowedTWR TO 1.0.
    }

    WHEN apoapsis >= targetApoapsis THEN {
        PRINT "Cutting engines.".
        SET f_CutEngines TO TRUE.
    }

    WHEN f_CutEngines THEN {
        PRINT "Engines cut.".
        SET targetThrottle TO 0.
        UNLOCK THROTTLE.
        set targetHeading to PROGRADE.
    }

    UNTIL SHIP:apoapsis >= targetApoapsis{
        AdjustThrottle().
        AdjustSteering().
        WAIT 0.
    }

    WAIT UNTIL f_OutOfAtmosphere.
    SET f_SafeToStage TO FALSE.
    RETURN 1.
}

function SetupCircularizationBurn {
    local targetOrbitalVelocity is OrbitalVelocityAtAltitudeOfCircularOrbit(SHIP:APOAPSIS, SHIP, SHIP:ORBIT:BODY).
    local presentOrbitalVelocity is OrbitalVelocityAtAltitude(SHIP:APOAPSIS, SHIP, SHIP:ORBIT).
    local nodeTime is TIMESTAMP() + ETA:APOAPSIS.
    local deltaV is targetOrbitalVelocity - presentOrbitalVelocity.
    local newNode is NODE(nodeTime, 0, 0, deltaV).
    ADD newNode.
    WAIT 0.
}

function DoCircularizationNode {
    RUNPATH("1:/boot/ExecuteNextNode.ks").
}

function Main {
    LoadProgram("Redstone Gen. 1 - Launch Controller").

    //set pitchPID:setpoint to targetApoapsis.
    //set throttlePID:setpoint to targetTTA.
    Launch().
    local ascentResult TO MonitorAscent().

    IF ascentResult = 1 {
        SetupCircularizationBurn().
    } ELSE {
        RETURN ascentResult.
    }

    UNLOCK THROTTLE.
    UNLOCK STEERING.
    DoCircularizationNode().
}

Main().
SHUTDOWN.

// run "0:/boot/RedstoneLC.ks".