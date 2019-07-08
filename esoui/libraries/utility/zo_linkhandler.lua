LINK_HANDLER = ZO_CallbackObject:New()

LINK_HANDLER.INSERT_LINK_EVENT = "ZO_LinkHandler_InsertLinkEvent"
LINK_HANDLER.LINK_CLICKED_EVENT = "ZO_LinkHandler_LinkClickedEvent"
LINK_HANDLER.LINK_MOUSE_UP_EVENT = "ZO_LinkHandler_LinkMouseUpEvent"

ITEM_LINK_TYPE = "item"
ACHIEVEMENT_LINK_TYPE = "achievement"
CHARACTER_LINK_TYPE = "character"
CHANNEL_LINK_TYPE = "channel"
BOOK_LINK_TYPE = "book"
DISPLAY_NAME_LINK_TYPE = "display"
URL_LINK_TYPE = "url"
COLLECTIBLE_LINK_TYPE = "collectible"
GUILD_LINK_TYPE = "guild"
HELP_LINK_TYPE = "help"

ZO_VALID_LINK_TYPES_CHAT =
{
    [GUILD_LINK_TYPE] = true,
    [ITEM_LINK_TYPE] = true,
    [ACHIEVEMENT_LINK_TYPE] = true,
    [COLLECTIBLE_LINK_TYPE] = true,
    [HELP_LINK_TYPE] = true,
}

function ZO_LinkHandler_InsertLink(link)
    if type(link) == "string" and #link > 0 then
        local text, color, linkType = ZO_LinkHandler_ParseLink(link)

        --todo: handle other link type sound cases
        if linkType == ITEM_LINK_TYPE then
            local soundCategory = GetItemSoundCategoryFromLink(link)
            if soundCategory then
                PlayItemSound(soundCategory, ITEM_SOUND_ACTION_SLOT)
            end
        end

        return LINK_HANDLER:FireCallbacks(LINK_HANDLER.INSERT_LINK_EVENT, link)
    end
end

local function HandleLinkMouseEvent(link, button, control, eventType)
    if type(link) == "string" and #link > 0 then
        local handled = LINK_HANDLER:FireCallbacks(eventType, link, button, ZO_LinkHandler_ParseLink(link))
        if not handled then
            ClearMenu()
            if button == MOUSE_BUTTON_INDEX_LEFT and ZO_PopupTooltip_SetLink then
                ZO_PopupTooltip_SetLink(link)
            elseif button == MOUSE_BUTTON_INDEX_RIGHT and link ~= "" then
                local function AddLink()
                    ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                end

                AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
                    
                ShowMenu(control)
            end
        end
    end
end

function ZO_LinkHandler_OnLinkClicked(link, button, control)
    HandleLinkMouseEvent(link, button, control, LINK_HANDLER.LINK_CLICKED_EVENT)
end

function ZO_LinkHandler_OnLinkMouseUp(link, button, control)
    HandleLinkMouseEvent(link, button, control, LINK_HANDLER.LINK_MOUSE_UP_EVENT)
end

function ZO_LinkHandler_CreateLinkWithFormat(text, color, linkType, linkStyle, stringFormat, ...) --where ... is the data to encode
    if linkType then
        return (stringFormat):format(linkStyle, zo_strjoin(':', linkType, ...), text)
    end
end

function ZO_LinkHandler_CreateLink(text, color, linkType, ...) --where ... is the data to encode
    return ZO_LinkHandler_CreateLinkWithFormat(text, color, linkType, LINK_STYLE_BRACKETS, "|H%d:%s|h[%s]|h", ...)
end

function ZO_LinkHandler_CreateLinkWithoutBrackets(text, color, linkType, ...) --where ... is the data to encode
    return ZO_LinkHandler_CreateLinkWithFormat(text, color, linkType, LINK_STYLE_DEFAULT, "|H%d:%s|h%s|h", ...)
end

function ZO_LinkHandler_ParseLink(link)
    if type(link) == "string" then
        local linkStyle, data, text = link:match("|H(.-):(.-)|h(.-)|h")
        return text, linkStyle, zo_strsplit(':', data)
    end
end

function ZO_LinkHandler_CreatePlayerLink(displayOrCharacterName)
    if(IsDecoratedDisplayName(displayOrCharacterName)) then
        return ZO_LinkHandler_CreateDisplayNameLink(displayOrCharacterName)
    else
        return ZO_LinkHandler_CreateCharacterLink(displayOrCharacterName)
    end 
end

function ZO_LinkHandler_CreateDisplayNameLink(displayName)
    local undecoratedDisplayName
    if(not IsDecoratedDisplayName(displayName)) then
        undecoratedDisplayName = displayName
        displayName = DecorateDisplayName(displayName)
    else
        undecoratedDisplayName = UndecorateDisplayName(displayName)
    end

    local userFacingDisplayName = IsConsoleUI() and undecoratedDisplayName or displayName
    return ZO_LinkHandler_CreateLink(userFacingDisplayName, nil, DISPLAY_NAME_LINK_TYPE, undecoratedDisplayName)
end

function ZO_LinkHandler_CreateCharacterLink(characterName)
    if IsConsoleUI() then
        return string.format("[%s]", ZO_FormatUserFacingCharacterName(characterName))
    else
        return ZO_LinkHandler_CreateLink(characterName, nil, CHARACTER_LINK_TYPE, characterName)
    end
end

function ZO_LinkHandler_CreateChannelLink(channelName)
    return ZO_LinkHandler_CreateLink(channelName, nil, CHANNEL_LINK_TYPE, channelName)
end

function ZO_LinkHandler_CreateURLLink(url, displayText)
    return ZO_LinkHandler_CreateLinkWithoutBrackets(displayText, nil, URL_LINK_TYPE, url)
end

local function AppendHelper(thingToAppend, size, nextElement, ...)
    if size == 0 then
        return thingToAppend
    end

    return nextElement, AppendHelper(thingToAppend, size - 1, ...) 
end

local function Append(thingToAppend, ...)
    return AppendHelper(thingToAppend, select('#', ...), ...)
end

-- where ... are arguments to pass to linkFunction
function ZO_LinkHandler_CreateChatLink(linkFunction, ...)
    return linkFunction(Append(LINK_STYLE_BRACKETS, ...))
end

do
    local LINK_GMATCH_PATTERN = "|H.-|h.-|h"
    local LINK_TYPE_MATCH_PATTERN = "|H%d:(.-):"
    function ZO_ExtractLinksFromText(text, validLinkTypes, linksTable)
        for link in zo_strgmatch(text, LINK_GMATCH_PATTERN) do
            local linkType = zo_strmatch(link, LINK_TYPE_MATCH_PATTERN)
            if validLinkTypes[linkType] then
                table.insert(linksTable, { linkType = linkType, link = link })
            end
        end
    end
end