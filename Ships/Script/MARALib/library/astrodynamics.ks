// astrodynamics.ks - additional manipulators/calculators for orbital mechanics
// MIT License
// https://github.com/maraketty/MARALib/

@LAZYGLOBAL OFF.

RUN ONCE "0:/MARALib/library/vesselstatistics.ks".

FUNCTION OrbitalVelocityAtAltitude {
    PARAMETER objectAlt IS SHIP:ALTITUDE. // Altitude at targeted time
    PARAMETER object IS SHIP. // Object doing the orbiting
    PARAMETER objectOrbit IS SHIP:ORBIT. // Oribt of the object

    DECLARE LOCAL mV IS object:MASS * 1000. // Mass of the object in kg
    DECLARE LOCAL mB IS objectOrbit:BODY:MASS. // Mass of the body in kg
    DECLARE LOCAL μ IS CONSTANT:G * (mB + mV). // Gravitational parameter
    DECLARE LOCAL rAlt IS objectOrbit:BODY:RADIUS + objectAlt. // Orbital radius at targeted altitude
    DECLARE LOCAL sma IS objectOrbit:SEMIMAJORAXIS.

    RETURN SQRT(μ * ((2/rAlt)-(1/sma))).
}

FUNCTION OrbitalVelocityAtAltitudeOfCircularOrbit {
    PARAMETER targetAltitude.
    PARAMETER targetVessel IS SHIP.
    PARAMETER targetBody IS SHIP:ORBIT:BODY.

    DECLARE LOCAL mV IS targetVessel:MASS * 1000. // Mass of the object in kg
    DECLARE LOCAL mB IS targetBody:MASS. // Mass of the body in kg
    DECLARE LOCAL μ IS CONSTANT:G * (mB + mV). // Gravitational parameter
    DECLARE LOCAL sma IS targetBody:RADIUS + targetAltitude.

    RETURN SQRT(μ/sma).
}

FUNCTION OrbitalVelocityAtApoapsis {
    RETURN OrbitalVelocityAtAltitude(SHIP:APOAPSIS, SHIP, SHIP:ORBIT).
}

FUNCTION OrbitalVelocityAtPeriapsis {
    RETURN OrbitalVelocityAtAltitude(SHIP:PERIAPSIS, SHIP, SHIP:ORBIT).
}

function ETAToTrueAnomaly {

  parameter TargetObject.
  parameter TADeg. // true anomaly in degrees

  local Ecc is "X".
  local MAEpoch is "X".
  local SMA is "X".
  local Mu is "X".
  local Epoch is "X".

  if hasnode {
    if nextnode:orbit:hasnextpatch {
      set Ecc to nextnode:orbit:nextpatch:eccentricity.
      set MAEpoch to nextnode:orbit:nextpatch:meananomalyatepoch * (constant:pi/180).
      set SMA to nextnode:orbit:nextpatch:semimajoraxis.
      set Mu to nextnode:orbit:nextpatch:body:mu.
      set Epoch to nextnode:orbit:nextpatch:epoch.
    } else {
      set Ecc to nextnode:orbit:eccentricity.
      set MAEpoch to nextnode:orbit:meananomalyatepoch * (constant:pi/180).
      set SMA to nextnode:orbit:semimajoraxis.
      set Mu to nextnode:orbit:body:mu.
      set Epoch to nextnode:orbit:epoch.
    }
  } else {
    set Ecc to TargetObject:orbit:eccentricity.
    set MAEpoch to TargetObject:orbit:meananomalyatepoch * (constant:pi/180).
    set SMA to TargetObject:orbit:semimajoraxis.
    set Mu to TargetObject:orbit:body:mu.
    set Epoch to TargetObject:orbit:epoch.
  }

  if  Ecc = 0 {
    set Ecc to 10^(-10).
  }

  local EccAnomDeg is ARCtan2(SQRT(1-Ecc^2)*sin(TADeg), Ecc + cos(TADeg)).
  local EccAnomRad is EccAnomDeg * (constant:pi/180).
  local MeanAnomRad is EccAnomRad - Ecc*sin(EccAnomDeg).

  local DiffFromEpoch is MeanAnomRad - MAEpoch.
  until DiffFromEpoch > 0 {
    set DiffFromEpoch to DiffFromEpoch + 2 * constant:pi.
  }
  local MeanMotion is SQRT(Mu / SMA^3).
  local TimeFromEpoch is DiffFromEpoch/MeanMotion.
  local TimeTillETA is TimeFromEpoch + Epoch - time:seconds.
  return TimeTillETA.
}

PRINT "AP: " + OrbitalVelocityAtApoapsis().
PRINT "PE: " + OrbitalVelocityAtPeriapsis().
PRINT "Circle: " + OrbitalVelocityAtAltitudeOfCircularOrbit(SHIP:APOAPSIS).