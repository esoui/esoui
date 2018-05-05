--This file contains overrides to our strings for unofficial translations since we don't allow loading custom language client string files in
--internal ingame.

local language = GetCVar("Language.2")

if language == "ru" then
    EsoStrings[SI_MARKET_PRODUCT_NAME_FORMATTER] = "<<1>>"
end