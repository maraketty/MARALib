// throttlecontrol.ks
// MIT License
// https://github.com/maraketty/MARALib/

@LAZYGLOBAL OFF.

RUN ONCE "0:/MARALib/library/vesselstatistics.ks".

FUNCTION ThrottleIsValid {
    PARAMETER ThrottleValue IS THROTTLE.
    
    RETURN ThrottleValue >= 0 AND ThrottleValue <= 1.
}

// Converts a requested vessel thrust-to-weight ratio to a throttle value between 0 and 1.
FUNCTION TWRToThrottle {
  PARAMETER TargetTWR.
  PARAMETER TargetVessel IS SHIP.

  IF HasThrustAndMass(TargetVessel) {
    RETURN TargetTWR * TargetVessel:MASS * (GetGravitationalForceOnVessel(TargetVessel)) / TargetVessel:MAXTHRUST.
  } ELSE {
    RETURN FALSE.
  }
}

// Converts a vessel throttle value to a thrust-to-weight ratio.
FUNCTION ThrottleToTWR {
    PARAMETER TargetThrottle.
    PARAMETER TargetVessel IS SHIP.

    IF ThrottleIsValid(TargetThrottle) AND HasThrustAndMass(TargetVessel) {
        RETURN (TargetVessel:MAXTHRUST / TargetVessel:MASS) * TargetThrottle.
    } ELSE {
        RETURN -1.
    }
}