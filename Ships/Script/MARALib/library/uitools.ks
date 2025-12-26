// uitools.ks - additional functions for drawing on the kOS terminal
// MIT License
// https://github.com/maraketty/MARALib/

@LAZYGLOBAL OFF.

DECLARE GLOBAL timeOfLastDraw IS TIMESTAMP().
DECLARE GLOBAL UIUpdateInterval TO 0.05.

FUNCTION SetUIUpdateInterval {
    PARAMETER newUIUpdateInterval IS -1.

    SET newUIUpdateInterval TO newUIUpdateInterval:TONUMBER(-1).
    IF newUIUpdateInterval > 0 {
        SET UIUpdateInterval TO newUIUpdateInterval.
    } ELSE {
        RETURN -1.
    }
}

FUNCTION CanDraw {
  IF timeOfLastDraw = 0 {
      RETURN TRUE.
  } ELSE {
      LOCAL timeDifference IS TIMESTAMP() - timeOfLastDraw.
      RETURN timeDifference > UIUpdateInterval.
  }
}

FUNCTION HorizontalLine {
  PARAMETER character IS "-".
  PARAMETER length IS TERMINAL:WIDTH.

  LOCAL charPosition IS 1.
  LOCAL output IS "".
  UNTIL charPosition > length {
      SET output TO output + character.
      SET charPosition TO charPosition + 1.
  }

  RETURN output.
}

FUNCTION JusityLeftText {
  PARAMETER message IS "".

  IF TERMINAL:WIDTH <= message:LENGTH {
    RETURN message.
  } ELSE {
    RETURN message + HorizontalLine(" ", TERMINAL:WIDTH - message:LENGTH).
  }
}

FUNCTION JustifyRightText {
  PARAMETER message IS "".

  IF TERMINAL:WIDTH <= message:LENGTH {
    RETURN message.
  } ELSE {
    RETURN HorizontalLine(" ", TERMINAL:WIDTH - message:LENGTH) + message.
  }
}

FUNCTION CenteredText {
  PARAMETER message IS "".
  PARAMETER fillerCharacter IS " ".

  LOCAL prefixLength IS 0.
  LOCAL suffixLength IS 0.
  LOCAL blankSpacesNumber IS TERMINAL:WIDTH - message:LENGTH.

  IF ABS(MOD(blankSpacesNumber, 2)) <> 0 {
    SET prefixLength TO FLOOR(blankSpacesNumber / 2).
    SET suffixLength TO prefixLength + 1.
  } ELSE {
    SET prefixLength TO blankSpacesNumber / 2.
    SET suffixLength TO prefixLength.
  }

  RETURN HorizontalLine(fillerCharacter, prefixLength) + message + HorizontalLine(fillerCharacter, suffixLength).
}

FUNCTION DisplayHUDMessage {
    PARAMETER message.
    PARAMETER delaySeconds IS 5.
    PARAMETER style IS 2.
    PARAMETER size IS 24.
    PARAMETER colour IS GREEN.
    PARAMETER doEcho IS FALSE.

    HUDTEXT(message, delaySeconds, style, size, colour, doEcho).
}

FUNCTION DisplayHUDError {
    PARAMETER message.
    PARAMETER delaySeconds IS 10.
    PARAMETER style IS 2.
    PARAMETER size IS 24.
    PARAMETER colour IS RED.
    PARAMETER doEcho IS FALSE.

    HUDTEXT(message, delaySeconds, style, size, colour, doEcho).
}