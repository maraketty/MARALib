// ================================================================================================================================================================================
//
//  Automated Parachute-Assisted Landing (APAL) v2025.12.17b (BETA)
//  By: Maraketty's Astrodynamic Research Association (MARA)
//  
//  https://maraketty.com/
//
// ================================================================================================================================================================================
//
//  This program will automatically manage vessel attitude, parachutes, and gear during unpowered parachute landings of probes/science return units/etc.
//
// ================================================================================================================================================================================
//
//  Instructions for Optimal Usage:
//
//  1. Label all parachutes/antenna/decoupler-equipped parts with a kOS tag as follows:
//      - Main Parachutes: "APAL_Chute"
//      - Backup Parachutes: "APAL_BackupChute"
//      - Deployable Antenna: "APAL_Transponder"
//      - Parts to Jettison If Landing Too Fast: "APAL_JettisonIfHeavy"
//      - Parts to Jettison After Parachute Deployment: "APAL_JettisonAfterDeployment"
//  2. Run the program in space prior to entering the atmosphere.
//  3. Wait for your vessel to land and the program to automatically close. The program will close ten (10) seconds after landing or splashing down.
//
// ================================================================================================================================================================================

@LAZYGLOBAL OFF.

RUN ONCE "0:/Utility/ProgramLoading.ks".
RUN ONCE "0:/UI/HUD.ks".

GLOBAL programName IS "Automated Parachute-Assisted Landing (APAL)".
GLOBAL allParachutes IS LIST().
GLOBAL allMainParachutes IS LIST().
GLOBAL allDrogueParachutes IS LIST().
GLOBAL allPrimaryParachutes IS LIST().
GLOBAL allBackupParachutes IS LIST().
GLOBAL jettisonIfHeavy IS LIST(). // Parts like heat shields that can be safely discarded if we're going too fast but otherwise want to keep
GLOBAL jettisonAfterDeployment IS LIST().
GLOBAL programStatus IS "NULL".
GLOBAL minimumSafeLandingSpeed IS -9.
GLOBAL timeOfLastDraw IS TIMESTAMP().
LOCK programUID TO SetProgramUID(). // Used for generating unique log file names.


LOCK LogToFileFlag TO FALSE.
LOCK LogToTerminalFlag TO FALSE.
GLOBAL controlSteering IS TRUE.

// --- Program Logging ---

FUNCTION SetProgramUID {    
    LogAction("Called: SetProgramUID()").

    RETURN SHIP:NAME + "_" + TIME:YEAR + "_" + TIME:DAY + "_" + FLOOR(100000*RANDOM()).
}

FUNCTION LogAction {
    PARAMETER message.

    LogToFile(message).
    LogToTerminal(message).
}

FUNCTION LogToFile {
    PARAMETER message.

    IF LogToFileFlag {
        LOG ROUND(MISSIONTIME) + " - " + message TO "0:/apal/" + programUID + "log.txt".
    }
}

FUNCTION LogToTerminal {
    PARAMETER message.
    
    IF LogToTerminalFlag {
        PRINT ROUND(MISSIONTIME) + " - " + message.
    }
}

// -- HUD & Messaging ---



FUNCTION CanDraw {
    IF timeOfLastDraw = 0 {
        RETURN TRUE.
    } ELSE {
        SET timeDifference TO TIMESTAMP() - timeOfLastDraw.
        IF timeDifference > 0.5 {
            RETURN TRUE.
        } ELSE {
            RETURN FALSE.
        }
    }
}

FUNCTION BuildHorizontalLine {
    SET charPosition TO 1.
    SET horizontalLine TO "".
    UNTIL charPosition > Terminal:WIDTH {
        SET horizontalLine TO horizontalLine + "-".
    }

    RETURN horizontalLine.
}

