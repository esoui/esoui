-- Mapping of link type to the text that appears for their associated "Use" keybind button.
local LINK_ACTION_NAMES =
{
    [GUILD_LINK_TYPE] = GetString(SI_GAMEPAD_GUILD_LINK_KEYBIND),
    [HELP_LINK_TYPE] = GetString(SI_GAMEPAD_OPEN_HELP_LINK_KEYBIND),
    [HOUSING_LINK_TYPE] = GetString(SI_GAMEPAD_HOUSING_LINK_KEYBIND),
}

-- Mapping of link type to the custom handler that is called when used;
-- the default handler is called for unmapped link types.
local LINK_ACTION_HANDLERS =
{
    [GUILD_LINK_TYPE] = function(link)
        local guildId = ZO_LinkHandler_ParseLinkData(link)
        GUILD_BROWSER_GUILD_INFO_GAMEPAD:ShowWithGuild(guildId)
    end,
    [HELP_LINK_TYPE] = function(link)
        local helpCategoryIndex, helpIndex = GetHelpIndicesFromHelpLink(link)
        if helpCategoryIndex and helpIndex then
            HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(helpCategoryIndex, helpIndex)
        end
    end,
}

-- Mapping of link type to a variable return function that receives a reference
-- to the calling ZO_GamepadLinks instance and returns any additional parameters
-- to be passed to GAMEPAD_TOOLTIPS:LayoutLink.
-- * Refer to ZO_GamepadLinks:Show() for additional information.
local LINK_LAYOUT_PARAMETER_FUNCTIONS =
{
    [HOUSING_LINK_TYPE] = function(gamepadLinks)
        return gamepadLinks:GetUseKeybind()
    end,
}

-- ZO_GamepadLinks presents one or more links' tooltips with carousel-style navigation and,
-- when appropriate, a customizable "Use" keybind for actionable links.

ZO_GamepadLinks = ZO_InitializingCallbackObject:Subclass()

