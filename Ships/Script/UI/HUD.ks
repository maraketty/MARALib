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