FUNCTION DrawStatusDisplay {

    IF CanDraw() {
        LogAction("Drawing Status Display").
        SET timeOfLastDraw TO TIMESTAMP().

        SET blankingInterval TO "                              ".
        SET horizontalLine to BuildHorizontalLine().
        PRINT "--- Automated Parachute-Assisted Landing (APAL) ---" + blankingInterval AT(0,0).
        PRINT "Total Parachutes:  " + allParachutes:LENGTH() + blankingInterval AT(0,2).
        PRINT "Drogue Parachutes: " + allDrogueParachutes:LENGTH() + blankingInterval AT(0,3).
        PRINT "Total Backups:     " + allBackupParachutes:LENGTH() + blankingInterval AT(0,4).
        PRINT horizontalLine AT(0,5).
        PRINT "Altitude (Sea Level): " + ROUND(SHIP:ALTITUDE) + blankingInterval AT(0,6).
        IF GetAltitude() < 1000 {
            PRINT "Altitude (Surface): " + ROUND(GetAltitude(), 2) + blankingInterval AT(0,7).
        } ELSE {
            PRINT "Altitude (Surface): " + ROUND(GetAltitude(), 0) + blankingInterval AT(0,7).
        }
        PRINT horizontalLine AT(0,8).
        PRINT "Status: " + programStatus + blankingInterval AT(0,9).
        PRINT horizontalLine AT(0,10).
        PRINT "Barometric Pressue:   " + ROUND(GetBarometricPressure(), 2) + blankingInterval AT(0,11).
        PRINT "Dynamic Pressure (Q): " + ROUND(GetDynamicPressure(), 2) + blankingInterval AT(0,12).
        PRINT horizontalLine AT(0,13).
        PRINT "Velocity Magnitude: " + ROUND(SHIP:VELOCITY:SURFACE:MAG, 1) + blankingInterval AT(0,14).
        PRINT "Vertical Speed:     " + ROUND(SHIP:VERTICALSPEED, 1) + blankingInterval AT(0,15).
    }
}

FUNCTION UpdateStatus {
    PARAMETER newStatus.
    LogAction("Updating Program Status to: " + newStatus).

    SET programStatus TO newStatus.
    DrawStatusDisplay().
}

// --- Vessel Stats ---

FUNCTION GetAltitude {
    LogAction("Probing Radar Altitude").

    RETURN MIN(SHIP:ALTITUDE - GEOPOSITION:TERRAINHEIGHT, SHIP:ALTITUDE).
}

FUNCTION FindModuleWithFieldName {
    PARAMETER part.
    PARAMETER fieldName.
    LogAction("Searching for PartModule with FieldName: " + fieldName + " in Part: " + part:NAME).

    IF part:ALLMODULES:LENGTH() > 0 {
        FOR module IN part:ALLMODULES {
            IF module:HASFIELD(fieldName) {
                RETURN module.
            }
        }
        RETURN FALSE.
    }
}

FUNCTION FindPartsWithName {
    PARAMETER partName.
    LogAction("Searching for Part: " + partName).

    SET partList TO SHIP:PARTSNAMED(partName).
    IF partList:LENGTH() > 0 {
        RETURN partList.
    } ELSE {
        RETURN LIST().
    }
}

FUNCTION DoesBarometerExist {
    IF FindPartsWithName("sensorBarometer"):LENGTH() > 0 {
        RETURN TRUE.
    } ELSE {
        RETURN FALSE.
    }
}

FUNCTION GetBarometricPressure {
    IF DoesBarometerExist() {
        RETURN SHIP:SENSORS:PRES.
    } ELSE {
        RETURN -1.
    }
}

FUNCTION GetDynamicPressure {
    IF DoesBarometerExist() {
        RETURN SHIP:DYNAMICPRESSURE.
    } ELSE {
        RETURN -1.
    }
}

FUNCTION IsVesselInAtmosphere {
    LogAction("Called: IsVesselInAtmosphere()").

    IF GetBarometricPressure() > 0 OR GetDynamicPressure() > 0 {
        RETURN TRUE.
    } ELSE {
        RETURN FALSE.
    }
}

// --- Parachute Management ---

FUNCTION UpdateAllParachutesLists {
    LogAction("Called: UpdateAllParachutesLists()").

    SET allParachutes TO SHIP:PARTSDUBBEDPATTERN("chute").
    SET allMainParachutes TO SHIP:PARTSDUBBEDPATTERN("Parachute").
    SET allDrogueParachutes TO SHIP:PARTSDUBBEDPATTERN("Drogue").
    SET allPrimaryParachutes TO SHIP:PARTSTAGGED("APAL_Chute").
    SET allBackupParachutes TO SHIP:PARTSTAGGED("APAL_BackupChute").
}

FUNCTION DoParachutesExist {
    LogAction("Called: DoParachutesExist()").

    IF allParachutes:LENGTH() <= 0 {
        RETURN FALSE.
    } ELSE {
        RETURN TRUE.
    }
}

FUNCTION DoMainParachutesExist {
    LogAction("Called: DoMainParachutesExist()").

    IF allMainParachutes:LENGTH() <= 0 {
        RETURN FALSE.
    } ELSE {
        RETURN TRUE.
    }
}