function ZO_GamepadLinks:Initialize(supportedLinkTypes, gamepadTooltip)
    self.links = {}
    self.supportedLinkTypes = {}

    self.currentLinkIndex = 1
    self.registeredKeybinds = nil
    self.showingLinkData = nil

    self:SetSupportedLinkTypes(supportedLinkTypes or ZO_VALID_LINK_TYPES_CHAT)
    self:InitializeKeybindStripDescriptor()
    self:SetGamepadTooltip(gamepadTooltip or GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GamepadLinks:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    { 
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Use Link
        {
            order = 10,
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                local linkData = self:GetCurrentLink()
                return LINK_ACTION_NAMES[linkData.linkType]
            end,
            callback = function()
                local linkData = self:GetCurrentLink()
                local actionHandler = LINK_ACTION_HANDLERS[linkData.linkType]
                if actionHandler then
                    -- Call the custom link handler.
                    actionHandler(linkData.link)
                    return
                end

                -- Call the default link handler.
                local NO_BUTTON = nil
                LINK_HANDLER:FireCallbacks(LINK_HANDLER.LINK_CLICKED_EVENT, linkData.link, NO_BUTTON, ZO_LinkHandler_ParseLink(linkData.link))
            end,
            visible = function()
                local linkData = self:GetCurrentLink()
                return linkData ~= nil and LINK_ACTION_NAMES[linkData.linkType] ~= nil
            end,
        },

        -- Next Link
        {
            order = 20,
            keybind = "UI_SHORTCUT_INPUT_RIGHT",
            name = GetString(SI_GAMEPAD_CYCLE_TOOLTIP_BINDING),
            callback = function()
                self:ShowNextLink()
            end,
            visible = function()
                return self:GetNumLinks() > 1
            end,
        },

        -- Previous Link
        {
            -- Name does not require localization because ethereal binds do not appear in the UI.
            ethereal = true,
            keybind = "UI_SHORTCUT_INPUT_LEFT",
            name = "Gamepad Previous Link",
            callback = function()
                self:ShowPreviousLink()
            end,
            visible = function()
                return self:GetNumLinks() > 1
            end,
        },
    }
end

function ZO_GamepadLinks:AddKeybinds()
    -- Order matters:
    self:RemoveKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.registeredKeybinds = true
end

function ZO_GamepadLinks:AddLinksTable(links, replaceExistingLinks)
    if replaceExistingLinks then
        self:ResetLinks()
    end

    if not links then
        -- Disregard a nil reference as a matter of convenience for the caller.
        return
    end

    local addedLink = false
    for linkIndex, link in ipairs(links) do
        if link.link then
            local linkType = GetLinkType(link.link)
            local linkHandlerName = GetLinkLayoutHandlerName(linkType)
            if GAMEPAD_TOOLTIPS[linkHandlerName] then
                -- Add the validated link.
                table.insert(self.links, link)
                addedLink = true
            end
        end
    end

    if addedLink then
        self:OnLinksUpdated(self.links)
    end
end

function ZO_GamepadLinks:AddLinksFromText(text, replaceExistingLinks)
    if replaceExistingLinks then
        self:ResetLinks()
    end

    if text == nil then
        -- Disregard a nil reference as a matter of convenience for the caller.
        return
    end

    local links = {}
    ZO_ExtractLinksFromText(text, self.supportedLinkTypes, links)
    self:AddLinksTable(links, replaceExistingLinks)
end

function ZO_GamepadLinks:GetCurrentLink()
    return self.links[self.currentLinkIndex]
end

function ZO_GamepadLinks:GetGamepadTooltip()
    return self.gamepadTooltip
end

function ZO_GamepadLinks:GetLink(linkIndex)
    return self.links[linkIndex]
end

function ZO_GamepadLinks:GetLinks()
    return self.links
end

function ZO_GamepadLinks:GetNumLinks()
    return #self.links
end

function ZO_GamepadLinks:GetSupportedLinkTypes()
    return self.supportedLinkTypes
end

function ZO_GamepadLinks:GetUseKeybind()
    return self.keybindStripDescriptor[1].keybind
end

function ZO_GamepadLinks:HasLinks()
    return #self.links > 0
end

function ZO_GamepadLinks:Hide()
    if self.showingLinkData then
        local previousLink = self.showingLinkData
        self.showingLinkData = nil
        GAMEPAD_TOOLTIPS:ClearTooltip(self.gamepadTooltip)
        self:OnLinkHidden(previousLink)
    end
end

function ZO_GamepadLinks:IsHidden()
    return self.showingLinkData == nil
end

function ZO_GamepadLinks:OnLinkHidden(linkData)
    self:FireCallbacks("OnLinkHidden", linkData)
    self:UpdateKeybinds()
end

function ZO_GamepadLinks:OnLinkShown(linkData, previousLinkData)
    self:FireCallbacks("OnLinkShown", linkData, previousLinkData)
    self:UpdateKeybinds()
end

function ZO_GamepadLinks:OnLinksUpdated(linkDataList)
    self:FireCallbacks("OnLinksUpdated", linkDataList)
    self:UpdateKeybinds()
end

function ZO_GamepadLinks:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.registeredKeybinds = nil
end

function ZO_GamepadLinks:ResetLinks()
    self:Hide()

    ZO_ClearNumericallyIndexedTable(self.links)
    self.currentLinkIndex = 1
    self.showingLinkData = nil

    self:OnLinksUpdated(self.links)
end

function ZO_GamepadLinks:SetGamepadTooltip(gamepadTooltip)
    if not gamepadTooltip or self.gamepadTooltip == gamepadTooltip then
        return
    end

    local wasHidden = self:IsHidden()
    self:Hide()
    self.gamepadTooltip = gamepadTooltip

    if not wasHidden then
        self:Show()
    end
end

function ZO_GamepadLinks:SetHidden(hidden)
    if hidden then
        self:Hide()
    else
        self:Show()
    end
end

function ZO_GamepadLinks:SetKeybindAlignment(alignment)
    self:RemoveKeybinds()
    self.keybindStripDescriptor.alignment = alignment
    self:UpdateKeybinds()
end

function ZO_GamepadLinks:SetUseKeybind(keybind)
    -- Order matters:
    self:RemoveKeybinds()
    self.keybindStripDescriptor[1].keybind = keybind
    self:UpdateKeybinds()
end

function ZO_GamepadLinks:SetSupportedLinkTypes(linkTypes)
    self:ResetLinks()
    ZO_ClearTable(self.supportedLinkTypes)

    if #linkTypes == 0 then
        -- Import a key/value pair table.
        for linkType, isSupported in pairs(linkTypes) do
            if isSupported ~= false then
                self.supportedLinkTypes[linkType] = true
            end
        end
    else
        -- Import a numerically indexed table.
        for _, linkType in ipairs(linkTypes) do
            self.supportedLinkTypes[linkType] = true
        end
    end
end

function ZO_GamepadLinks:Show()
    local linkData = self:GetCurrentLink()
    if linkData and linkData.linkType then
        -- Look up the parameter function for this link type.
        -- If one exists then pass its variable return values as additional parameters for GAMEPAD_TOOLTIPS:LayoutLink.
        local parameterFunction = LINK_LAYOUT_PARAMETER_FUNCTIONS[linkData.linkType]

        -- Show current link.
        if GAMEPAD_TOOLTIPS:LayoutLink(self.gamepadTooltip, linkData.link, parameterFunction and parameterFunction(self)) then
            local previousLinkData = self.showingLinkData
            self.showingLinkData = linkData
            self:OnLinkShown(self.showingLinkData, previousLinkData)
            return
        end
    end

    -- No link was shown so the link apparatus must be hidden.
    self:Hide()
end

function ZO_GamepadLinks:ShowNextLink()
    local numLinks = #self.links
    if numLinks == 0 then
        self:Hide()
        return
    end

    local nextIndex = self.currentLinkIndex + 1
    if nextIndex > numLinks then
        nextIndex = 1
    end

    self.currentLinkIndex = nextIndex
    self:FireCallbacks("CycleLinks", self.currentLinkIndex)
    self:Show()
end

function ZO_GamepadLinks:ShowPreviousLink()
    local numLinks = #self.links
    if numLinks == 0 then
        self:Hide()
        return
    end

    local nextIndex = self.currentLinkIndex - 1
    if nextIndex < 1 then
        nextIndex = numLinks
    end

    self.currentLinkIndex = nextIndex
    self:FireCallbacks("CycleLinks", self.currentLinkIndex)
    self:Show()
end

function ZO_GamepadLinks:UpdateKeybinds()
    if self:IsHidden() then
        self:RemoveKeybinds()
    else
        if self.registeredKeybinds then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            self:AddKeybinds()
        end
    end
end