local LINK_ACTION_NAMES =
{
    [GUILD_LINK_TYPE] = GetString(SI_GAMEPAD_GUILD_LINK_KEYBIND),
    [HELP_LINK_TYPE] = GetString(SI_GAMEPAD_OPEN_HELP_LINK_KEYBIND),
    [HOUSING_LINK_TYPE] = GetString(SI_GAMEPAD_HOUSING_LINK_KEYBIND),
}

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


-- ZO_GamepadLinks presents the tooltips associated with one or more links using a carousel-style
-- presentation and manages the keybinds necessary for using and cycling between those links.

ZO_GamepadLinks = ZO_InitializingCallbackObject:Subclass()

function ZO_GamepadLinks:Initialize(supportedLinkTypes, gamepadTooltip)
    self.links = {}
    self.supportedLinkTypes = {}

    self.currentLinkIndex = 1
    self.registeredKeybinds = nil
    self.showingLinkData = nil

    self:SetSupportedLinkTypes(overrideLinkTypes or ZO_VALID_LINK_TYPES_CHAT)
    self:InitializeKeybindStripDescriptor()
    self:SetGamepadTooltip(gamepadTooltip or GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GamepadLinks:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    { 
        -- Use Link
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
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
                return linkData and LINK_ACTION_NAMES[linkData.linkType] ~= nil or false
            end,
        },

        -- Next Link
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
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
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
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
    self:RemoveKeybinds()

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.registeredKeybinds = self.keybindStripDescriptor
end

function ZO_GamepadLinks:AddLinksTable(links, replaceExistingLinks)
    if replaceExistingLinks then
        self:ResetLinks()
    end

    if links == nil then
        -- Disregard a nil reference as a matter of convenience for the caller.
        return
    end

    if #links > 0 then
        ZO_CombineNumericallyIndexedTables(self.links, links)
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

    if #links > 0 then
        ZO_CombineNumericallyIndexedTables(self.links, links)
        self:OnLinksUpdated(self.links)
    end
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
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.registeredKeybinds)
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

    for _, keybindDescriptor in ipairs(self.keybindStripDescriptor) do
        keybindDescriptor.alignment = alignment
    end

    self:UpdateKeybinds()
end

function ZO_GamepadLinks:SetUseKeybind(keybind)
    self:RemoveKeybinds()

    local useKeybindDescriptor = self.keybindStripDescriptor[1]
    useKeybindDescriptor.keybind = keybind

    self:UpdateKeybinds()
end

function ZO_GamepadLinks:SetSupportedLinkTypes(linkTypes)
    self:ResetLinks()
    ZO_ClearTable(self.supportedLinkTypes)

    if #linkTypes == 0 then
        -- Import a mapping table.
        for linkType, isSupported in pairs(linkTypes) do
            if isSupported ~= false then
                self.supportedLinkTypes[linkType] = true
            end
        end
    else
        -- Import a list table.
        for _, linkType in ipairs(linkTypes) do
            self.supportedLinkTypes[linkType] = true
        end
    end
end

function ZO_GamepadLinks:Show()
    local linkData = self:GetCurrentLink()
    if linkData and linkData.linkType then
        local previousLink = self.showingLinkData
        local link = linkData.link

        -- Show current link.
        if GAMEPAD_TOOLTIPS:LayoutLink(self.gamepadTooltip, link) then
            self.showingLinkData = linkData
            self:OnLinkShown(self.showingLinkData, previousLink)
            return
        end
    end

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

    -- TODO XAR: Look into potentially narrating this again.
    self.currentLinkIndex = nextIndex
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

    -- TODO XAR: Look into potentially narrating this again.
    self.currentLinkIndex = nextIndex
    self:Show()
end

function ZO_GamepadLinks:UpdateKeybinds()
    if self:IsHidden() then
        self:RemoveKeybinds()
    else
        if self.registeredKeybinds == self.keybindStripDescriptor then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.registeredKeybinds)
        else
            self:AddKeybinds()
        end
    end
end