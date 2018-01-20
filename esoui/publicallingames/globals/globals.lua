-- This allows us to make the same function in InGames and Pregame while changing exactly what it calls,
-- so shared code doesn't need to know which state its in
function ZO_Disconnect()
    Disconnect()
end