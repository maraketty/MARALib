// vesselstatistics.ks
// MIT License
// https://github.com/maraketty/MARALib/

@LAZYGLOBAL OFF.

FUNCTION HasThrust {
    PARAMETER TargetVessel IS SHIP.

    RETURN TargetVessel:MAXTHRUST > 0.
}

FUNCTION HasMass {
    PARAMETER TargetVessel IS SHIP.

    RETURN TargetVessel:MASS > 0.
}

FUNCTION HasThrustAndMass {
    PARAMETER TargetVessel IS SHIP.

    RETURN HasThrust(TargetVessel) AND HasMass(TargetVessel).
}

FUNCTION GetMU {
    PARAMETER TargetVessel IS SHIP.

    IF HasMass(TargetVessel) {
        RETURN CONSTANT:G * TargetVessel:MASS.
    } ELSE {
        RETURN -1.
    }
}

FUNCTION GetGravitationalForceOnVessel {
    PARAMETER TargetVessel IS SHIP.

    IF HasMass(TargetVessel) {
        RETURN TargetVessel:ORBIT:BODY:MU / (TargetVessel:ALTITUDE + TargetVessel:ORBIT:BODY:RADIUS)^2.
    } ELSE {
        RETURN -1.
    }
}