FUNCTION DoDrogueParachutesExist {
    LogAction("Called: DoDrogueParachutesExist()").

    IF allDrogueParachutes:LENGTH() <= 0 {
        RETURN FALSE.
    } ELSE {
        RETURN TRUE.
    }
}

FUNCTION DoPrimaryParachutesExist {
    LogAction("Called: DoPrimaryParachutesExist()").

    IF allPrimaryParachutes:LENGTH() <= 0 {
        RETURN FALSE.
    } ELSE {
        RETURN TRUE.
    }
}

FUNCTION DoBackupParachutesExist {
    LogAction("Called: DoBackupParachutesExist()").

    IF allBackupParachutes:LENGTH() <= 0 {
        RETURN FALSE.
    } ELSE {
        RETURN TRUE.
    }
}

FUNCTION GetParachuteModule {
    PARAMETER parachutePart.
    LogAction("Called: GetParachuteModule(" + parachutePart:NAME + ")").

    IF parachutePart:HASMODULE("RealChuteFAR") {
        RETURN parachutePart:GETMODULE("RealChuteFAR").
    } ELSE {
        RETURN FindModuleWithFieldName(parachutePart, "min pressure").
    }
}

FUNCTION IsParachuteArmed {
    PARAMETER parachuteModule.
    LogAction("Called: IsParachuteArmed(" + parachuteModule:NAME + ")").

    RETURN parachuteModule:HASEVENT("disarm chute").
}

FUNCTION DisarmParachute {
    PARAMETER parachuteModule.
    LogAction("Called: DisarmParachute(" + parachuteModule:PART:NAME + ")").

    IF IsParachuteArmed(parachuteModule) {
        parachuteModule:DOEVENT("disarm chute").
        LogAction("Disarmed: " + parachuteModule:PART:NAME).
    }
}

FUNCTION DeployPrimaryParachutes {
    FOR parachutePart IN allPrimaryParachutes {
        SET parachuteModule TO GetParachuteModule(parachutePart).
        IF parachuteModule:HASEVENT("deploy chute") {
            parachuteModule:DOEVENT("deploy chute").
        }
        LogAction("Deploying Primary: " + parachutePart:NAME).
    }
    WAIT 3.
}

FUNCTION DeployBackupParachutes {
    FOR parachutePart IN allBackupParachutes {
        SET parachuteModule TO GetParachuteModule(parachutePart).
        IF parachuteModule:HASEVENT("deploy chute") {
            parachuteModule:DOEVENT("deploy chute").
        }
        LogAction("Deploying Backup: " + parachutePart:NAME).
    }
    WAIT 3.
}

FUNCTION DeployAllParachutes {
    FOR parachutePart IN allParachutes {
        SET parachuteModule TO GetParachuteModule(parachutePart).
        IF parachuteModule:HASEVENT("deploy chute") {
            parachuteModule:DOEVENT("deploy chute").
        }
        LogAction("Emergency Deploying: " + parachutePart:NAME).
    }
    WAIT 3.
}

FUNCTION HasParachuteFailed {
    PARAMETER parachutePart.
    
    SET parachuteModule TO GetParachuteModule(parachutePart).
    IF parachuteModule:HASEVENT("deploy chute") <> TRUE {
        IF parachuteModule:HASEVENT("disarm chute") {
            // Parachute has been armed, but has not deployed.
            RETURN FALSE.
        } ELSE IF parachuteModule:HASEVENT("cut chute") {
            // Parachute is actively deployed.
            RETURN FALSE.
        } ELSE {
            // Parachute is neither armed, but not deployed nor actively deployed.
            RETURN TRUE.
        }

    }
}

FUNCTION CheckListForFailedParachutes {
    PARAMETER parachutePartList.

    FOR parachutePart IN parachutePartList {
        IF HasParachuteFailed(parachutePart) {
            LogAction("Parachute Has Failed: " + parachutePart:NAME).
            RETURN TRUE.
        }
    }

    RETURN FALSE.
}

// Alternative Equipment

FUNCTION UpdateJettisonIfHeavyList {
    SET jettisonIfHeavy TO SHIP:PARTSDUBBEDPATTERN("APAL_JettisonIfHeavy").
}

FUNCTION UpdateJettisonAfterDeploymentList {
    SET jettisonAfterDeployment TO SHIP:PARTSDUBBEDPATTERN("APAL_JettisonAfterDeployment").
}

FUNCTION DiscardHeatShield {
    FOR part IN jettisonIfHeavy {
        IF part:HASMODULE("ModuleDecouple") {
            SET partModule TO part:GETMODULE("ModuleDecouple").
            IF partModule:HASEVENT("jettison heat shield") {
                partModule:DOEVENT("jettison heat shield").
            }
        }
    }
}

FUNCTION DiscardAfterDeployment {
    FOR part in jettisonAfterDeployment {
        IF part:HASMODULE("ModuleAnchoredDecoupler") {
            SET partModule TO part:GETMODULE("ModuleAnchoredDecoupler").
            IF partModule:HASEVENT("decouple") {
                partModule:DOEVENT("decouple").
            }
        }
    }
}

FUNCTION ExtendTransponder {
    FOR transponderPart IN SHIP:PARTSDUBBEDPATTERN("APAL_Transponder") {
        IF transponderPart:HASMODULE("ModuleDeployableAntenna") {
            transponderPart:GETMODULE("ModuleDeployableAntenna"):DOEVENT("extend antenna").
        }
    }
}

// --- Main Program Logic ---

FUNCTION MonitorDescent {
    UpdateStatus("Waiting for Safe Deployment").

    IF controlSteering {
        SAS OFF.
        LOCK STEERING TO RETROGRADE.
    }

    // Discard Heat Shield If We're Going to Fast Prior to Landing
    WHEN SHIP:VERTICALSPEED < minimumSafeLandingSpeed AND GetAltitude() < 500 THEN {
        DiscardHeatShield().
    }

    // Emergency Deployment Settings
    WHEN (GetAltitude() < 500 AND SHIP:VERTICALSPEED < minimumSafeLandingSpeed) OR CheckListForFailedParachutes(allBackupParachutes) THEN {
        UpdateStatus("Deployment (EMERGENCY)").
        DeployAllParachutes().
    }

    // Main & Backup Deployment Settings
    WHEN (SHIP:VELOCITY:SURFACE:MAG < 400 AND SHIP:VERTICALSPEED < minimumSafeLandingSpeed) OR GetAltitude() < 3000 THEN {
        UpdateStatus("Deployment").
        DeployPrimaryParachutes().
        IF CheckListForFailedParachutes(allPrimaryParachutes) <> TRUE {
            UpdateStatus("Waiting for Landing").
            DiscardAfterDeployment().
        }
        WHEN CheckListForFailedParachutes(allPrimaryParachutes) THEN {
            UpdateStatus("Waiting for Safe Deployment (BACKUP)").
            WHEN (SHIP:VELOCITY:SURFACE:MAG < 200 AND SHIP:VERTICALSPEED < minimumSafeLandingSpeed) OR GetAltitude() < 2000 THEN {
                UpdateStatus("Deployment (BACKUP)").
                DeployBackupParachutes().
                IF CheckListForFailedParachutes(allBackupParachutes) <> TRUE {
                    UpdateStatus("Waiting for Landing").
                    DiscardAfterDeployment().
                }
            }
        }
    }

    WHEN GetAltitude() < 100 THEN {
        IF controlSteering {
            SAS OFF.
            LOCK STEERING TO UP.
        }
        GEAR ON.
    }

    UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" {
        DrawStatusDisplay().
    }
    
    WHEN SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" THEN {
        UpdateStatus("Landed").
        IF controlSteering {
            UNLOCK STEERING.
        }
        WAIT 10.

        UpdateStatus("Deploying Transponder").
        ExtendTransponder().
    }
}

FUNCTION Main {
    UpdateAllParachutesLists().
    UpdateJettisonAfterDeploymentList().
    UpdateJettisonIfHeavyList().
    DrawStatusDisplay().

    IF DoParachutesExist() = FALSE {
        UpdateStatus("No Parachutes").
        DisplayHUDError("ERROR: NO PARACHUTES FOUND").
        WAIT 6.
        UpdateStatus("Closing").
        DisplayHUDMessage("APAL Shutting Down").
        WAIT 3.
        SHUTDOWN.
    }

    UpdateStatus("Pre-Check").
    FOR parachute in allParachutes {
        DisarmParachute(GetParachuteModule(parachute)).
    }
    IF IsVesselInAtmosphere() <> TRUE {
        UpdateStatus("Waiting for Atmosphere").
        UNTIL IsVesselInAtmosphere() {
            DrawStatusDisplay().
        }
    }
    MonitorDescent().
}

LoadProgram(programName).
SetProgramUID().
Main().

WAIT 5.
CLEARSCREEN.